#!/usr/bin/python3
from jinja2 import Environment, FileSystemLoader
from urllib.parse import urlsplit, urljoin
import ipaddress
import datetime
import os
import shutil
import pickle
import subprocess
import glob
from time import sleep

import configparser

config = configparser.ConfigParser()
# Set option names case sensitive. 
# See https://docs.python.org/dev/library/configparser.html#configparser-objects
config.optionxform = str
config.read('config.ini')


class Host:  
    def __init__(self, name, ip, mac, domain, bridge, path, disk_image_template, domxmltemplpath):
        self._ip = ip
        self._name = name
        self._mac = mac
        self._domain = domain
        self._bridge = bridge
        self._path = path            
        
        os.makedirs(path)
         
        # Copy disk image - use COW is possible
        diskpath = os.path.join(path, 'disk0.raw')
        subprocess.check_output(['cp', '--reflink=auto', disk_image_template, diskpath])
         
         
        # Create VM definition for libvirt
        templdata = {
                     'fqdn': self.fqdn(),
                     'mac': mac,
                     'bridge' : bridge,
                     'diskpath': diskpath
                     }
         
        self._domxmlfile = os.path.join(self._path, 'definition.xml')
        _process_template(domxmltemplpath, templdata, self._domxmlfile)
        
        # defineVM in libvirt
        subprocess.check_output(['virsh', 'define', self._domxmlfile])
         
           
    def running(self):
        self.__check_defined()
        return subprocess.call(['virsh', 'dominfo', self.fqdn(), '|', 'grep', '-q', 'State:\s*running'], shell=True) == 0
         
     
    def defined(self):
        return subprocess.call(['virsh', 'dominfo', self.fqdn()]) == 0
     
    def start(self):
        self.__check_defined()
        subprocess.check_output(['virsh', 'start', self.fqdn()])

     
    def stop(self, force = False):
        self.__check_defined()
        if force:
            cmd = 'destroy'
        else:
            cmd = 'shutdown'
        subprocess.call(['virsh', cmd, self.fqdn()])
     
    def restart(self, force = False):
        self.__check_defined()
        if force:
            cmd = 'reset'
        else:
            cmd = 'reboot'
        subprocess.check_output(['virsh', cmd, self.fqdn()])
     
    def name(self):
        return self._name
     
    def domain(self):
        return self._domain
     
    def fqdn(self):
        return '{}.{}'.format(self.name(), self.domain())
     
    def mac(self):
        self.__check_defined()
        return self._mac
     
    def ip(self):
        self.__check_defined()
        return self._ip
     
    def undefine(self):
        if self.defined():
            self.stop(force = True)
            subprocess.check_output(['virsh', 'undefine', self.fqdn()])
        shutil.rmtree(self.path(), ignore_errors=True)
     
    def path(self):
        return self._path
     
    
    def __check_defined(self):
        if not self.defined():
            raise "Operation on not <defined> host {}".format(self.name())


class AlreadyRunningException(Exception):
    pass

class TestBox:
    """
    
    """
    
             
    
    def __init__(self, network_id, repositories = {}):
        """
        repos must use some prefix as specified in config
        """
    
        self.network_id = network_id;
        self.workdir = os.path.join(config['global']['workdir'], 'network_{}'.format(network_id))
        
        # create workdir if it does not exist
        os.makedirs(self.workdir, exist_ok = True)
        
        # Check that there is no existing configuration for this network. That would mean that
        # Previous test was not completed correctly, is still running or some error happened
        if os.path.exists(os.path.join(self.workdir, 'TestBox.state')):
            raise AlreadyRunningException("There exist a running state for network {}. This probably means that there is a test running on the network.".format(network_id))
        
        self.__templdata = _prepare_template_data(network = self.network_id, custom_product_repositories = repositories)
        
        # runtime data about built images in the test 
        self.images = {}
        self.images_path = os.path.join(self.workdir, 'images')
        self.__delete_images()
        
        # runtime data about hosts in the test
        self.hosts = {}
        self.hosts_path = os.path.join(self.workdir, 'hosts')
        self.__delete_images()
        
        self.__init_infrastructure()
        
        # If we got this far with no exception, all is ready
        self.__closed = False
        self.save()
        
    
    @staticmethod
    def load(network_id):
        """Loads TestBox instance from disk and returns it"""
        with open(os.path.join(config['global']['workdir'], 'network_{}'.format(network_id), 'TestBox.state'), 'rb') as f:
            tb = pickle.load(f)
        return tb
    
        
    def save(self):
        """Saves the current state of TestBox to the disk"""
        with open(os.path.join(self.workdir, 'TestBox.state'), 'wb') as f:
            pickle.dump(self, f)
       
    def __delete_hosts(self):
        for host in self.hosts:
            self.hosts[host].undefine()
        self.hosts.clear()
        shutil.rmtree(self.hosts_path, ignore_errors=True)
        os.makedirs(self.hosts_path, exist_ok = True)
    

    def __delete_images(self):
        shutil.rmtree(self.images_path, ignore_errors=True)
        os.makedirs(self.images_path, exist_ok = True)

    def __init_infrastructure(self):
        self.add_host('sles-11-sp3', 'server', start=True)

    def restart(self, wait_for_infrastructure_load_sec=30):
        """Removes all host from the network - will make the network completely clean for next tests. But it will not remove built images to speed up tests
        """
        self.__check_closed()
        self.__delete_hosts()
        self.__init_infrastructure()
        
        # Wait for infrastructure to start before we allow to start other machines
        sleep(wait_for_infrastructure_load_sec)
        
        self.save()
    
    def close(self):
        """
        Release all the resources allocated in the test box (delete images, etc.).
        It is no longer possible to work with this box after the close() has been called.
        """
        self.__closed = True
        
        # unregister and stop hosts
        self.__delete_hosts()
        self.__delete_images()
        
        shutil.rmtree(self.workdir, ignore_errors=True)
        pass
    
    def __check_closed(self):
        """ Raise ValueError if we run it on closed TestBox
        """
        if self.__closed:
            raise ValueError('Operation on closed TestBox')
    
    def add_host(self, os_ver, variant, start=True):
        """ os_ver = sles-11-sp3
        variant = sut
        """
        if variant not in ('pure', 'sut', 'hamsta', 'qadb', 'qadbreport', 'server'):
            raise ValueError("Invalid host variant {}.".format(variant))
        
        image = self.__build_image(os_ver, variant) 
        
        if variant in ('hamsta', 'qadb', 'qadbreport', 'server'):
            # There can be only one
            if variant in self.hosts:
                raise ValueError("There can be only one special host {} in the TestBox".format(variant))
            host_data = self.__templdata['network'][variant]
        else:
            # Is this optimal?
            host_data = [x for x in self.__templdata['network']['suts'] if x['name'] not in self.hosts][0] 
        
        host = Host(host_data['name'],
                            host_data['ip'], 
                            host_data['mac'], 
                            self.__templdata['network']['domain'],                           
                            self.__templdata['network']['bridge'],
                            os.path.join(self.hosts_path, host_data['name']),
                            image,
                            'templates/libvirt/vm.xml')
        
        self.hosts[host.name()] = host
        self.save()
        
        if start:
            host.start()
    
    def export_robot_configuration(self, file):
        """
        """
        data = {}
        data['vms'] = []
        for h in self.hosts.values():
            d = {}
            d['name'] = h.name()
            d['fqdn'] = h.fqdn()
            d['ip'] = h.ip()
            d['mac'] = h.mac()
            
            if h.name() in ('server', 'controller', 'hamsta', 'qadb', 'qadbreport'):
                data[h.name()] = d
            else:
                data['vms'].append(d) 
        data['testuser'] = self.__templdata['testuser']
        
        _process_template('templates/robot/testbox.robot', data, file)
        
    def __build_image(self, os_ver, variant):
        code = "{}-{}".format(os_ver, variant)
        if code not in self.images:
            if not os.path.exists('templates/kiwi/{}/config.xml'.format(code)):
                raise "Image description for selected OS-variant {} does not exist".format(code)
        
            img = {}
            img['kiwi'] = os.path.join(self.images_path, code, 'kiwi')
            os.makedirs(img['kiwi'], exist_ok = True)
            
            # process template to get kiwi description
            _process_template_directory(os.path.join('templates/kiwi', code), self.__templdata, img['kiwi'])
            
            
            # build the description
            img['root'] = os.path.join(self.images_path, code, 'root')
            shutil.rmtree(img['root'], ignore_errors=True) # Root must not exist, otherwise kiwi will not build
            print("running kiwi --prepare for {}".format(code))
            subprocess.check_output(['/usr/sbin/kiwi', '--yes', '--prepare', img['kiwi'], '--root', img['root'], '--logfile={}'.format(os.path.join(self.images_path, code, 'kiwi-prepare.log'))])
            
            # create the image
            img['images'] = os.path.join(self.images_path, code, 'images')
            shutil.rmtree(img['images'], ignore_errors=True)
            print("running kiwi --create for {}".format(code))
            subprocess.check_output(['/usr/sbin/kiwi', '--yes', '--create', img['root'], '-d', img['images'], '--logfile={}'.format(os.path.join(self.images_path, code, 'kiwi-create.log'))])
            
            # path to raw image
            img['raw'] = glob.glob(os.path.join(img['images'], '*.raw'))[0]
            
            self.images[code] = img
            
        
        return self.images[code]['raw']
    
        
def create_systemwide_configuration(config_path = None):
    ''' Create system-wide configuration replacing the existing files with the files
    automatically generated from templates. The configuration is placed in
    <workdir>/system_config where workdir is specified in config.ini unless specified 
    by config_path argument
    '''
    data = _prepare_template_data()
    
    if(config_path is None):
        config_path = os.path.join(config['global']['workdir'], 'system_config')
        shutil.rmtree(config_path, ignore_errors = True)

    os.makedirs(config_path, exist_ok = True)
    _process_template_directory('templates/controller', data, config_path)

def url_to_config_format(url):
    """ transforms url to short form based on configurtaion.
    e.g. http://fallback.suse.cz/install/SLP/openSUSE-13.1-GM/x86_64/DVD1  -> slp:openSUSE-13.1-GM/x86_64/DVD1
    
    Arguments:
        url - url to transform
    
    Raises:
        ValueError if it is not possible to transform URL
    """
    if not url.startswith('http'):
        raise ValueError('Only http(s) urls supported: {}'.format(url))
    
    u=urlsplit(url)
    port = u.port if u.port else 80
    url=urljoin('{}://{}:{}'.format(u.scheme, u.hostname, port), u.path)
    for r in config['repositories']:
        u=urlsplit(config['repositories'][r])
        port = u.port if u.port else 80
        repourl = urljoin('{}://{}:{}'.format(u.scheme, u.hostname, port), u.path)
        if url.startswith(repourl):
            # Found match
            return url.replace(repourl + '/', '{}:'.format(r))
        
    raise ValueError("Cannot transform {} to repo:path format".format(url))


def _generate_mac_address(network, host):
    """ Generates mac address based on network number (0-255) and host  number (0-2^16)
    
    Throws ValueException if network number or host number is outside its bounds
    
    Arguments:
    network -- id of the network
    host -- id of the host
    
    Returns:
        string containing the mac address
    """
    
    if network < 0 or network >= 256:
        raise ValueError("Network id out of bounds: {}".format(network))
    
    if host < 0 or host >= 2 ** 16:
        raise ValueError("Host id out of bounds: {}".format(host))
    
    return '52:54:00:{:02x}:{:02x}:{:02x}'.format(network, int(host / 256), host % 256)


def _reverse_network_address(netaddr):
    """ generates reverse network address
    192.168.1.0/24 -> 1.168.192.in-addr.arpa
    
    Arguments:
    netaddr -- ipaddress network object
    
    Returns:
        string containing the reverse network address
    """
    
    rev_addr = 'in-addr.arpa'
    addr = str(netaddr.network_address).split('.')
    for part in str(netaddr.netmask).split('.'):
        m = int(part)
        if m > 0:
            # Netmask is nonzero for this byte
            # so apply netmask to address and add it to reverse address
            rev_addr = '{}.{}'.format(int(addr.pop(0)) & m, rev_addr)
        else:
            break
        
    return rev_addr    

def _process_template(template_file, template_data, target_file):
    """
    """
    jinjaEnv = Environment(loader=FileSystemLoader(os.path.dirname(template_file)))
    template = jinjaEnv.get_template(os.path.basename(template_file))
    
    with open(target_file, 'w') as f:
            f.write(template.render(template_data))

def _process_template_directory(template_dir, template_data, target_dir):
    """ Reads complete directory structure of template_dir, process all files 
    with template engine and saves result into target directory.
    
    Arguments:
    template_dir -- string path of the directory structure that should be processes
    template_data -- dict containing the data used in templates
    target dir -- string where to store the resulting structure
    
    Returns:
    None, but throws exception on error
    """
    
    #os.mkdir(target_dir)
    jinjaEnv = Environment(loader=FileSystemLoader(template_dir))
    
    for template_file in jinjaEnv.list_templates():
        target_file = os.path.join(target_dir, template_file)
        os.makedirs(name=os.path.dirname(target_file), exist_ok=True)
        template = jinjaEnv.get_template(template_file)
        with open(target_file, 'w') as f:
            f.write(template.render(template_data))
        
        

def _prepare_template_data(network=None, sut_count=64, custom_product_repositories = {}):
    ''' Read the configuration and prepares the dict that contains the values needed by
    templates. The values are used together with various jinja2 templates to configure
    the test network and set up testing hosts.
    
    Arguments:
    network -- id of the network to prepare configuration for. If set to None, no network specific
               configuration will be added. (used for generating configuration for the test controller host)
    sut_count -- how many virtual SUT should be set up (in network configuration). This indicate the maximum 
                 number.
    custom_product_repositories - additional "product" repos in same form as products in config.ini
                                  names should be those that are expected in templates. Normally used for qarepo that contains test packages
                                    QA-SLE-11-SP3 = ibs:SLE-11-SP3
                                    QA-SLE-11-SP3-Update = ibs:SLE-11-SP3-Update
                                    QA-SLE-12 = ibs:SLE-12
                                    QA-openSUSE-13.1 = ibs:openSUSE-13.1
    
    Returns: 
        dict containing the data to use for jinja2 templates
    '''
    
    data = {}
    services = []
    
    # Proxy configuration + repository map to the proxy url
    data['proxy'] = {}
    data['repositories'] = {}
    data['networks'] = []
    
    data['testuser'] = {}
    data['testuser']['login']    = config['testuser']['login'] 
    data['testuser']['name']     = config['testuser']['name']
    data['testuser']['password'] = config['testuser']['password']
    
    data['dns'] = {}
    data['dns']['serial'] = datetime.date.today().strftime('%Y%m%d00')
    
    data['proxy']['port'] = config['global']['http_port']
    
    # map of repository server url to proxy url
    urlmap = {}
    
    for r in config['repositories']:
        url = urlsplit(config['repositories'][r])
        repodata = {}
        repodata['type'] = r 
        repodata['port'] = url.port if url.port else 80
        repodata['host'] = url.hostname
        repodata['url'] = url.path
        
        services.append(repodata)
        
        # repos is CNAME (or in /etc/hosts) to controller - host where reverse proxy is running
        urlmap[r] = urljoin('http://repos:{}'.format(data['proxy']['port']), repodata['url'])
    
    data['proxy']['services'] = services
    data['proxy']['urlmap'] = urlmap

    for product in config['products']:
        (repo, urlpart) = config['products'][product].split(':', 1)
        try:
            data['repositories'][product] = urlmap[repo]+ '/' + urlpart
        except KeyError:
            print("Skipping repository for {} - bad format or repository '{}' is not defined in repositories".format(product, repo))
    
    for product in custom_product_repositories:
        (repo, urlpart) = custom_product_repositories[product].split(':', 1)
        try:
            data['repositories'][product] = urlmap[repo]+ '/'+ urlpart
        except KeyError:
            print("Skipping repository for {} - bad format or repository '{}' is not defined in repositories".format(product, repo))
        
    for n in range(1, int(config['global']['networks']) + 1):
        c_net = config['network_{}'.format(n)]
        net = {}
        
        net['domain'] = c_net['domain']
        net['bridge'] = c_net['bridge']
        
        ipnet = ipaddress.ip_network(c_net['network'])
        net['broadcast_ip'] = ipnet.broadcast_address
        net['address'] = ipnet.network_address
        net['netmask'] = ipnet.netmask
        net['reverse'] = _reverse_network_address(ipnet)
        

 
        # hosts() is generator, but I need index it -> create list.
        hosts = list(ipnet.hosts())

        host_num = 0        
        for special in ['controller', 'server', 'hamsta', 'qadb', 'qadbreport']:
            net[special] = {}
            net[special]['ip'] = hosts[host_num]
            net[special]['reverse'] = _reverse_network_address(ipaddress.ip_network('{}/32'.format(hosts[host_num])))
            if special != 'controller':     # Controller has its own mac address!
                net[special]['mac'] = _generate_mac_address(n, host_num)
            net[special]['fqdn'] = special + '.' + net['domain']
            net[special]['name'] = special
            host_num += 1
        
        # TODO: add real hw SUTs here
        
        # add SUTs
        net['suts'] = []
        for ip in hosts[host_num:host_num+sut_count]:
            sut = {}
            sut['ip'] = ip
            sut['reverse'] = _reverse_network_address(ipaddress.ip_network('{}/32'.format(hosts[host_num])))
            sut['mac'] = _generate_mac_address(n, host_num)
            sut['name'] = 'sut-{:02d}'.format(len(net['suts'])+1)
            sut['fqdn'] = sut['name'] + '.' + net['domain']
            net['suts'].append(sut)
            host_num += 1

        net['dynamic_start'] = hosts[host_num]
        net['dynamic_end'] = hosts[-1]

        data['networks'].append(net)
        
    if network is not None:
        if network <= 0 or network > int(config['global']['networks']):
            raise IndexError('Network index ({}) out of bounds'.format(network))
        
        data['network'] = data['networks'][network - 1]
        
    return data

