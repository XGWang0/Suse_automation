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
               and run virtualization relevant test. This script supports daily test and milestone test.
  Function & Scope:
               Tool supports below projects:
                 1. Guest installation test
                    The main target is that verifies guest installation result on special prodcut version.
                
                Test Type : Milestone Test
                            The test forces on sles milestone product and verifies virt tool on the latest sles product
                 Note: This Script needs to combine with jenkins to run
"""

from jenkins_run_devel_prj1 import * 

class GuestInstalling(GuestInstalling, object):
    '''Class representing virt-install test runner
    '''

    def __init__(self, prd, buildver, testmode, queue):
        '''Initial variable and constant value
        '''
        super(GuestInstalling, self).__init__(prd, buildver, testmode, queue)
        self.upd_repo = ""

    def getRepoChgVer(self, prd, build_info):
        '''Get change version of repo
        '''
        if self.test_mode == "std":
            return build_info
        else:
            prd_ver = prd.strip().split(".")[0]
            return ''.join(re.findall("%s-devel.*?;|%s-test.*?;" %(prd_ver,prd_ver),
                                      build_info, re.I))

    def makeEffect2RPM(self, phase="Phase0", job_sketch="Reboot To Activate New Virt RPM"):


        if self.status:
            # Only "SLES-12" product needs to switch kernel again after updating rpm
            #if 'SLES-12' in self.prd_ver and self.virt_type == "XEN":
            if self.virt_type == "XEN":
                #Switch xen kernel
                self.switchXenKernel(phase=phase)
            else:
                self.rebootHost(phase=phase, job_sketch=job_sketch, timeout=3600)
        else:
            return

    def updateRPM(self, phase="Phase0", job_sketch="Upgrade Virt RPM", timeout=3600):
        """Function which update host by hamsta API
        """

        cmd_update_rpm = (self.feed_hamsta + 
                          " -x \"source /usr/share/qa/virtautolib/lib/virtlib;"
                          "update_virt_rpms off on off %(upd_repo)s\""
                          " -h %(host)s 127.0.0.1 -w" %dict(upd_repo=self.upd_repo,
                                                            host=self.host))
            #return 

        if self.status:
            LOGGER.info("Start to upgrade RPM with cmd [%s] %s" %(cmd_update_rpm, self.host))
            self.execHamstaJob(cmd=cmd_update_rpm,
                               timeout=timeout,
                               job_sketch=job_sketch,
                               phase=phase)
        else:
            LOGGER.warn("Last phase failure, skip virt rpm updating.")            


    def checkRPM(self, phase="Phase0", job_sketch="Check Virt RPM", timeout=3600):
        '''Check all rpm is existent on host
        '''
        
        cmd_update_rpm = (self.feed_hamsta +
                          " -x \"source /usr/share/qa/virtautolib/lib/virtlib;"
                          "update_virt_rpms off on off\""
                          " -h %(host)s 127.0.0.1 -w" %dict(host=self.host))
        
        if self.status:
            LOGGER.info("Start to Check RPM with cmd [%s] %s" %(cmd_update_rpm, self.host))
            self.execHamstaJob(cmd=cmd_update_rpm,
                               timeout=timeout,
                               job_sketch=job_sketch,
                               phase=phase)
        else:
            LOGGER.warn("Last phase failure, skip virt rpm checking.")    

    def _getUpdRepo(self):
        '''Get upgrad repo url for milestone test
        '''
        source_name = "source.virtupdate.milestone.%s" %(self.prd_ver.lower())
        milestone_root_repo = self.prepareRepos(source_name)

        self.upd_repo = os.path.join(milestone_root_repo, self.build_ver)
        LOGGER.debug("Update repo : %s" %self.upd_repo)

    def assembleResult(self, prefix_name="Virt Install -  ",
                       feature_desc="Description of Feature"):
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

        repo_chg_ver = self.getRepoChgVer(self.prd, self.test_mode)

        feature_desc = ("Target : Guest Installation mainly verifies "
                        "different kind PRODUCT VERSION of virtual-manchine installation "
                        "result on HOST with special version prodcut."
                        "         (Support xen & kvm type virtualization)\n")

        feature_desc += "\nTest Type : %s" %"MileStone Test"
        feature_desc += "\nVirt Type : %s" %self.virt_type
        feature_desc += "\nHost      : %s" %self.host

        tmp_job_map = {}
        tmp_job_map["feature_prefix_name"] = prefix_name
        tmp_job_map["feature_host"] = self.host
        tmp_job_map["feature_prj_name"] = self.prd
        tmp_job_map["scenario_info"] = self.result
        tmp_job_map["feature_desc"] = feature_desc
        tmp_job_map["feature_status"] =  self.status

        return tmp_job_map

def installGuest(prd, param, queue=None):
    """External function to warp gest installing functions
    """
    
    def _installGuestDailyT(gi_inst):
        if gi_inst.status:
            # Prepare test machine running environment
            gi_inst.setDefaultGrub(phase="Phase1")
            gi_inst.rebootHost(phase="Phase2", job_sketch="Reboot For Initializing Status")

            # Install test machine
            gi_inst.installHost(phase="Phase3")

            gi_inst._getUpdRepo()
            # Update virt rpm on test machine
            gi_inst.updateRPM(phase="Phase4", job_sketch="Upgrade Virt RPM For %s" %gi_inst.prd)
            gi_inst.makeEffect2RPM(phase="Phase4.1")
            
            # Extend a enteral script
            gi_inst.impExteralScript('Virt_jenkins_cmd_hook')

            # Get guest filter
            prd_filter = gi_inst.getGuestFilter(param[0])
            # Execute test case of guest installation
            gi_inst.installVMGuest(filter=param[0], process_num=param[1])

            gi_inst.releaseHost()

    def _installGuestMileS(gi_inst):
        if gi_inst.status:
            # Prepare test machine running environment
            gi_inst.setDefaultGrub(phase="Phase1")
            gi_inst.rebootHost(phase="Phase2", job_sketch="Reboot For Initializing Status")

            # Install test machine
            gi_inst.installHost(phase="Phase3")
            
            gi_inst.checkRPM(phase="Phase4", job_sketch="Check Virt RPM For %s" %gi_inst.prd)
            
            gi_inst.makeEffect2RPM(phase="Phase4.1")
            # Extend a enteral script
            gi_inst.impExteralScript('Virt_jenkins_cmd_hook')

            prd_filter = gi_inst.getGuestFilter(param[0])
            # Execute test case of guest installation
            #gi_inst.installVMGuest(filter=param[0], process_num=param[1])
            gi_inst.installVMGuest(filter=prd_filter, process_num=param[1])

            gi_inst.releaseHost()

    vir_opt = GuestInstalling(prd, param[2], param[3], queue)
    LOGGER.info("Guest Installation Milestone test on product version [%s] on host [%s] starts to run" %(prd, vir_opt.host))

    if param[4] == 'milestone':
        _installGuestMileS(vir_opt)
    else:
        _installGuestDailyT(vir_opt)

    vir_opt.writeLog2File()
    LOGGER.info("Guest Installation Milestone test on product version [%s] on host [%s] finished" %(prd, vir_opt.host))

    return vir_opt.assembleResult()

class MultipleProcessRun(MultipleProcessRun, object):
    """Class which supports multiple process running for virtualization
    """

    def __init__(self, options):
        super(MultipleProcessRun, self).__init__(options)
        self.sub_test_mode = options.sub_test_mode.strip()
        self.param.append(self.sub_test_mode)

    def _giMultipleTask(self):
        """Execute multiple taskes in processes pool only for guest installing
        """
        for task in self.task_list:
            #installGuest(task, self.param,self.queue)

            self.result.append([task,
                                self.pool.apply_async(
                                    installGuest,
                                    (task, self.param, self.queue)
                                    )])

