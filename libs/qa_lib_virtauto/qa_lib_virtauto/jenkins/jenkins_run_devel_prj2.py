#!/usr/bin/python
"""
****************************************************************************
Copyright (c) 2013 Unpublished Work of SUSE. All Rights Reserved.

THIS IS AN UNPUBLISHED WORK OF SUSE.  IT CONTAINS SUSE'S
CONFIDENTIAL, PROPRIETARY, AND TRADE SECRET INFORMATION.  SUSE
RESTRICTS THIS WORK TO SUSE EMPLOYEES WHO NEED THE WORK TO PERFORM
THEIR ASSIGNMENTS AND TO THIRD PARTIES AUTHORIZED BY SUSE IN WRITING.
THIS WORK IS SUBJECT TO U.S. AND INTERNATIONAL COPYRIGHT LAWS AND
TREATIES. IT MAY NOT BE USED, COPIED, DISTRIBUTED, DISCLOSED, ADAPTED,
PERFORMED, DISPLAYED, COLLECTED, COMPILED, OR LINKED WITHOUT SUSE'S
PRIOR WRITTEN CONSENT. USE OR EXPLOITATION OF THIS WORK WITHOUT
AUTHORIZATION COULD SUBJECT THE PERPETRATOR TO CRIMINAL AND  CIVIL
LIABILITY.

SUSE PROVIDES THE WORK 'AS IS,' WITHOUT ANY EXPRESS OR IMPLIED
WARRANTY, INCLUDING WITHOUT THE IMPLIED WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE, AND NON-INFRINGEMENT. SUSE, THE
AUTHORS OF THE WORK, AND THE OWNERS OF COPYRIGHT IN THE WORK ARE NOT
LIABLE FOR ANY CLAIM, DAMAGES, OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT, OR OTHERWISE, ARISING FROM, OUT OF, OR IN CONNECTION
WITH THE WORK OR THE USE OR OTHER DEALINGS IN THE WORK.
****************************************************************************

Tool Brief:
  Description: Automatically distribute tasks into available host 
               and run virtualization relevant test.
  Function & Scope:
               Tool supports below projects:
                 1. Host migration test
                    Target : Host Upgrade Virtualization mainly verifies and compares the 
                             virtualization administration result before and after upgrading 
                             a virtual host from LOW VERSION PRODUCT to HIGH VERSION PRODUCT, 
                             to ensure that the virtual guests created on a base product are 
                             highly managable when the virtual host upgradse to a higher version product.
                    (Support xen & kvm type virtualization)
                Test Type : Devel Test
                            The test forces on development repo and verifies the latest virt product
                 Note: Script combines with jenkins
"""

from jenkins_run_devel_prj1 import * 

class HostMigration(GuestInstalling, object):
    '''The class is only for host migration test
    '''
    def __init__(self, org_prd, dest_prd, param, queue):
        '''Initial function and variables, inherit GuestInstalling class
        '''
        self.build_ver = param[0]
        super(HostMigration, self).__init__(org_prd, param[0], param[1], queue)
        
        self.full_dest_prd = dest_prd.strip()
        self.dest_prd, self.dest_virt_type = self.full_dest_prd.strip().split(".")

        # Get guest regular expression
        self.hu_g_product = param[2]
        self.cmd_test_run =  ""

    def generateTestRun(self, phase="phase2", timeout=1800):
        """Function which update host by hamsta API
        """
        def _get_test_run(result, keyword="Generated test run file:"):
                se_ins = re.search("%s\s*(\S+)" %(keyword), result, re.I)
                if se_ins:
                    return se_ins.groups()[0].strip()
                else:
                    return ""

        if self.status:
            # Get guest regular expression pattern
            guest_prd = self.getGuestFilter()
            cmd_generate_tr = (self.feed_hamsta +  " -x "
                   "\"/usr/share/qa/tools/_generate_vh-update_tests.sh "
                   "-m %(virt_std)s -v %(virt_type)s -b %(org_prd)s -u %(dest_prd)s -i \'%(guest_prd)s\' \" "
                   "-h %(host)s 127.0.0.1 -w" %dict(host=self.host,
                                                    virt_std=self.test_mode,
                                                    virt_type=self.virt_type.lower(),
                                                    org_prd=self.prd_ver.lower().replace("-64",""),
                                                    dest_prd=self.dest_prd.lower().replace("-64",""),
                                                    guest_prd=guest_prd))
            LOGGER.info(("Start to generate test run script with cmd [%s] on %s"
                         %(cmd_generate_tr, self.host)))
            self.execHamstaJob(cmd=cmd_generate_tr,
                               timeout=timeout,
                               job_sketch="Generate Test-Run Script",
                               phase=phase)

            if self.status:
                job_result = self.result[-1]["scenario_alloutput"]
                cmd_test_run = _get_test_run(job_result)
                if cmd_test_run:
                    self.cmd_test_run = (self.feed_hamsta +
                                         " -x \"" + cmd_test_run + " %(step)s\"" 
                                         " -h %(host)s 127.0.0.1 -w ")
                else:
                    self.status = False
            else:
                pass
        else:
            LOGGER.warn("Last phase failure, skip generation test run script.")


    def updateRPM(self, phase="Phase0", job_sketch="Upgrade Virt RPM", timeout=3600):
        """Function which update host by hamsta API
        """
        if self.status:

            cmd_update_rpm = self.cmd_test_run  %dict(step="01",
                                                      host=self.host)
            LOGGER.info("Start to upgrade RPM with cmd [%s] %s" %(cmd_update_rpm, self.host))
            self.execHamstaJob(cmd=cmd_update_rpm,
                               timeout=timeout,
                               job_sketch=job_sketch,
                               phase=phase)
            
            #self.rebootHost(phase=phase, job_sketch="Recover Machine Status", chk_postive_status=False)
        else:
            LOGGER.warn("Last phase failure, skip rpm updating.")

    def updateHost(self, phase="Phase0", timeout=172800):
        """Function which update host by hamsta API
        """
        if self.status:

            cmd_update_host = self.cmd_test_run %dict(step="02",
                                                      host=self.host)

            '''
            cmd11 = (self.feed_hamsta + " -x \"ls \" "
                          "-h %(host)s 127.0.0.1 -w")
            cmd_update_host = cmd11 %dict(host=self.host)
            '''

            LOGGER.info("Start to upgrade host with cmd [%s] %s" %(cmd_update_host, self.host))
            self.execHamstaJob(cmd=cmd_update_host,
                               timeout=timeout,
                               job_sketch="Administration And Upgrade To %s" %(self.full_dest_prd),
                               phase=phase)
        else:
            LOGGER.warn("Last phase failure, skip host updating.")

    def verifyGuest(self, timeout=10000):
        """Function which verifys result of host migration.
        Thru invoking hamsta cmd to do this operation.
        """
        if self.status:

            cmd_verify_guest = self.cmd_test_run %dict(step="03",
                                                       host=self.host)

            LOGGER.info("Start to verify host with cmd [%s] %s" %(cmd_verify_guest, self.host))

            self.execHamstaJob(cmd=cmd_verify_guest,
                                timeout=timeout,
                                job_sketch="Upgrade Verification",
                                phase="Phase7",
                                doc_str_flag=True)
        else:
            LOGGER.warn("Last phase failure, skip upgrade verfication.")

    def getDateTimeDelta(self, beg_time, end_time):
        '''Calculate difftime.
        '''
        beg_date_time_tuple = time.mktime(datetime.datetime.timetuple(beg_time))
        end_date_time_tuple = time.mktime(datetime.datetime.timetuple(end_time))
        
        return abs(int(end_date_time_tuple - beg_date_time_tuple))

    def assembleResult(self):
        '''Generate new data structure.
        
        Format Sample:
            {'feature_desc': 'desc',
              'feature_host': '147.2.207.27',
              'feature_prj_name': 'SLES-11-SP4-64.KVM',
              'feature_prefix_name': 'Virt Install - host '
              'scenario_info': [                
                                    {'doc_str_flag': False,
                                      'end_time': datetime.datetime(2015, 5, 6, 7, 55, 11, 871674),
                                      'hamsta_output': 'hamsta_out',
                                      'hamsta_status': 0,
                                      'scenario_alloutput': 'scenario_output',
                                      'scenario_name': 'Install host',
                                      'scenario_qadb_url': '',
                                      'scenario_status': 0,
                                      'start_time': datetime.datetime(2015, 5, 6, 7, 55, 11, 863720),
                                      'step_info': [{'step_name':'sles-11-sp2-64-fv-def-net',
                                                     'step_status':'PASSED',
                                                     'step_duration':100,
                                                     'step_stdout':"",
                                                     'step_errout':""}
                                                    ],
                                    }
                                ]
            }
        '''

        prefix_name="Host-Upgrade "

        feature_desc=("Target : Host Upgrade Virtualization mainly verifies and compares the "
                      "virtualization administration result before and after upgrading "
                      "a virtual host from LOW VERSION PRODUCT to HIGH VERSION PRODUCT, "
                      "to ensure that the virtual guests created on a base product are "
                      "highly managable when the virtual host upgradse to a higher version product."
                      "         (Support xen & kvm type virtualization)\n")

        org_prd_chg_rpms = self.getChgRPMs(self.prd)
        upg_prd_chg_rpms = self.getChgRPMs(self.dest_prd)

        feature_desc += "\nTest Type : %s" %'Devel/Unit Test'
        feature_desc += "\nVirt Type : %s" %self.virt_type
        feature_desc += "\nHost      : %s" %self.host
        feature_desc += "\n%s" %org_prd_chg_rpms
        feature_desc += "\n%s" %upg_prd_chg_rpms

        tmp_job_map = {}
        tmp_job_map["feature_prefix_name"] = prefix_name
        tmp_job_map["feature_host"] = self.host
        tmp_job_map["feature_prj_name"] = "%s -> %s" %(self.prd, self.full_dest_prd)
        tmp_job_map["scenario_info"] = self.result
        tmp_job_map["feature_desc"] = feature_desc
        tmp_job_map["feature_status"] =  self.status

        return tmp_job_map

    '''
    def updateRPMFromMilestone(self, phase="Phase0", timeout=36000):
        """Function which update host from milestone repo
        """
        if self.test_mode == "std":
            if self.status:
                if self.upd_desthost_repo:
                    cmd_update_rpm = self.cmd_test_run  %dict(step="03",
                                                              host=self.host)
                    if DEBUG:
                        cmd_update_rpm = "/tmp/test.sh rpm"
                    LOGGER.info("Start to upgrade RPM from Milesteon Build with cmd [%s] %s" %(cmd_update_rpm, self.host))
                    self.execHamstaJob(cmd=cmd_update_rpm,
                                       timeout=timeout,
                                       job_sketch="Upgrade RPM From Milestone build",
                                       phase=phase)
                    
                    #self.rebootHost(phase=phase, job_sketch="Recover Machine Status", chk_postive_status=False)
                    self.makeEffect2HostUpgrade(phase="Phase9")
                else:
                    LOGGER.info("Update RPM from default source.")
            else:
                LOGGER.warn("Last phase failure, skip milestone rpm updating.")
        else:
            LOGGER.info("Test mode is dev, skip milestone rpm upgrade")
    '''
    def makeEffect2HostUpgrade(self, phase="Phase0", flag=True):
        if self.status:
            # Only upgraded product is sle-12 or up version needs to be switched kernel
            #if 'SLES-12' in self.dest_prd and self.virt_type == "XEN":
            if self.virt_type == "XEN":
                self.switchXenKernel()
            else:
                pass
        else:
            pass

    def makeEffect2RPM(self, phase="Phase0", prd_ver="", job_sketch="Reboot To Activate New Virt RPM"):

        if not prd_ver:
            prd_ver = self.prd_ver

        if self.status:
            # Only "SLES-12" product needs to switch kernel again after updating rpm
            #if 'SLES-12' in prd_ver and self.virt_type == "XEN":
            if self.virt_type == "XEN":
                #Switch xen kernel
                self.switchXenKernel(phase=phase)
            else:
                self.rebootHost(phase=phase, job_sketch=job_sketch, timeout=3600)
        else:
            LOGGER.warn("Last phase failure, skip reboot or switch xen kernel step.") 


    def getGuestFilter(self):
        ''' Get specify guest product versions
        '''
        all_prd_filter_list = self.hu_g_product.split(",")
        for prd_guest_filter in all_prd_filter_list:
            if re.search("%s.*?%s\s*?=\s*?" %(self.prd, self.full_dest_prd), prd_guest_filter, re.I):
                prd_filter = re.sub("%s.*?%s\s*?=\s*" %(self.prd, self.full_dest_prd), "", prd_guest_filter).strip()
                if prd_filter:
                    return prd_filter.replace("|", ",")
                else:
                    break
        
        return "sles-11,sles-12,sled-11,sled-12"


def migrateHost(org_prd, dest_prd, param, queue=None,):
    """Externel function, only for warp migration host function
    """
    def _migrateHostDevel(hm_inst):
        if hm_inst.status:

            # Prepare test machine environment
            hm_inst.setDefaultGrub(phase="Phase0")
            hm_inst.rebootHost(phase="Phase1", job_sketch="Reboot For Initial Status")

            # Install host with base product
            hm_inst.installHost(phase="Phase2")

            # Generate test run script
            hm_inst.generateTestRun(phase="Phase3")

            # Update virt rpm on base product
            hm_inst.updateRPM(phase="Phase4", job_sketch="Upgrade Virt RPM For %s" %hm_inst.prd)
            hm_inst.makeEffect2RPM(phase="Phase5")

            #Update base product to higher product
            hm_inst.updateHost(phase="Phase6")
            hm_inst.rebootHost(phase="Phase7", timeout=5400,
                               job_sketch="Reboot to upgraded %s.%s" %(hm_inst.dest_prd, hm_inst.virt_type))
            hm_inst.makeEffect2HostUpgrade(phase="Phase7", flag=False)
            
            # Update virt rpm on upgraded product
            hm_inst.updateRPM(phase="Phase4",
                              job_sketch="Upgrade Virt RPM For %s.%s" %(hm_inst.dest_prd,
                                                                        hm_inst.virt_type))
            hm_inst.makeEffect2RPM(phase="Phase5", prd_ver=hm_inst.dest_prd,
                                   job_sketch="Reboot To Activate New Virt RPM For %s.%s" %(hm_inst.dest_prd,
                                                                                            hm_inst.virt_type)) 
            # Verification Result
            hm_inst.verifyGuest()

            hm_inst.releaseHost()

    vir_opt = HostMigration(org_prd, dest_prd, param, queue)
    LOGGER.info("Host Migration Devel Test from [%s] to [%s] starts to run on host [%s] now" %(org_prd,
                                                                                                   dest_prd,
                                                                                                   vir_opt.host))

    _migrateHostDevel(vir_opt)

    vir_opt.writeLog2File()
    LOGGER.info("Host Migration Devel Test from [%s] to [%s] finished" %(org_prd, dest_prd))
    
    return vir_opt.assembleResult()

class MultipleProcessRun(MultipleProcessRun, object):
    """Class which supports multiple process running for virtualization
    """

    def __init__(self, options):
        """Initial process pool, valiables and constant values 
        """
        super(MultipleProcessRun, self).__init__(options)

    def startRun(self):
        self.host_list = AllStaticFuncs.getAvailHost(self.options.hu_host_list.split(","))
        self.scenarios = self.options.hu_scenarios.strip().split(",")
        #self.org_prd_list = self.options.org_product_list.strip().split(",")
        #self.upg_prd_list = self.options.upg_product_list.strip().split(",")

        self.hu_g_product = self.options.hu_g_product_list.strip()
        self.param = (self.build_version, self.test_mode, self.hu_g_product)


        #Pool size is defined through host number.
        if self.host_list:
            self.pool = multiprocessing.Pool(processes=len(self.host_list))
            LOGGER.debug("Create process pool[%d]" %len(self.host_list))
            self.initialQueue()
            self._huMultipleTask()
            self.closeAndJoinPool()
        else:
            self.prj_status["status"]= False
            self.createFileFlag()
            self.prj_status["info"] = "There is no available host"

    def _huMultipleTask(self):
        """Execute multiple taskes in processes pool only for guest installing
        """
        for test_suite in self.scenarios:
            ord_prd, upg_prd = re.split("\s*->\s*",test_suite.strip())

            #migrateHost(ord_prd, upg_prd, self.param, self.queue)

            self.result.append([ord_prd + '-' + upg_prd,
                                self.pool.apply_async(migrateHost,
                                    (ord_prd, upg_prd, self.param, self.queue))])

DEBUG = False

#LOGGER = LoggerHandling(os.path.join(AllStaticFuncs.getBuildPath(), "sys.log"), logging.DEBUG)
