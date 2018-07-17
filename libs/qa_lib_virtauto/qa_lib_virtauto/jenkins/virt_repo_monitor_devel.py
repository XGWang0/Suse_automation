#!/usr/bin/env python

import json
import xml.etree.ElementTree as ET
import optparse
import logging
import os
import re
import sys
import subprocess
import time
import copy
import shutil
from urllib2 import urlopen, HTTPError, URLError


class LoggerHandling(object):
    """Class which support to add five kind of level info to file
    and standard output 
    """
    def __init__(self, log_file, log_level=logging.DEBUG):
        logging.basicConfig(level=logging.DEBUG,
                            format='%(asctime)s %(filename)s[line:%(lineno)d] [%(process)d]-[%(threadName)s] %(levelname)-6s | %(message)s',
                            datefmt='%a, %d %b %Y %H:%M:%S',
                            filename=log_file,
                            filemode='w')

        console = logging.StreamHandler()
        console.setLevel(log_level)
        formatter = logging.Formatter('%(asctime)s [%(process)d] [%(threadName)s]: %(levelname)-8s %(message)s')
        console.setFormatter(formatter)

        self.logger = logging.getLogger('')
        self.logger.addHandler(console)

    def debug(self, message):
        """Display debug message
        """
        self.logger.debug(message)

    def info(self, message):
        """Display info message
        """
        self.logger.info(message)

    def warn(self, message):
        """Display warning message
        """
        self.logger.warn("\033[1;33;47m" + message + "\033[0m")

    def error(self, message):
        """Display error message
        """
        self.logger.error("\033[1;31;47m" + message + "\033[0m")

    def crit(self, message):
        """Display Criticall message
        """
        self.logger.critical(message)

class URLParser(object):
    
    def __init__(self):
        pass

    @staticmethod
    def checkURLPath(url, times=3):
        
        for i in range(times):
            try:
                w = urlopen(url)
                return True
            except HTTPError,e:
                if i == 2:
                    LOGGER.warn("URL [%s] %s" %(url,e) )
                    return False
                else:
                    time.sleep(1)
                    continue
            except Exception, e:
                if times == 2:
                    LOGGER.warn("URL [%s] %s" %(url,e) )
                    return False
                else:
                    time.sleep(1)
                    continue


    def getValidURL(self, url):
        convert_url_flag = False
        while True:
            if URLParser().checkURLPath(url) is True:
                return url
            else:
                if convert_url_flag is True:
                    break
                if 'dvd' in url:
                    url = url.replace('dvd1','DVD1')
                    convert_url_flag = True
                    LOGGER.info("Try to convert url to %s" %url)
                elif 'DVD' in url:
                    url = url.replace('DVD1','dvd1')
                    convert_url_flag = True
                    LOGGER.info("Try to convert url to %s" %url)
                else:
                    LOGGER.info("url does not exist")
                    return ""
        
        return ""
    
    def getFileContent(self,url, times=3):

        url = self.getValidURL(url)
        if not url:
            LOGGER.info("There is invalid url %s , countent is empty" %url)
            return ''
      
        for i in range(times):           
            try:
                w = urlopen(url)
                r =  w.read()
                return r
            except HTTPError,e:
                LOGGER.error(str(e))
                if i == 2:
                    LOGGER.error("Failed to get access url %s" %url)
                    return ""
                else:
                    time.sleep(1)
                    continue
            except URLError, ex:
                if i == 2:
                    LOGGER.error(str(ex))
                    LOGGER.error("Failed to get access url %s" %url)
                    return ""
                else:
                    time.sleep(1)
                    continue
            except Exception, e:
                LOGGER.error(e)
            finally:
                pass
                #w.close()

class ParseCMDParam(optparse.OptionParser, object):
    """Class which parses command parameters
    """

    def __init__(self):
        optparse.OptionParser.__init__(
            self, 
            usage='Usage: %prog [options]',
            epilog="NOTE: This monitor script supports all projects triggering task.")

        # guest installation
        group = optparse.OptionGroup(
            self,
            "Prj1:Guest Installing",
            "This Group parameter is used to Prj1 Guest Installing ")

        self.add_option_group(group)
        group.add_option("--gi-prd", action="append", type="string",
                        dest="gi_prd_list",
                        help=("Input product version, just like sles-12-sp0-64 and sles-11-sp4-64,"
                              "This parameter as detecting object is used to check changed packages, if yes,"
                              "job of prj1 will be triggered automatically. This parameter supports multiple uses,"
                              "such as \"--gi-prd sles-12-sp0-64 --gi-prd sles-12-sp1-64\""))
        group.add_option("--gi-job", action="store", type="string",
                        dest="gi_job_name",
                        help=("Input the job link of prj1 in here"))

        #Host Upgrade Installing
        group = optparse.OptionGroup(
            self,
            "Prj2:Host Upgrade Installing",
            "Monitor relevant repositories change and trigger host upgrading test")

        self.add_option_group(group)
        group.add_option("--hu-prd", action="append", type="string",
                        dest="hu_prd_list",
                        help=("Input product version, just like sles-12-sp0-64 and sles-11-sp4-64,"
                              "This parameter as detecting object is used to check changed packages, if yes,"
                              "job of prj2 will be triggered automatically. This parameter supports multiple uses,"
                              "such as \"--hu-prd sles-12-sp0-64 --hu-prd sles-12-sp1-64\""))
        group.add_option("--hu-job", action="store", type="string",
                        dest="hu_job_name",
                        help=("Input the job link of prj1 in here"))

        group = optparse.OptionGroup(
            self,
            "Prj3:Guest Migration",
            "Monitor relevant repositories change and trigger guest migration test")

        self.add_option_group(group)
        group.add_option("--gm-prd", action="append", type="string",
                        dest="gm_prd_list",
                        help=("Input product version, just like sles-12-sp0-64 and sles-11-sp4-64,"
                              "This parameter as detecting object is used to check changed packages, if yes,"
                              "job of prj3 will be triggered automatically. This parameter supports multiple uses,"
                              "such as \"--gm-prd sles-12-sp0-64 --gm-prd sles-12-sp1-64\""))
        group.add_option("--gm-job", action="store", type="string",
                        dest="gm_job_name",
                        help=("Input the job link of prj3 in here"))


        group = optparse.OptionGroup(
            self,
            "Prj4:Guest Upgrade",
            "Monitor relevant repositories change and trigger guest upgrade test")

        self.add_option_group(group)
        group.add_option("--gu-prd", action="append", type="string",
                        dest="gu_prd_list",
                        help=("Input product version, just like sles-12-sp0-64 and sles-11-sp4-64,"
                              "This parameter as detecting object is used to check changed packages, if yes,"
                              "job of prj3 will be triggered automatically. This parameter supports multiple uses,"
                              "such as \"--gm-prd sles-12-sp0-64 --gm-prd sles-12-sp1-64\""))
        group.add_option("--gu-job", action="store", type="string",
                        dest="gu_job_name",
                        help=("Input the job link of prj4 in here"))

        #Guest migration test parameters
        LOGGER.debug("Params : " + str(sys.argv))

class AllStaticFuncs(object):
    """Class which contains all staticmethod functions
    """
    def __init__(self):
        pass


    @staticmethod
    def getWorkSpace():
        return os.getenv("WORKSPACE", os.curdir)

    @staticmethod
    def getJksHome():
        return os.getenv("JENKINS_HOME", os.curdir)

    @staticmethod
    def checkIPAddress(ip_address):
        """Check if the host address is available through hamsta command line
        """
        (return_code, output) = runCMDBlocked(
            "/usr/share/hamsta/feed_hamsta.pl -p 127.0.0.1")
        LOGGER.debug("Current all availiable host %s" %output)
        if return_code == 0 and output:
            #if len(ip_address.split(".")) == 4 and re.search(ip_address.strip(),
            if re.search(ip_address.strip(), output, re.I):
                return True
            else:
                return False

    @staticmethod
    def getAvailHost(host_list):
        """Get availiable host list
        """
        tmp_host_list = map(lambda x: x.strip(), host_list)
        tmp_host_list = filter(AllStaticFuncs.checkIPAddress, tmp_host_list)
        LOGGER.info("Available hosts :" + str(tmp_host_list))
        return tmp_host_list

    @staticmethod
    def getBuildPath():
        """Get build path, environment WORKSPACE and BUILD_TAG are built-in 
        environment variable of jenkins
        """
        build_path = os.path.join(os.getenv("WORKSPACE", os.getcwd()),
                                   "LOG", os.getenv("BUILD_TAG", ""))
        if not os.path.exists(build_path):
            os.makedirs(build_path)
        return build_path

    @staticmethod
    def getJobURL():
        """Get environment variable JOB_URL which belongs to Jenkins variable
        """
        return os.getenv("JOB_URL", os.getcwd())

    @staticmethod
    def downloadFile(url, dl_path, mode='wb'):
        file_name = url.split('/')[-1]
        u = urlopen(url)
        f = open(os.path.join(dl_path, file_name), mode)
        file_size_dl = 0
        block_sz = 1024
        while True:
            buffer = u.read(block_sz)
            if not buffer:
                break
            file_size_dl += len(buffer)
            f.write(buffer)      
        f.close()

    @staticmethod
    def extractPackage(pack):
        '''This function can be used to work for *.gz file
        '''
        import StringIO
        import gzip
        #feed = urlopen(pack)
        # feed is compressed
        compressed_data = URLParser().getFileContent(pack)
        compressedstream = StringIO.StringIO(compressed_data)
        gzipper = gzip.GzipFile(fileobj=compressedstream)
        data = gzipper.read()

        return data

    @staticmethod
    def writeFile(filename, content):
        '''This function can be used to write content to file
        '''
        with open(filename, "w+") as f:
            LOGGER.debug("File is %s" %filename)
            f.seek(0)
            f.truncate()
            f.write(content)
        LOGGER.debug("File Name is %s" %filename)
        LOGGER.debug("File Content is %s" %content)

def runCMDBlocked(cmd):
    """Run a command line with blocking format
    """
    result = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE,
                              stderr=subprocess.PIPE)

    LOGGER.info("Execute cmd :%s" %cmd)
    (r_stdout, r_stderr) = result.communicate()
    return_code = result.returncode
    #LOGGER.info("Returned info :%s" %(r_stdout + r_stderr))
    return (return_code, r_stdout + r_stderr)

def runCMDNonBlocked(cmd, timeout=5):
    """Run command line with non-blocking format
    """
    #print "current param1 :%s \npid is :%s" %(task, os.getpid())

    start_time = datetime.datetime.now()
    result = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE,
                              stderr=subprocess.PIPE, preexec_fn=os.setpgrp)

    readbuf_msg = ""
    select_rfds = [result.stdout]
    result_buf = ""
    timeout_flag = False

    while len(select_rfds) > 0:
        (rfds, _wfds, _efds) = select.select(select_rfds, [], [], timeout)
        if not rfds:
            #print "kill pid = ",result.pid
            os.kill(-result.pid, signal.SIGKILL)
            timeout_flag = True
            result_buf = "--------timeout(%d secs)--------\n" %timeout
            return_code = 10
            break
        for rfd in rfds:
            readbuf_msg = rfd.readline()
            result_buf = result_buf + readbuf_msg
            if len(readbuf_msg) == 0:
                select_rfds.remove(result.stdout)

    result.wait()

    end_time = datetime.datetime.now()
    if timeout_flag is False:
        return_code = result.returncode

    return (return_code, result_buf, start_time, end_time)

class RepoMontior(object):
    
    AFFECTED_PKGS_SLE11 = {'com':['libvirt','libvirt-client','libvirt-python','virt-manager',
                                  'vm-install','perl-Sys-Virt-TCK','libvirt-daemon','libvirt-devel',
                                  'libvirt-doc','libvirt-lock-sanlock','qa_test_virtualization'],
                           'xen':['xen','kernel-xen','xen-tools','xen-libs','xen-devel','xen-doc-html',
                                  'xen-kmp-default','xen-kmp-trace','xen-tools-domU'],
                           'kvm':['qemu-x86','kvm','kernel-default','qemu-guest-agent'],
                           }

    AFFECTED_PKGS_SLE12 = {'com':AFFECTED_PKGS_SLE11['com'] + \
                           ['libvirt-daemon-driver-network', 'libvirt-daemon-driver-qemu',
                            'libvirt-daemon-driver-interface','libvirt-daemon-driver-nwfilter',
                            'libvirt-daemon-driver-secret', 'libvirt-daemon-driver-nodedev',
                            'libvirt-daemon-driver-storage','libvirt-daemon-qemu','qemu',
                            'libvirt-daemon-driver-lxc','libcap-ng-utils'],
                           'xen':['xen','kernel-xen','xen-tools','xen-libs','xen-devel','xen-doc-html',
                                  'xen-kmp-default','xen-kmp-trace','xen-tools-domU'],
                           'kvm':AFFECTED_PKGS_SLE11['kvm'] + ['qemu-tools'],
                           }
    
    TRIGGERED_JOB_PARAMS = {'VIRT_PRODUCT_VERSION':'',
                            'HOST_PRODUCT':'',
                            'HOST_LIST':''}
    
    def __init__(self):
        pass

    def getRepoAdress(self, product, repotype):
        '''repotype scope : virttest or virtdevel
        '''
        get_source_api = '/usr/share/qa/virtautolib/lib/get-source.sh'
        
        if os.path.exists(get_source_api):
            product = product.strip().lower()

            if repotype == 'virttest':
                get_repo_cmd = '%s -p source.virttest.%s' %(get_source_api, product)
            elif repotype == 'virtdevel':
                get_repo_cmd = '%s -p source.virtdevel.%s' %(get_source_api, product)

            return_code, result_buf = runCMDBlocked(get_repo_cmd)
            if return_code != 0:
                if 'sles-12-sp0-64' in product:
                    product_fcs = 'sles-12-fcs-64'
                    get_repo_cmd = get_repo_cmd.replace(product, product_fcs)
                    return_code, result_buf = runCMDBlocked(get_repo_cmd)
                    if return_code == 0:
                        repo_address = result_buf.strip()
                        LOGGER.info('%s %s repository address is [%s]' %(product, repotype, repo_address))
                        return repo_address
                else:
                    LOGGER.error('Failed to get %s %s repository, due to [%s]' %(product, repotype, result_buf))
                    return ""
            else:
                repo_address = result_buf.strip()
                LOGGER.info('%s %s repository address is [%s]' %(product, repotype, repo_address))
                return repo_address
        else:
            LOGGER.error("No get source api [%s] on local host" %get_source_api)
            sys.exit(-1)

    def getRelPkgsData(self, url):
        x86_64_url = os.path.join(url,'x86_64')
        noarch_url = os.path.join(url,'noarch')
        x86_64_content = URLParser().getFileContent(x86_64_url)
        noarch_content = URLParser().getFileContent(noarch_url)
        
        return x86_64_content + noarch_content

    def _getRepoData(self, url):
            url = os.path.join(url,'repodata/repomd.xml')
            xml_content = URLParser().getFileContent(url)
            if xml_content:
                root = ET.fromstring(str(xml_content))
                return root
            else:
                return None

    def getFileLIstPkg(self, base_url):
        def _getFileNmae(url):
            root = self._getRepoData(url)
            for c in root:
                if 'data' in c.tag and c.get('type') == "filelists":
                    for j in c:
                        if 'location' in j.tag:
                            return j.get('href')
            return None

        filelists = _getFileNmae(base_url)
        if filelists:
            filelists = os.path.join(base_url, filelists)
            if URLParser().checkURLPath(filelists):
                return AllStaticFuncs().extractPackage(filelists)
            else:
                LOGGER.warn("There is no filelist file with name [%s]" %filelists)
                return ''
        else:
            LOGGER.warn("Failed to get filelist file on link [%s]" %filelists)
            return ''

    def storeChgBVer(self, ver):
        if ver:
            if ver in RepoMontior.TRIGGERED_JOB_PARAMS['VIRT_PRODUCT_VERSION']:
                pass
            else:
                if RepoMontior.TRIGGERED_JOB_PARAMS['VIRT_PRODUCT_VERSION']:
                    RepoMontior.TRIGGERED_JOB_PARAMS['VIRT_PRODUCT_VERSION'] = ver
                else:
                    RepoMontior.TRIGGERED_JOB_PARAMS['VIRT_PRODUCT_VERSION'] += ',' + ver

    def getBuildVer(self, prd, url, repotype):
            
        root = self._getRepoData(url)
        #LOGGER.debug(root)
        tmp_ver = ''
        for i in root:
            if 'revision' in i.tag:
                value = i.text
                LOGGER.debug(value)
                if value and repotype == 'virttest':
                    tmp_ver = '%s-test:%s' %(prd.upper(), value)
                elif value and repotype == 'virtdevel':
                    tmp_ver = '%s-devel:%s' %(prd.upper(), value)
                LOGGER.debug(tmp_ver)                   
                return tmp_ver
                #__storeChgBVer(prd, i.text, repotype)
        
        return None

    def getPkg(self, pkgname, repocont):
        compile = re.compile('<package pkgid="(\S+)" name="%s" arch="(noarch|x86_64)">' %pkgname, re.I)
        re_i = compile.search(repocont)
        
        if re_i:
            return re_i.groups()[0]
        else:
            return ''

    def replaceLastRepo(self, repo_file, current_content):
        if current_content:
            LOGGER.info('Save repository data to file %s' %repo_file)
            with open(repo_file, "w+") as f:
                f.seek(0)
                f.truncate()
                f.write(current_content)

    def compareRepoChange(self, product, last_repo_file, current_content, rel_pkgs_data):

        def _getChgPKG(v_t, pkg_src, last_repo_cont, curr_repo_cont):
            chg_pkg = []
            for pkg in pkg_src[v_t]:
                last_pkgid = self.getPkg(pkg, last_repo_cont)
                curr_pkgid = self.getPkg(pkg, curr_repo_cont)
                
                if last_pkgid:
                    if curr_pkgid:
                        if last_pkgid == curr_pkgid:
                            LOGGER.info("Pkg %s is existent, no change"%pkg)
                            continue
                        else:
                            LOGGER.warn("Pkg %s is existent and changed" %pkg)
                            chg_pkg.append(pkg)
                    else:
                        LOGGER.debug("Not found pkg %s on previous pkg list file" %pkg)
                        continue
                else:
                    if curr_pkgid:
                        LOGGER.info("Pkg %s is existent and changed" %pkg)
                        chg_pkg.append(pkg)
                    else:
                        LOGGER.debug("Not found pkg %s on current pkg list file" %pkg)
                        continue
            return chg_pkg

        def _getPKGVer(product, pkg_list, rel_pkgs_data):
            rel_pkg_list = []

            for pkg in pkg_list:
                pkg_l = re.findall("%s-[0-9 . _ -]+?\.x86_64\.rpm" %(pkg) , rel_pkgs_data, re.I)
                if pkg_l:
                    rel_pkg_list.append(sorted(pkg_l)[-1])
                else:
                    rel_pkg_list.append(pkg)

            if rel_pkg_list:
                return "%s:%s@" %(product, ','.join(rel_pkg_list))
            else:
                return ""

        last_repo_cont = ''
        curr_repo_cont = current_content
        product = product.upper()
        cmp_status = False
        chg_prd = ''

        tmp_chg_pkg_data = []
        chg_pkg = []

        if 'sles-12'.upper() in product:
            affected_pkg = RepoMontior.AFFECTED_PKGS_SLE12
        else:
            affected_pkg = RepoMontior.AFFECTED_PKGS_SLE11

        LOGGER.debug("last saved repo file is %s" %last_repo_file)
        if os.path.exists(last_repo_file):
            with open(last_repo_file, 'r') as f:
                last_repo_cont = f.read()

            for v_t in ['com', 'kvm', 'xen']:
                LOGGER.info(' '*30 + '-'*10 + v_t + '<<' + '-'*10 + ' '*30)
                tmp_chg_pkg_data = _getChgPKG(v_t, affected_pkg, last_repo_cont, curr_repo_cont)
                if tmp_chg_pkg_data:
                    cmp_status |= True
                    if v_t == "com":
                        chg_prd = '%s.KVM,%s.XEN' %(product, product)
                        LOGGER.info("Common packages are changed, trigger xen and kvm test")
                    elif v_t == "kvm":
                        if chg_prd:
                            pass
                        else:
                            chg_prd = '%s.KVM' %product
                            LOGGER.info("KVM packages are changed, trigger kvm test")
                    elif v_t == "xen":
                        if 'XEN' in chg_prd:
                            pass
                        else:
                            chg_prd += chg_prd and ',%s.XEN' %product or '%s.XEN' %product
                            LOGGER.info("XEN packages are changed, trigger xen test")            
                    chg_pkg.extend(tmp_chg_pkg_data)
                    LOGGER.debug("Changed PRD is %s" %str(chg_prd))
                    LOGGER.info('Changed PKG list : %s' %(str(tmp_chg_pkg_data)))

                else:
                    LOGGER.info('No changed PKG on %s' %(v_t))
                LOGGER.info(' '*30 + '-'*10 + v_t + '>>' + '-'*10 + ' '*30)

            if cmp_status is False:
                LOGGER.info("No package changed !")
            #else:
            #    self.replaceLastRepo(last_repo_file, current_content)

            LOGGER.debug("cmp_status is %s" %str(cmp_status))
            chg_pkg_str = _getPKGVer(product, chg_pkg, rel_pkgs_data)
            return (cmp_status, chg_prd, chg_pkg_str)
            
        else:
            LOGGER.info("Not found last repo content, trigger xen and kvm test")
            chg_prd = '%s.KVM,%s.XEN' %(product, product)
            cmp_status = True
            chg_pkg = affected_pkg['com'] + affected_pkg['xen'] + affected_pkg['kvm']
            chg_pkg_str = _getPKGVer(product, chg_pkg, rel_pkgs_data)
            #self.replaceLastRepo(last_repo_file, current_content)
            return (cmp_status, chg_prd, chg_pkg_str)

    def outputJobParam2File(self, absfile=None):
        if absfile is None:
            absfile = self.output_file

        LOGGER.debug(absfile)
        file_content = ''
        for name, value in RepoMontior.TRIGGERED_JOB_PARAMS.items():
            file_content += "%s=%s%s" %(name,value,os.linesep)

        with open(absfile, "w+") as f:
            f.seek(0)
            f.truncate()
            f.write(file_content)

class JenkinsAPI(object):
    JOB_STATUS = {'pending':11,
                  'running':13,
                  'passed':15,
                  'failed':17}

    def __init__(self, jenkins_url):
        self.jenkins_url = jenkins_url

    def getJobsData(self, url=None):
        #url = 'http://jenkins.virt.lab.novell.com:8080/job/QAA/job/01_InstallingGuest/job/02_execute_test/'
        #url = os.path.join(url, 'api', 'json?pretty=true')
        if url is None:
            url = self.jenkins_url
        jobs_list = []
        try:
            req = urlopen(url)
            res = req.read()
            data = json.loads(res)
            return data
            '''
            import pprint
            pprint.pprint(data)
            print data['name']
            return data['name']
            '''
        except HTTPError, e:
            LOGGER.warn("Failed to access website ,cause [%s]" %e)
            return []
    
    def getJobStatus(self, url=None):
        if url is None:
            url = self.jenkins_url
        url = os.path.join(url, 'api', 'json?pretty=true')
        jobs_data = self.getJobsData(url)
        if jobs_data['color'] == 'blue':
            return 17
        elif 'anime' in jobs_data['color'] or "disabled" in jobs_data['color']:
            return 13
        elif  jobs_data['color'] == "red":
            return 15
        else:
            return 0


    def getJobDefParam(self, param_name, url=None):
        if url is None:
            url = self.jenkins_url
        url = os.path.join(url, 'api', 'json?pretty=true',
                           '&tree=actions[parameterDefinitions[name,defaultParameterValue[value]]]')
        data = self.getJobsData(url)
        LOGGER.debug(data)
        if 'actions' in data:
            data_act =  data['actions']
            for act_data in data_act:
                if 'parameterDefinitions' in act_data:
                    data_act_param = act_data['parameterDefinitions']
                    for param_data in data_act_param:
                        if param_data['name'] == param_name:
                            return param_data['defaultParameterValue']['value']
        return None

class PorjectMonitor(object):
    def __init__(self, options, rm):
        self.rm = rm
        self.options = options
        self.project_data = self.getPrjData()
        LOGGER.debug(self.project_data)
        self.all_prd_list = []
        self.status = False
        
        self.hu_scenarios = ""
        self.gm_scenarios = ""
        
        
    def getPrjData(self):
        LOGGER.info('Initial command line parameter data')
        tmp_prj_data = []
        if self.options.gi_prd_list and self.options.gi_job_name:
            tmp_prj_data.append({'name':'GI',
                                  'prdlist':self.options.gi_prd_list,
                                  'trigjob':self.options.gi_job_name,
                                  'paramet':self.getFmtOfParamData('GI'),
                                  'chkprd':[],
                                  'status':False})
        if self.options.hu_prd_list and self.options.hu_job_name:
            tmp_prj_data.append({'name':'HU',
                                  'prdlist':self.options.hu_prd_list,
                                  'trigjob':self.options.hu_job_name,
                                  'paramet':self.getFmtOfParamData('HU'),
                                  'chkprd':[],
                                  'status':False})
        if self.options.gm_prd_list and self.options.gm_job_name:
            tmp_prj_data.append({'name':'GM',
                                  'prdlist':self.options.gm_prd_list,
                                  'trigjob':self.options.gm_job_name,
                                  'paramet':self.getFmtOfParamData('GM'),
                                  'chkprd':[],
                                  'status':False})
        if self.options.gu_prd_list and self.options.gu_job_name:
            tmp_prj_data.append({'name':'GU',
                                  'prdlist':self.options.gu_prd_list,
                                  'trigjob':self.options.gu_job_name,
                                  'paramet':self.getFmtOfParamData('GU'),
                                  'chkprd':[],
                                  'status':False})
        return tmp_prj_data

    def getFmtOfParamData(self, project, ):
        if project == 'GI':
            param_data = {'VIRT_PRODUCT_VERSION':None,
                          'HOST_LIST':None,
                          'HOST_PRODUCT':None}
        elif project == 'HU':
            param_data = {'VIRT_PRODUCT_VERSION':None,
                          'HU_SCENARIOS':None,
                          'HOST_LIST':None,
                          'TEST_MODE':'dev'}
        elif project == 'GM':
            param_data = {'VIRT_PRODUCT_VERSION':None,
                          'GM_SCENARIOS':None,
                          'HOST_LIST':None,
                          'TEST_MODE':'dev'}
        elif project == 'GU':
            param_data = {'VIRT_PRODUCT_VERSION':None,
                          'HOST_LIST':None,
                          'HOST_PRODUCT':None}
        
        return param_data
        

    def cleanEnv(self):
        LOGGER.info('Clean expired data files')
        for i in self.project_data:
            for j in [self.getParamOutputFile(i['name']),
                      self.getNoHostFlagFile(i['name'])]:
                if j and os.path.exists(j):
                    os.remove(j)


    def initFolder(self, projectname):
        test_folder = 'VIRT_TEST_CFG'
        abs_folders = os.path.join(AllStaticFuncs().getWorkSpace(),
                                   test_folder, projectname.upper())
        if os.path.exists(abs_folders):
            pass
        else:
            os.makedirs(abs_folders)
        
        return abs_folders

    def getParamOutputFile(self, projectname):
        output_file = os.path.join(self.initFolder(projectname),
                                   '%s_TRIGGERED_JOB_PARAM_FILE' %projectname.upper())
        
        return output_file

    def getNoHostFlagFile(self, projectname):
        output_file = os.path.join(self.initFolder(projectname),
                                   '%s_TRIGGERED_JOB_NOHOST_FLAG' %projectname.upper())
        
        return output_file


    def getRepoDataOuputFile(self, projectname, product, stage='last'):
        output_folder = os.path.join(self.initFolder(projectname), 'repodata')
        if os.path.exists(output_folder):
            pass
        else:
            os.makedirs(output_folder)
        
        
        return os.path.join(output_folder, '%s_%s' %(stage, product))

    def updatePrjData(self, projectanme, verinfo, scenarios_list):
        def _unionList(listA, listB):
            list_a = set(listA)
            list_b = set(listB)
            
            return list(list_a | list_b)

        for i in self.project_data:
            if i['name'] == projectanme:
                i['status'] |= True
                if i['paramet']['VIRT_PRODUCT_VERSION']:
                    if verinfo in  i['paramet']['VIRT_PRODUCT_VERSION']:
                        pass
                    else:
                        i['paramet']['VIRT_PRODUCT_VERSION'] += verinfo
                else:
                    i['paramet']['VIRT_PRODUCT_VERSION'] = verinfo

                if projectanme in ['GI','GU']:
                    sce_name = 'HOST_PRODUCT'
                elif projectanme == 'HU':
                    sce_name = 'HU_SCENARIOS'
                elif projectanme == 'GM':
                    sce_name = 'GM_SCENARIOS'
                
                if i['paramet'][sce_name]:
                    tmp_prd = _unionList(i['paramet'][sce_name].split(","), scenarios_list)
                else:
                    tmp_prd = scenarios_list
                i['paramet'][sce_name] = ','.join(tmp_prd)

                '''
                elif projectanme == 'HU':
                    i['paramet']['HU_SCENARIOS'] = ','.join(scenarios_list)

                elif projectanme == 'GM':
                    i['paramet']['GM_SCENARIOS'] = ','.join(scenarios_list)
                '''
    def generateNoHostFile(self, prjdata):
        file_name = self.getNoHostFlagFile(prjdata['name'])
        msg = ("Detect that product version [%s] is changed."
               "Failed to trigger downstream job due to no available host."
               "Monitor job will continue to check build change at the next time" 
               %prjdata['chkprd'])
        file_content = "%s=%s" %('MAIL_CONTENT',msg)
        AllStaticFuncs().writeFile(file_name, file_content)

    def allocateHost(self):
        gi_def_host = hu_def_host = []
        gi_val = hu_val = None
        for i, val in enumerate(filter(lambda x: x['status'] is True, self.project_data)):
            def_host = val['paramet']['HOST_LIST']
            if val['name'] == 'GI':
                gi_def_host = val['paramet']['HOST_LIST'].split(',')
                gi_val = val
                continue
            elif val['name'] == 'HU':
                hu_def_host = val['paramet']['HOST_LIST'].split(',')
                hu_val = val
                continue

        prj1andprj2 = list(set(gi_def_host).intersection(set(hu_def_host)))
        LOGGER.debug("Intersection value is %s" %str(prj1andprj2))

        if len(prj1andprj2) > 1:
            for i,val in enumerate(prj1andprj2):
                if i%2 == 0:
                    gi_def_host.pop(gi_def_host.index(val))
                elif i %2 ==1:
                    hu_def_host.pop(hu_def_host.index(val))
        elif len(prj1andprj2) == 1:
            if len(gi_def_host) > len(hu_def_host):
                gi_def_host.pop(gi_def_host.index(prj1andprj2[0]))
            else:
                hu_def_host.pop(hu_def_host.index(prj1andprj2[0]))

        if not gi_def_host and gi_val:
            gi_val['status'] = False
            #Generate file for jenkins to check host stauts and send mail notification
            self.generateNoHostFile(gi_val)
            LOGGER.warn('Prj1 can not be trigger due to no available host')
        else:
            gi_def_host = ','.join(gi_def_host)
        if not hu_def_host and hu_val:
            hu_val['status'] = False
            #Generate file for jenkins to check host stauts and send mail notification
            self.generateNoHostFile(hu_val)   
            LOGGER.warn('Prj2 can not be trigger due to no available host')
        else:
            hu_def_host = ','.join(hu_def_host)

        LOGGER.debug('Project data is %s' %str(self.project_data))


    def getFreeHost(self, prj, hostpoll):
        hostlist = prj['paramet']['HOST_LIST'].split(',')
        chk_product = prj['chkprd']
        tmp_host_list = []
        if hostpoll:
            for host in hostlist:
                if host in hostpoll:
                    continue
                else:
                    tmp_host_list.append(host)
        else:
            tmp_host_list = hostlist
        
        if len(chk_product) <= len(tmp_host_list):
            return ','.join(tmp_host_list[0:len(chk_product)])
        else:
            return ','.join(tmp_host_list)
 
    def dumpParamData2File(self):
        LOGGER.info('Dump Parameters Data To File '.center(90,"="))
        tmp_free_host_all = ''
        for i in filter(lambda x: x['status'] is True, self.project_data):
            self.status |= True
            file_name = self.getParamOutputFile(i['name'])
            LOGGER.info('Dump parameter data to file %s' %file_name)
            '''
            freehost = self.getFreeHost(i, tmp_free_host_all)
            if freehost:
                i['paramet']['HOST_LIST'] = freehost
                tmp_free_host_all += ',%s' %freehost
            else:
                LOGGER.warn(("Project [%s] will not be triggered ,due to default host "
                             "[%s] is used by other project" %(i['name'],str(i['paramet']['HOST_LIST']))))
                i['status'] = False
                continue
            '''
            file_content = ''
            for name, value in i['paramet'].items():
                file_content += "%s=%s%s" %(name,value,os.linesep)
    
            with open(file_name, "w+") as f:
                LOGGER.debug("File is %s" %file_name)
                f.seek(0)
                f.truncate()
                LOGGER.info(file_content)
                f.write(file_content)
        if self.status is False:
            LOGGER.info("No changed repository data needs to be dumped")

    def updateLastRepoData(self):
        for i in filter(lambda x: x['status'] is True, self.project_data):
            for prd in i['chkprd']:
                LOGGER.debug("Update last repo data [%s] with current repo data [%s]" %(prd[0],prd[1]))
                shutil.copyfile(prd[1], prd[0])


    def updateAllPrdInfo2Dist(self, prj, cmpinfo):
        ''' Filter all relevant product version accourding to supplyed prd parameter
        '''

        prd = cmpinfo[1]
        verinfo = cmpinfo[2]
        org_prd = []
        dest_prd = []
    
        if prj in ['GI','GU']:
            self.updatePrjData(prj, verinfo, prd.split(","))

        elif prj == 'HU':
            triggered_scnearios = []
            for p in prd.split(','):
                for testsuite in self.hu_scenarios.strip().split(","):
                    if p in testsuite:
                        triggered_scnearios.append(testsuite.strip())
                    
            self.updatePrjData(prj, verinfo, triggered_scnearios)

        elif prj == 'GM':
            triggered_scnearios = []
            for p in prd.split(','):
                for testsuite in self.gm_scenarios.strip().split(","):
                    if p in testsuite:
                        triggered_scnearios.append(testsuite.strip())
            self.updatePrjData(prj, verinfo, triggered_scnearios)

    def checkHostInLastPrj(self, hostall, hostlist):
        tmp_host = []
        for host in hostlist:
            if host in hostall:
                continue
            else:
                tmp_host.append(host)
        
        return  tmp_host

    def popPrj(self, pd):
        for i, p in enumerate(self.project_data):
            if pd['name'] == p['name']:
                self.project_data.pop(i)

    def getIndex(self, pd):
        for i, p in enumerate(self.project_data):
            if pd['name'] == p['name']:
                return i
        return None    

    def checkTrigJob(self):
        LOGGER.info('')
        LOGGER.info(' Get Jenkins Job Info '.center(90,"="))
        
        host_all = []
        copy_prj_data = copy.deepcopy(self.project_data)

        LOGGER.debug(copy_prj_data)

        for i,pd in enumerate(copy_prj_data):
            if i != 0:
                copy_prj_data = copy.deepcopy(self.project_data)
                LOGGER.info('')
            LOGGER.info("[%d] Try  to get info from job %s" %(i+1, pd['trigjob']))
            LOGGER.debug(pd)
            jp = JenkinsAPI(pd['trigjob'])
            job_status = jp.getJobStatus()
            LOGGER.debug("JOb stataus is %d" %job_status)
            
            if job_status == 13:
                self.popPrj(pd)
                LOGGER.warn("Triggered job [%s] is running, skip packages comparison" %pd['trigjob'])
                continue
            else:
                host_list = jp.getJobDefParam('HOST_LIST')
                LOGGER.info("Project default host list is [%s]" %str(host_list))
                
                if host_list:
                    default_host = AllStaticFuncs().getAvailHost(host_list.split(','))
                    if default_host:
                        # Check multiple host only for prj3
                        if pd['name'] == 'GM':
                            if len(default_host) >= 2:
                                pass
                            else:
                                self.popPrj(pd)
                                LOGGER.warn("There is no enough hosts (2 or more) for running prj3, skip packages comparison")
                                continue

                        host_all.extend(default_host)
                        LOGGER.debug(self.project_data)
                        LOGGER.debug(i)
                        index = self.getIndex(pd)
                        self.project_data[index]['paramet']['HOST_LIST'] = ','.join(default_host)
                        self.all_prd_list = list(set(self.all_prd_list).union(set(pd['prdlist'])))
        
                        # Get the all default scenarios
                        if pd['name'] == 'GM':
                            self.gm_scenarios = jp.getJobDefParam("GM_SCENARIOS")
                        elif pd['name'] == 'HU':
                            self.hu_scenarios = jp.getJobDefParam("HU_SCENARIOS")
                    else:
                        self.popPrj(pd)
                        LOGGER.warn("There is no available host or default host will be used by other project, skip packages comparison")
                else:
                    self.popPrj(pd)
                    LOGGER.warn("Jenkins job [%s] does not set default host list, skip packages comarison" %pd['trigjob'])
        LOGGER.debug('Project data is %s' %str(self.project_data))
        LOGGER.debug('All product list is %s' %str(self.all_prd_list))

    def getRepoChange(self):
        LOGGER.info('')
        LOGGER.info(' Get Repository Info '.center(90,'='))
        for c,i in enumerate(self.all_prd_list):
            if c != 0:
                LOGGER.info('')
            LOGGER.info("[%d] Monitor %s repository change" %(c+1,i))
            tmp_repo_cont = ''
            # Get virtual devel repository and file list content
            virtdevel_url = self.rm.getRepoAdress(i, 'virtdevel')
            tmp_repo_cont = self.rm.getFileLIstPkg(virtdevel_url)

            # Get real pkg data from virt devel repo
            virtdevel_rel_pkg_data = self.rm.getRelPkgsData(virtdevel_url)
            
            '''
            # Get version information of virtual devel repository
            #ver_devel = self.rm.getBuildVer(i, virtdevel_url, 'virtdevel')
            '''
            # Get virtual test repository and file list content
            virttest_url = self.rm.getRepoAdress(i, 'virttest')
            rel = self.rm.getFileLIstPkg(virttest_url)
            
            # Get real pkg data from virt test repo
            virttest_rel_pkg_data = self.rm.getRelPkgsData(virttest_url)
            
            '''
            # Get version information of virtual test repository
            #ver_test = self.rm.getBuildVer(i, virttest_url, 'virttest')
            '''

            # Combine devel and test content of package list
            tmp_repo_cont += rel is not None and rel or ''
            LOGGER.debug(i)
            LOGGER.debug(self.project_data)
            # Package content of last time 
            for j,p in enumerate(filter(lambda x: i in x['prdlist'], self.project_data)):
                if j != 0:
                    LOGGER.info('')
                LOGGER.info('[%d.%d] Deal with data for project [%s] and product [%s]' %(c+1,j+1,i,p['name']))
                last_repo_file = self.getRepoDataOuputFile(p['name'], i, 'last')
                curr_repo_file = self.getRepoDataOuputFile(p['name'], i, 'curr')
                # Comparer package content of last time with current package content and
                # detect which package is changed
                rel = self.rm.compareRepoChange(i, last_repo_file, tmp_repo_cont,
                                                virtdevel_rel_pkg_data + virttest_rel_pkg_data)
                self.rm.replaceLastRepo(curr_repo_file, tmp_repo_cont)
                if rel[0] is True:
                    p['status'] = True
                    p['chkprd'].append((last_repo_file, curr_repo_file))
                    self.updateAllPrdInfo2Dist(p['name'], rel)

                    '''
                    for prd in self._getAllPrdInfoForHU(p['name'], rel):
                        self.updatePrjData(p['name'], rel[2], prd)
                        #self.updatePrjData(p['name'], ver_devel + ',' + ver_test, prd)
                    '''



def main():
    LOGGER.info(' START '.center(90,"="))
    param_opt = ParseCMDParam()
    options, _args = param_opt.parse_args()
    rm = RepoMontior()

    dp = PorjectMonitor(options, rm)
    dp.cleanEnv()
    dp.checkTrigJob()
    dp.getRepoChange()

    LOGGER.debug(dp.project_data)

    dp.allocateHost()
    dp.dumpParamData2File()
    dp.updateLastRepoData()
    LOGGER.info(' END '.center(90,"="))
    return dp.status is False and 1 or 0



LOGGER = LoggerHandling(os.path.join(AllStaticFuncs.getBuildPath(), "sys.log"), logging.DEBUG)

if __name__ == '__main__':
    #print JenkinsAPI("http://jenkins.virt.lab.novell.com:8080/job/QAA/job/01_InstallingGuest/job/02_execute_test/").getJobDefParam('HOST_LIST')
    #print JenkinsAPI("http://jenkins.virt.lab.novell.com:8080/job/QAA/job/01_InstallingGuest/job/02_execute_test/").getJobStatus()
    w = main()
    LOGGER.info(w)
    sys.exit(w)
