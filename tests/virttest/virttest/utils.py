#!/usr/bin/python3

from . import _config

from jinja2 import Environment, FileSystemLoader
from urllib.parse import urlsplit, urljoin
import ipaddress
import datetime
import os
import shutil


def create_systemwide_configuration(config_path = None):
    ''' Create system-wide configuration replacing the existing files with the files
    automatically generated from templates. The configuration is placed in
    <workdir>/system_config where workdir is specified in config.ini unless specified 
    by config_path argument
    '''
    data = _prepare_template_data()
    
    if(config_path is None):
        config_path = os.path.join(data['global']['workdir'], 'system_config')
        shutil.rmtree(config_path)

    os.makedirs(config_path, exist_ok = True)
    _process_template_directory('templates/controller', data, config_path)



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
    data['dns'] = {}
    data['dns']['serial'] = datetime.date.today().strftime('%Y%m%d00')
    
    data['proxy']['port'] = _config['global']['http_port']
    
    # map of repository server url to proxy url
    urlmap = {}
    
    for r in _config['repositories']:
        url = urlsplit(_config['repositories'][r])
        repodata = {}
        repodata['type'] = r 
        repodata['port'] = url.port if url.port else 80
        repodata['host'] = url.hostname
        repodata['url'] = url.path
        
        services.append(repodata)
        
        # repos is CNAME (or in /etc/hosts) to controller - host where reverse proxy is running
        urlmap[r] = urljoin('http://repos:{}'.format(data['proxy']['port']), repodata['url'])
    
    data['proxy']['services'] = services

    for product in _config['products']:
        (repo, urlpart) = _config['products'][product].split(':')
        try:
            data['repositories'][product] = urljoin(urlmap[repo]+ '/this_will_be_removed_by_urljoin', urlpart) # FIXME: urljoin sucks!
        except KeyError:
            print("Skipping repository for {} - bad format or repository '{}' is not defined in repositories".format(product, repo))
    
    for (product, url) in custom_product_repositories:
        (repo, urlpart) = url.split(':')
        try:
            data['repositories'][product] = urljoin(urlmap[repo]+ '/this_will_be_removed_by_urljoin', urlpart) # FIXME: urljoin sucks!
        except KeyError:
            # Raise again, since we must make sure our repo is accessible through pound reverse proxy
            print("Repository for {} - bad format or repository '{}' is not defined in repositories".format(product, repo))
            raise
                
    for n in range(1, int(_config['global']['networks']) + 1):
        c_net = _config['network_{}'.format(n)]
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
            net['suts'].append(sut)
            host_num += 1

        net['dynamic_start'] = hosts[host_num]
        net['dynamic_end'] = hosts[-1]

        data['networks'].append(net)
        
    if network is not None:
        if network <= 0 or network > int(_config['global']['networks']):
            raise IndexError('Network index ({}) out of bounds'.format(network))
        
        data['network'] = data['networks'][network - 1]
        
    return data
