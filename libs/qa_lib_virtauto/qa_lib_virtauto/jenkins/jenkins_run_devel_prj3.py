import multiprocessing
import threading
import Queue
import os
import sys
import logging

from jenkins_run_devel_prj1 import *

class AllStaticFuncs(AllStaticFuncs):

    @staticmethod
    def pushList2Queue(obj_list, obj_task):
        for i in obj_list:
            obj_task.put(i)

class MultiThreadHostInstallation(GuestInstalling, object):
    '''Install host in parallel
    '''
    def __init__(self, task_q, build_v, test_mod, host_q):

        self.task_q = task_q
        self.host_q = host_q
        self.prd = self.getPrd(self.task_q)
        LOGGER.debug("prd is %s" %self.prd)
        super(MultiThreadHostInstallation, self).__init__(self.prd, build_v, test_mod, self.host_q)

        self.process_name = ''

        self.cmd11 = (self.feed_hamsta + " -x \"ls \" "
                    "-h %(host)s 127.0.0.1 -w")

    def getPrd(self, q):
        if q.qsize() > 0:
            return q.get(block=True, timeout=2)
        else:
            return None

    def storeTaskInstace(self, dict, key, value):
        dict[key] = value


    def execHamstaJob(self, cmd, timeout, job_sketch, phase, doc_str_flag=False, save_result=True, col_tc_rlt=False):
        '''Common function, which executes hamsta cmd to finish:
        1. collect hamsta output
        2. collect job terminal output and case substr.
        3. analyze result and generate job info map
        col_tc_rlt : Indicate that needs to get test case details if it is true 
        '''
        
        # Initial variables
        sub_tc_result = []
        job_id = 0

        if not self.checkHostStatus(timeout=1800):
            LOGGER.error("Host ip [%s] is not up status on hamster" %self.host)
            return_code = job_status_code = 1
            hamsta_output = job_result_all = 'Host [%s] is not available' %self.host
            qadb_link = ''
            job_sketch = 'Check Host Status'
            start_time = end_time = datetime.datetime.now()
            self.status = False
            
        else:
            LOGGER.info("Execute \"%s\" on %s machine" %(job_sketch, self.host))
            (return_code, hamsta_output,
             start_time, end_time) = runCMDNonBlocked(cmd, timeout=timeout)
            LOGGER.info('CMD:%s, return_valure:%s, return_result:%s' %(cmd, str(return_code), hamsta_output))
            #Get qadb link for test suite
            job_status, job_id = self.getJobStatus(hamsta_output)
    
            #Analyze hamsta status and job status
            if return_code == 0:
                if job_status == "passed" :
                    job_status_code = 0
                    self.status = True
                    return_msg = ("Finished \"%s\" successfully" %(job_sketch))
                else:
                    job_status_code = 1
                    self.status = False
                    return_msg = ("Failed to execute \"%s\"" %(job_sketch))
                    
            else:
                if return_code == 10:
                    self.timeout_flag = True
                job_status_code = return_code
                self.status = False
    
                return_msg = ("Failed to execute \"%s\" ,cause :[%s]" %(job_sketch, hamsta_output))
   
            job_result_all = self.parseOutput(hamsta_output)
            qadb_link = self.getQadbURL(job_result_all)
            
            if col_tc_rlt is True:
                sub_tc_result = self.getSubCaseData()

            fmt_result_all = AllStaticFuncs.genStandardOutout("%s %s" %(phase, job_sketch),
                                                              job_status,
                                                              job_result_all,
                                                              display_phase=True)
            LOGGER.info(return_msg)

        if self.status is True and save_result is False:
            LOGGER.debug("Do not save result data")
        else:
            if int(job_id) > 0:
                 job_sketch += ' {HID:%s}' %job_id
            #Collect job information
            result_map = {"doc_str_flag":doc_str_flag,
                          "scenario_status":job_status_code,
                          "step_info":sub_tc_result,
                          "scenario_alloutput":job_result_all,
                          "scenario_qadb_url":qadb_link,
                          "scenario_name":job_sketch,
                          "hamsta_output":hamsta_output,
                          "hamsta_status":return_code,
                          "start_time":start_time,
                          "end_time":end_time
                          }
    
            self.result.append(result_map)

    def getSubCaseData(self, prefix_tc_cont="STDOUT\s+job"):
        '''Split result and get sub test case result,
           then convert sub result into list
    
        Sub case result content:
        2015-11-30 08:22:35    STDOUT    job    Overall migration result start:
        2015-11-30 08:22:35    STDOUT    job    testcase ---------- result ---------- reason
        2015-11-30 08:22:35    STDOUT    job    virsh migrate --live --p2p --persistent --change-protection --unsafe --compressed --abort-on-error sles-11-sp3-32-fv-def-net qemu+ssh://151.155.144.33/system tcp://151.155.144.33 ---------- pass
        2015-11-30 08:22:35    STDOUT    job    virsh migrate --live --tunnelled --p2p --persistent --change-protection --unsafe --compressed --abort-on-error sles-11-sp3-32-fv-def-net qemu+ssh://151.155.144.33/system ---------- fail
        2015-11-30 08:22:35    STDOUT    job    virsh migrate --live --p2p --persistent --change-protection --unsafe --compressed --abort-on-error sles-11-sp3-64-fv-def-net qemu+ssh://151.155.144.33/system tcp://151.155.144.33 ---------- skip
        2015-11-30 08:22:36    STDOUT    job    virsh migrate --live --tunnelled --p2p --persistent --change-protection --unsafe --compressed --abort-on-error sles-11-sp3-64-fv-def-net qemu+ssh://151.155.144.33/system ---------- pass
        2015-11-30 08:22:36    STDERR    job    redirecting to systemctl stop named.service
        2015-11-30 08:22:36    STDOUT    job    Overall migration result end.
         
         Result:
         [{'step_name':'sles-11-sp2-64-fv-def-net',
           'step_status':'PASSED',
           'step_duration':1000,
           'step_stdout':'',
           'step_errout':''},
           {...},....]
        '''
        def _getGUestInfo(msg):
            flag = False
            for item in msg.split():
                if '--' in item:
                    flag = True
                    continue
                elif '--' not in item and flag is True:
                    return item
    
    
        # Directly fetch test result from test machine
        get_rlt_cmd = self.feed_hamsta + (' -x \''
                                      '<![CDATA[result=`find /var/log/qa/oldlogs/'
                                      ' -mindepth 3 -iname "guest_migrate_*" | tail -1 `;'
                                      ' if [[ -f $result && -n "$result" ]];then cat $result; fi ]]>\'' 
                                      ' -h %s 127.0.0.1 -w') %self.host

        (rd, ho, st, et) = runCMDNonBlocked(get_rlt_cmd, timeout=300)
        test_result = self.parseOutput(ho)
        LOGGER.debug("Test result is ----- %s" %test_result)

        tmp_allcase_result = []
        case_cont_compile = re.compile("%s\s+(virsh migrate.*?|xl migrate.*?|xm migrate.*?)\s+----------\s+(pass|fail|skip|timeout)" %prefix_tc_cont, re.I)
        case_result_list = re.findall(case_cont_compile, test_result)
        LOGGER.debug("test for getSubCaseData, output:" + test_result)
        LOGGER.debug('getSubCaseData case list : %s' %str(case_result_list))
    
        if case_result_list:
            for case_result in case_result_list:
                if 'xl migrate' in case_result[0]:
                    case_msg = 'xl_migrate'
                elif 'xm migrate' in case_result[0]:
                    case_msg = 'xm_migrate'
                else:
                    case_msg = 'virsh_migrate'
                #case_msg = 'virsh_migrate'
                if 'live' in case_result[0]:
                    case_msg += '_live'
                else:
                    case_msg += '_nolive'
            
                if 'p2p' in case_result[0]:
                    case_msg += '_p2p'
                if 'tunnelled' in case_result[0]:
                    case_msg += '_tunnelled'
                
                guest_info = _getGUestInfo(case_result[0])
                if guest_info:
                    case_msg += '_%s' %guest_info
    
                tmp_case_map = {}
                tmp_case_map["step_name"] = case_msg
                if 'pass' in case_result[1]:
                    tmp_case_map["step_status"] = 'passed'
                elif 'skip' in case_result[1]:
                    tmp_case_map["step_status"] = 'skipped'
                else:
                    tmp_case_map["step_status"] = 'failed'
                tmp_case_map["step_duration"] = 0
                tmp_case_map["step_stdout"] = 'pass' in case_result[1] and case_result[0] or ''
                tmp_case_map["step_errout"] = 'pass' not in case_result[1] and case_result[0] or ''
                LOGGER.debug('getSubCaseData case map %s' %str(tmp_case_map))
                tmp_allcase_result.append(tmp_case_map)
    
        return tmp_allcase_result

    def installHost(self, addon_repo= "", phase="Phase0", timeout=4800):
        """Reinstall host by hamsta cmd:
        feed_hamsta.pl -t 5 --re_url  repo -re_sdk sdk --pattern kvm/xen_server
        -rpms qa_test_virtualization -h host 127.0.0.1 -w

        if xen type, execute extra switching xen kerenl
        """
        #Prepare all needed repos
        source_name = "source.%s.%s"%(self.repo_type, self.prd_ver.lower())
        host_img_repo = self.prepareRepos(source_name)

        if self.status:
            
            cmd_install_host = (self.cmd_installhost %dict(img_repo=host_img_repo,
                                                          host=self.host,
                                                          virttype=self.virt_type.lower()))
            #cmd_install_host = self.cmd11 %dict(host=self.host)
            if DEBUG:
                # runCMDBlocked("scp /root/xgwang/prj3/* root@%s.bej.suse.com:/tmp/" %self.host)
                cmd_install_host = self.cmd11 %dict(host=self.host)

            LOGGER.info(("Start to install host with cmd[%s] on machine %s in parallel"
                         %(cmd_install_host, self.host)))
            #Install host
            self.execHamstaJob(cmd=cmd_install_host,
                               timeout=timeout,
                               job_sketch="Install host %s" %self.host,
                               phase=phase)

            #Switch xen kernel
            if self.virt_type == "XEN":
                self.switchXenKernel()
        else:
            LOGGER.warn("Failed to reserver host, skip host reinstallation")

    def run(self, status_q, lock, hig_pri_task):


        self.setDefaultGrub(phase="Phase0")
        self.rebootHost(phase="Phase0",job_sketch="Reboot Machine %s To Initialize Status" %(self.host))
        self.installHost(phase="Phase1")
        self.updateRPM(phase="Phase2", job_sketch="Upgrade Virt RPM For %s" %self.prd)
        self.makeEffect2RPM(phase="Phase2.1", job_sketch="Reboot %s To Activate New Virt RPM" %(self.host))

        lock.acquire()
        LOGGER.debug("prd is %s, hig_pri_task is %s" %(self.prd,hig_pri_task))
        #if status_q['org_host_task'] is None:
        if self.prd == hig_pri_task and status_q['org_host_task'] is None: # High priority task will be stored in previous position
            self.process_name = 'org_host_task'
            self.storeTaskInstace(status_q, key='org_host_task', value=self)
            LOGGER.info("Org host %s" %self.host)
        else:
            self.process_name = 'dest_host_task'
            self.storeTaskInstace(status_q, key='dest_host_task', value=self)
            LOGGER.info("Dest host %s" %self.host)
        lock.release()

class GuestMigration(object):

    def __init__(self, prd_list, build_v, test_mod, host_queue):
        self.prd_list = prd_list
        self.host_list = []
        self.build_v = build_v
        self.test_mod = test_mod
        self.queue = host_queue
        self.host_q = Queue.Queue()
        self.task_q = Queue.Queue()
        self.task_status = {'org_host_task':None, 'dest_host_task':None}

        self.feed_hamsta = "/usr/share/hamsta/feed_hamsta.pl"
        self.status = True
        self.result = []
        # Reserve host group
        self.reserveHost()

    def checkHostGroup(self, hosts):
        for host in hosts:
            if AllStaticFuncs().checkIPAddress(host) is False:
                LOGGER.info("Machine [%s] is down, no enough machine to do test!!" %host)
                return False
        return True

    def reserveHost(self, timeout=1800):
        '''Reserve available and free host
        '''
        LOGGER.info("Start to reserve host")

        start_time = datetime.datetime.now()
        now = time.time()
        while time.time() - now < timeout:
            if self.queue.qsize() == 0:
                LOGGER.warn("There is no available host in queue")
                time.sleep(20)
            else:
                self.host_list = self.queue.get(block=True, timeout=2)
                if self.checkHostGroup(self.host_list) is True:
                    AllStaticFuncs().pushList2Queue(self.host_list, self.host_q)
                    LOGGER.info("Reserve hosts [%s]" %str(self.host_list))
                    return 
                else:
                    break

        LOGGER.error("There is no available host, exit!!")

        self.status = False
        self.no_host_flag = True
        result_map = {"scenario_status":20,
                      "step_info":[],
                      "scenario_alloutput":"No Availbale host group",
                      "doc_str_flag":True,
                      "scenario_qadb_url":'',
                      "scenario_name":"Reserve host",
                      "hamsta_output":"No Availbale host",
                      "hamsta_status":0,
                      "start_time":start_time,
                      "end_time":datetime.datetime.now()}
        self.result.append(result_map)

    def releaseHost(self):
        '''Back host address into queue after finishing test on host
        '''
        self.queue.put(self.host_list)
        LOGGER.debug("Insert host list %s to queue %d" %(str(self.host_list), self.queue.qsize()))

    def storePrd2Queue(self):
        if self.status:
            LOGGER.debug("store prd : %s" %str(self.prd_list))
            AllStaticFuncs().pushList2Queue(self.prd_list, self.task_q)
        else:
            LOGGER.info("Failed to reserve host group, skip storing tasks")
 
    def installHostAndVM(self):
    
        base_prd = self.prd_list[0]
        LOGGER.debug("prd list is %s" %str(self.prd_list))
        LOGGER.debug("the base prd %s" %str(base_prd))
        if self.status:
            task_lock = threading.Lock()
        
            t1 = threading.Thread(name="thread1",
                                  target=MultiThreadHostInstallation(self.task_q, self.build_v,
                                                          self.test_mod, self.host_q).run,
                                  args=(self.task_status, task_lock, base_prd))
            t2 = threading.Thread(name="thread2",
                                  target=MultiThreadHostInstallation(self.task_q, self.build_v,
                                                          self.test_mod, self.host_q).run,
                                  args=(self.task_status, task_lock, base_prd))
            t1.start()
            t2.start()
            
            t1.join()
            t2.join()
        
            for w in self.task_status.values():
                LOGGER.debug(w.status)
                self.status &= w.status
                self.result.append(w.result)
    
            LOGGER.debug(self.result)
            LOGGER.debug('-'*100)
            LOGGER.debug(self.status)
            LOGGER.debug('-'*100)
            return self.status
        else:
            LOGGER.error("Last phase failure, skip installing hosts")

    def getGuestFilter(self, guest_prd):
        ''' Get specify guest product versions
        '''
        all_prd_filter_list = guest_prd.split(",")
        for prd_guest_filter in all_prd_filter_list:
            if re.search("%s.*?%s\s*?=\s*?" %(self.prd_list[0], self.prd_list[1]), prd_guest_filter, re.I):
                prd_filter = re.sub("%s.*?%s\s*?=\s*" %(self.prd_list[0], self.prd_list[1]), "", prd_guest_filter).strip()
                if prd_filter:
                    return prd_filter.replace("|", ",")
                else:
                    break
        
        return "sles-11,sles-12,sled-11,sled-12"

    def migrateGuest2DestHost(self, timeout=86400, guest_prd='SLES-12-SP2-64.XEN->SLES-12-SP2-64.XEN = sles-12-sp2-64'):
        """Execute guest migration script via HAMSTA
        """
        if self.status:
            org_host_self = self.task_status['org_host_task']
            dest_host_self = self.task_status['dest_host_task']
            guest_filter = self.getGuestFilter(guest_prd)

            cmd_gm_on_machine = " -x \"/usr/share/qa/tools/test_virtualization-guest-migrate-run -d %(desthost)s -v %(virttype)s -u root -p susetestng -i %(guestprd)s -t %(timeout)s\""

            cmd_guest_migration = (self.feed_hamsta + cmd_gm_on_machine + 
                                   " -h %(host)s 127.0.0.1 -w") %dict(host=org_host_self.host,
                                                                     desthost=dest_host_self.host,
                                                                     virttype=org_host_self.virt_type,
                                                                     guestprd=guest_filter,
                                                                     timeout=timeout)
            #cmd_guest_migration = self.feed_hamsta + " -x \"ls \"  -h %(host)s 127.0.0.1 -w" %dict(host=org_host_self.host)
            #cmd_guest_migration = self.feed_hamsta + " -x \"/tmp/test.sh \"  -h %(host)s 127.0.0.1 -w" %dict(host=org_host_self.host)
            LOGGER.info(("Start to migrate guest with cmd[%s] on machine %s"
                         %(cmd_guest_migration, self.task_status['org_host_task'].host)))
            #Install host
            LOGGER.debug("timeout is %d" %timeout)
            org_host_self.execHamstaJob(cmd=cmd_guest_migration,
                                        timeout=timeout,
                                        job_sketch="Migration Test",
                                        phase="Phase3",
                                        col_tc_rlt=True)
        else:
            LOGGER.warn("Last phase failure, skip guest migration operation")

    def _checkAttr(self, attr):
        if hasattr(self.task_status['org_host_task'], attr) and hasattr(self.task_status['dest_host_task'], attr):
            return True
        else:
            return False

    def collectResult(self, scen_stauts=True):
        '''Generate new data structure.
        '''
        def _getHostData():
            '''Get all org host and dest host, if no enough hosts or failed to reserve hosts, the host data will use 
                "host_list" variable as org and dest host data 
            '''
            LOGGER.debug(dir(self.task_status['org_host_task']))
            LOGGER.debug(dir(self.task_status['dest_host_task']))

            tmp_host_list = []
            if hasattr(self.task_status['org_host_task'], 'host') and hasattr(self.task_status['dest_host_task'], 'host'):
                tmp_host_list = [self.task_status['org_host_task'].host, self.task_status['dest_host_task'].host]
            else:
                tmp_host_list = self.host_list

            LOGGER.debug('Host List on collection function is %s' %str(tmp_host_list))
            return tmp_host_list

        def _getResultData():
            '''Get all result data, if no enough hosts or failed to reserve hosts, the report data will use 
                "result" variable as result data 
            '''
            tmp_result = []
            # Get host data from multiple thread object or host list.
            if hasattr(self.task_status['org_host_task'], 'result') and hasattr(self.task_status['dest_host_task'], 'result'):
                tmp_result = self.task_status['dest_host_task'].result + self.task_status['org_host_task'].result
            else:
                tmp_result = self.result
            
            return tmp_result

        def _getPrdVer():
            '''Get change version of repo
            '''
            tmp_prd_ver = ""
            for prd in self.prd_list:
                prd_ver = prd.strip().split(".")[0]
                tmp_prd_ver += ''.join(re.findall("%s-devel:\d+|%s-test:\d+" %(prd_ver,prd_ver),
                                                  self.build_v, re.I))
            return tmp_prd_ver

        feature_desc = ("Target : Guest Migration test mainly tests whether migrating"
                        " various supported vm guests from a low version product source"
                        " host to a high or equal version product destination host are "
                        "successful and whether the virtualualization administration test"
                        " over the guests before and after the migration are successful.")

        org_host, dest_host = _getHostData()

        feature_desc += "\nTest Type : %s" %'Devel/Unit Test'
        #feature_desc += "\nVirt Type : %s" %self.virt_type
        feature_desc += '\nOrg_host:%s\nDest_host:%s'%(org_host, dest_host)
        feature_desc += "\nChanged Packages List : \n%s" %_getPrdVer()
        
        scen_stauts = self.status

        tmp_job_map = {}
        tmp_job_map["feature_prefix_name"] = 'Guest-Migration '
        tmp_job_map["feature_host"] = 'Org_host:%s\nDest_host:%s'%(org_host, dest_host)
        tmp_job_map["feature_prj_name"] = "%s -> %s" %(self.prd_list[0],
                                                       self.prd_list[1])
        tmp_job_map["scenario_info"] = _getResultData()
        tmp_job_map["feature_desc"] = feature_desc
        tmp_job_map["feature_status"] =  scen_stauts
        
        LOGGER.debug(tmp_job_map)
        
        return tmp_job_map


class MultipleProcessRun(MultipleProcessRun, object):
    """Class which supports multiple process running for virtualization
    """

    def __init__(self, options):
        """Initial process pool, valiables and constant values 
        """
        super(MultipleProcessRun, self).__init__(options)

    def _divideHost2Q(self, step=2):
        avail_host_group = []
        tmplist = []
        all_host_list = AllStaticFuncs.getAvailHost(self.options.gm_host_list.split(","))
        for h in all_host_list:
            tmplist.append(h)
            if len(tmplist) == 2:
                self.queue.put(tmplist)
                avail_host_group.append(tmplist)
                tmplist = []
                continue
        LOGGER.debug("All avaliable host group are %s" %(str(avail_host_group)))

    def startRun(self):

        self.gm_guest_prd = self.options.gm_guest_prd
        self._divideHost2Q()
        #self.org_prd_list = self.options.gm_org_prd.strip().split(",")
        #self.dest_prd_list = self.options.gm_dest_prd.strip().split(",")
        self.scenarios = self.options.gm_scenarios.strip().split(",")

        self.param = (self.build_version, self.test_mode)

        #Pool size is defined through host number.
        q_size = self.queue.qsize()
        if q_size != 0:
            self.pool = multiprocessing.Pool(processes=q_size)
            LOGGER.debug("Create process pool[%d]" %q_size)
            #self.initialQueue()
            self._gmMultipleTask()
            self.closeAndJoinPool()
        else:
            self.prj_status["status"]= False
            self.createFileFlag()
            self.prj_status["info"] = "There is no available host"

    def _gmMultipleTask(self):
        #for prd_list in self.combineProductV(self.org_prd_list, self.dest_prd_list):
        for test_suite in self.scenarios:
            prd_list = re.split("\s*->\s*", test_suite.strip())
            LOGGER.debug("prd_list is %s" %str(prd_list))
            #migrateGuest(prd_list, self.build_version, self.test_mode, self.queue, self.gm_guest_prd)

            self.result.append([prd_list,
                self.pool.apply_async(migrateGuest,
                                      (prd_list, self.build_version, self.test_mode, self.queue, self.gm_guest_prd))])

def migrateGuest(prd_list, prd_ver, test_mode, host_queue, guest_prd):

    gm = GuestMigration(prd_list, prd_ver, test_mode, host_queue)
    #gm.checkHosts()
    gm.storePrd2Queue()
    gm.installHostAndVM()
    gm.migrateGuest2DestHost(guest_prd=guest_prd)
    #result.append(gm.collectResult(rel))
    LOGGER.debug('-'*15 + 'separator line' + '-'*15)
    #gm.writeLog2File()
    LOGGER.info("Product version [%s] --> [%s] finished" %(prd_list[0], prd_list[1]))
    
    gm.releaseHost()
    return gm.collectResult()


'''
def main():
    """Main function
    """
    
    #Initial environment
    AllStaticFuncs.cleanJosnFIle()
    #Parse commandline parameters
    start_time = datetime.datetime.now()
    param_opt = ParseCMDParam()
    options, _args = param_opt.parse_args()
    #Instance for multiple process
    mpr = MultipleProcessRun(options)
    #Collect all result and generate json file
    tcmap=mpr.getResultMap()
    #Compress result of project
    AllStaticFuncs.compressFile(AllStaticFuncs.getBuildPath())
    
    #Verify project result and mark status
    if mpr.getMulPoolStatus()["status"] is True:
        exit_code = 0
    else:
        LOGGER.warn(mpr.getMulPoolStatus()["info"])
        exit_code = 5
    sys.exit(exit_code)

DEBUG = False

if __name__ == "__main__":
    main()
'''

