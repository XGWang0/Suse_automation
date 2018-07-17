import multiprocessing
import threading
import Queue
import os
import sys
import logging

from jenkins_run_devel_prj3 import *

class MultiThreadHostInstallation(MultiThreadHostInstallation, object):
    '''Install host in parallel
    '''
    def __init__(self, task_q, build_v, test_mod, host_q, sub_test_mode):

        super(MultiThreadHostInstallation, self).__init__(task_q, build_v, test_mod, host_q)

        self.process_name = ''

        self.cmd11 = (self.feed_hamsta + " -x \"ls \" "
                    "-h %(host)s 127.0.0.1 -w")
        
        #self.upd_repo = self._getUpdRepo(self.prd_ver)
        self.sub_test_mode = sub_test_mode

    def _getUpdRepo(self, prd_ver):
        '''Get upgrad repo url for milestone test
        '''
        source_name = "source.virtupdate.milestone.%s" %(prd_ver.lower())
        milestone_root_repo = self.prepareRepos(source_name)

        upd_repo = os.path.join(milestone_root_repo, self.build_ver)
        
        LOGGER.debug("Update repo : %s" %upd_repo)
        return upd_repo

    '''
    def updatePrdRPM(self, phase="Phase0", job_sketch="Upgrade Virt RPM", timeout=3600):
        """Function which update host by hamsta API
        """

        LOGGER.debug("Current update rpm function is updatePrdRPM")
        cmd_update_rpm = (self.feed_hamsta +
                          " -x \"source /usr/share/qa/virtautolib/lib/virtlib;"
                          "update_virt_rpms off on off\""
                          " -h %(host)s 127.0.0.1 -w" %dict(host=self.host))

        if self.status:
            LOGGER.info("Start to upgrade RPM with cmd [%s] %s" %(cmd_update_rpm, self.host))
            self.execHamstaJob(cmd=cmd_update_rpm,
                               timeout=timeout,
                               job_sketch=job_sketch,
                               phase=phase)
        else:
            LOGGER.warn("Last phase failure, skip virt rpm updating.")
    '''

    def updateDailyRPM(self, phase="Phase0", job_sketch="Upgrade Virt RPM", timeout=3600):
        """Function which update host by hamsta API
        """

        upd_repo = self._getUpdRepo(self.prd_ver)
        LOGGER.debug("Current update rpm function is updateDailyRPM")
            #cmd_update_rpm = (self.feed_hamsta + " -x \"ls\" -h %(host)s 127.0.0.1 -w" %dict(host=self.host))
        
        cmd_update_rpm = (self.feed_hamsta + 
                          " -x \"source /usr/share/qa/virtautolib/lib/virtlib;"
                          "update_virt_rpms off on off %(upd_repo)s\""
                          " -h %(host)s 127.0.0.1 -w" %dict(upd_repo=upd_repo,
                                                            host=self.host))    
        if self.status:
            LOGGER.info("Start to upgrade RPM with cmd [%s] %s" %(cmd_update_rpm, self.host))
            self.execHamstaJob(cmd=cmd_update_rpm,
                               timeout=timeout,
                               job_sketch=job_sketch,
                               phase=phase)
        else:
            LOGGER.warn("Last phase failure, skip virt rpm updating.")

    def updateMilesRPM(self, phase="Phase0", job_sketch="Check Virt RPM", timeout=3600):
        """Function which update host by hamsta API
        """
        cmd_update_rpm = (self.feed_hamsta +
                          " -x \"source /usr/share/qa/virtautolib/lib/virtlib;"
                          "update_virt_rpms off on off\""
                          " -h %(host)s 127.0.0.1 -w" %dict(host=self.host))
        
        LOGGER.debug("Current update rpm function is updateDailyRPM")

        if self.status:
            LOGGER.info("Start to check RPM with cmd [%s] %s" %(cmd_update_rpm, self.host))
            self.execHamstaJob(cmd=cmd_update_rpm,
                               timeout=timeout,
                               job_sketch=job_sketch,
                               phase=phase)
        else:
            LOGGER.warn("Last phase failure, skip virt rpm checking.")

    def run(self, status_q, lock, hig_pri_task):

        self.setDefaultGrub(phase="Phase0")
        self.rebootHost(phase="Phase0",job_sketch="Reboot Machine %s To Initialize Status" %(self.host))
        self.installHost(phase="Phase1")
        lock.acquire()
        if self.prd == hig_pri_task and status_q['org_host_task'] is None:   
            update_rpm_func = self.updateMilesRPM
        else:
            if self.sub_test_mode == "milestone":
                update_rpm_func = self.updateMilesRPM
            else:
                update_rpm_func = self.updateDailyRPM
        lock.release()
        
        # UPdate rpm
        update_rpm_func(phase="Phase2", job_sketch="Upgrade Virt RPM For %s On %s" %(self.prd, self.host))

        self.makeEffect2RPM(phase="Phase2.1", job_sketch="Reboot %s To Activate New Virt RPM" %(self.host))

        lock.acquire()
        if self.prd == hig_pri_task and status_q['org_host_task'] is None: # High priority task will be stored in previous position
        #if status_q['org_host_task'] is None:
            self.process_name = 'org_host_task'
            self.storeTaskInstace(status_q, key='org_host_task', value=self)
            LOGGER.info("Org host %s" %self.host)
        else:
            self.process_name = 'dest_host_task'
            self.storeTaskInstace(status_q, key='dest_host_task', value=self)
            LOGGER.info("Dest host %s" %self.host)
        lock.release()

class GuestMigration(GuestMigration, object):

    def __init__(self, prd_list, build_v, test_mod, host_queue, sub_test_mode):

        super(GuestMigration, self).__init__(prd_list, build_v, test_mod, host_queue)
        self.sub_test_mode = sub_test_mode

    def installHostAndVM(self):
        LOGGER.debug("running milestone installHostAndVM")
        if self.status:
            task_lock = threading.Lock()
        
            t1 = threading.Thread(name="thread1",
                                  target=MultiThreadHostInstallation(self.task_q, self.build_v,
                                                          self.test_mod, self.host_q, self.sub_test_mode).run,
                                  args=(self.task_status, task_lock, self.prd_list[0]))
            t2 = threading.Thread(name="thread2",
                                  target=MultiThreadHostInstallation(self.task_q, self.build_v,
                                                          self.test_mod, self.host_q, self.sub_test_mode).run,
                                  args=(self.task_status, task_lock, self.prd_list[0]))
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

    '''
    def migrateGuest2DestHost(self, timeout=86400,
                              guest_prd='SLES-12-SP2-64.XEN->SLES-12-SP2-64.XEN = sles-12-sp2-64'):
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
            LOGGER.info(("Start to migrate guest with cmd[%s] on machine %s"
                         %(cmd_guest_migration, self.task_status['org_host_task'].host)))
            #Install host
            LOGGER.debug("timeout is %d" %timeout)
            
            org_host_self.execHamstaJob(cmd=cmd_guest_migration,
                                        timeout=timeout,
                                        job_sketch=("Migration Test From %(orgprd)s [%(orghost)s] To "
                                                    "%(destprd)s [%(desthost)s]." %dict(orgprd=org_host_self.prd,
                                                                                        orghost=org_host_self.host,
                                                                                        destprd=dest_host_self.prd,
                                                                                        desthost=dest_host_self.host)),
                                        phase="Phase3",
                                        col_tc_rlt=True)
        else:
            LOGGER.warn("Last phase failure, skip guest migration operation")

    '''

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

        feature_desc += "\nTest Type : %s" %'MileStone'
        #feature_desc += "\nVirt Type : %s" %self.virt_type
        feature_desc += '\nOrg_host:%s\nDest_host:%s'%(org_host, dest_host)
        
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
        self.sub_test_mode = options.sub_test_mode

    def _gmMultipleTask(self):
        for test_suite in self.scenarios:
            prd_list = re.split("\s*->\s*",test_suite.strip())
            LOGGER.debug("prd_list is %s" %str(prd_list))
            '''
            migrateGuest(prd_list, self.build_version, self.test_mode,
                         self.queue, self.gm_guest_prd, self.sub_test_mode)
            '''
            self.result.append([prd_list,
                self.pool.apply_async(migrateGuest,
                                      (prd_list, self.build_version, self.test_mode,
                                       self.queue, self.gm_guest_prd, self.sub_test_mode))])

def migrateGuest(prd_list, prd_ver, test_mode, host_queue, guest_prd, sub_test_mode):

    LOGGER.debug("RUnning migrateGuest MIlestone")
    gm = GuestMigration(prd_list, prd_ver, test_mode, host_queue, sub_test_mode)
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


