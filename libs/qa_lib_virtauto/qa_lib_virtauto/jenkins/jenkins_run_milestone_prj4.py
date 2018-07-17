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
                 1. Guest upgrade test
                    Target : Guest Upgrade Virtualization mainly verifies and compares the 
                             virtualization administration result before and after upgrading 
                             a virtual guest from LOW VERSION PRODUCT to HIGH VERSION PRODUCT, 
                             to ensure that the virtual guests still can run normally.
                    (Support xen & kvm type virtualization)
                Test Type : Milestone Test
                            The test forces on sles milestone product and verifies virt tool on the latest sles product
                 Note: This Script needs to combine with jenkins to run
"""

from jenkins_run_milestone_prj1 import * 

class GuestUpgrade(GuestInstalling, object):
    '''The class is only for host migration test
    '''
    def __init__(self, prd, buildver, testmode, queue, upg_ver='sles-12-sp2-64'):
        '''Initial function and variables, inherit GuestInstalling class
        '''
        super(GuestInstalling, self).__init__(prd, buildver, testmode, queue)
        self.upg_ver = upg_ver

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
     
             Guest Name          --- Result ---  Reason  
              sles-11-sp4-64-fv-def-net  ---  Fail  ---  Administration before guest upgrade fail.
              sles-11-sp4-64-fv-def-net  ---  Fail  ---  Guest upgrade without reboot fail.
              sles-11-sp4-64-fv-def-net  ---  Fail  ---  Send reboot command after guest upgrade fail.
              sles-11-sp4-64-fv-def-net  ---  Fail  ---  Reboot after guest upgrade fail.
              sles-11-sp4-64-fv-def-net  ---  Fail  ---  Incorrect SuSe-release after guest upgrade.
              sles-11-sp4-64-fv-def-net  ---  Fail  ---  Administration after guest upgrade fail.
              sles-11-sp4-64-fv-def-net  ---  Pass
              sles-12-sp1-64-fv-def-net  ---  Fail  ---  Administration before guest upgrade fail.
              sles-12-sp1-64-fv-def-net  ---  Fail  ---  Administration after guest upgrade fail.
              sles-12-sp1-64-fv-def-net  ---  Pass
            Test done
          
          Result:
          [{'step_name':'sles-11-sp2-64-fv-def-net',
            'step_status':'PASSED',
            'step_duration':1000,
            'step_stdout':'',
            'step_errout':''},
            {...},....]
        '''

        # Directly fetch test result from test machine
        get_rlt_cmd = self.feed_hamsta + (' -x \''
                                      '<![CDATA[result=`find /var/log/qa/oldlogs/'
                                      ' -mindepth 3 -iname "guest_upgrade_*" | tail -1 `;'
                                      ' if [[ -f $result && -n "$result" ]];then cat $result; fi ]]>\'' 
                                      ' -h %s 127.0.0.1 -w') %self.host

        (rd, ho, st, et) = runCMDNonBlocked(get_rlt_cmd, timeout=300)
        test_result = self.parseOutput(ho)
        LOGGER.debug("Test result is ----- %s" %test_result)

        #LOGGER.debug("Current function in prj4")
        tmp_allcase_result = []
        testcase_info_list = []

        case_cont_compile = re.compile("Guest Name\s*--+ Result\s*--+\s*Reason(.*)Test done", re.DOTALL)
        case_result = re.search(case_cont_compile, test_result)
    
        if case_result:
            testcase_info_list = case_result.groups()[0].strip().split(os.linesep)
            result_reason = ""
        for testcase in testcase_info_list:
            LOGGER.debug('Result line is %s' %testcase)
            if re.search("pass", testcase, re.I):
                case_name,case_status = re.split("\s*--+\s*", testcase)
            elif re.search("fail|skip", testcase, re.I):
                case_name,case_status,result_reason = re.split("\s*--+\s*", testcase)
            else:
                continue

            case_name = re.sub(".*%s" %prefix_tc_cont, repl="", string=case_name).strip()
            tmp_case_map = {}
            tmp_case_map["step_name"] = case_name + ' upgrade to %s' % self.upg_ver
            if re.search('pass', case_status, re.I):
                tmp_case_map["step_status"] = 'passed'
            elif re.search('skip', case_status, re.I):
                tmp_case_map["step_status"] = 'skipped'
            else:
                tmp_case_map["step_status"] = 'failed'
        
            tmp_case_map["step_duration"] = 0
            tmp_case_map["step_stdout"] = result_reason
            tmp_case_map["step_errout"] = result_reason
            LOGGER.debug('getSubCaseData case map %s' %str(tmp_case_map))
            tmp_allcase_result.append(tmp_case_map)
     
        return tmp_allcase_result

    def getGuestFilter(self, guest_filter):
        ''' Get specify guest product versions
        '''
        all_prd_filter_list = guest_filter.split(",")
        for prd_guest_filter in all_prd_filter_list:
            if self.prd in prd_guest_filter:
                prd_filter = re.sub("%s\s*=\s*" %self.prd, "", prd_guest_filter).strip()
                if prd_filter:
                    return prd_filter.replace("|", ",")
                else:
                    break
        
        return "sles-11,sles-12,sled-11,sled-12"

    def upgradeVM(self, guestfilter, timeout=36000):
        """Function which update host by hamsta API
        """
        if self.status:
            # Get guest regular expression pattern
            
            source_name = "source.%s.%s"%(self.repo_type, self.upg_ver.lower())
            source_repo = self.prepareRepos(source_name)
    
            cmd_upgrade_guest = (self.feed_hamsta +  " -x "
                           "\"/usr/share/qa/tools/test_virtualization-guest-upgrade-run "
                           "-p %(upg_ver)s -r %(upg_repo)s -g \'%(guest_prd)s\' -t %(timeout)s\" "
                           "-h %(host)s 127.0.0.1 -w" %dict(host=self.host,
                                                            upg_ver=self.upg_ver.lower(),
                                                            upg_repo=source_repo,
                                                            guest_prd=guestfilter,
                                                            timeout=timeout))
            LOGGER.info(("Start to install guest with cmd[%s] on host %s"
                         %(cmd_upgrade_guest, self.host)))
            '''
            cmd_upgrade_guest = (self.feed_hamsta +  " -x "
                           "/tmp/test.sh"
                           " -h %(host)s 127.0.0.1 -w" %dict(host=self.host))
            '''
            self.execHamstaJob(cmd=cmd_upgrade_guest,
                               timeout=timeout,
                               job_sketch="Guest Upgrade Verfication",
                               phase="Phase3",
                               col_tc_rlt=True)
        else:
            LOGGER.warn("Last phase is failed, skip Guest Upgrade Verfication")

def upgradeGuest(prd, param, queue=None):
    """Externel function, only for warp migration host function
    """
    def _upgradeGuestDaily(gu_inst):
        LOGGER.info("Milestone daily test on prj4 is enable")
            
    def _upgradeGuestMiles(gu_inst):
        if gu_inst.status:

            # Prepare test machine environment
            gu_inst.setDefaultGrub(phase="Phase0")
            gu_inst.rebootHost(phase="Phase1", job_sketch="Reboot For Initial Status")

            # Install host with base product
            gu_inst.installHost(phase="Phase2")

            gu_inst.checkRPM(phase="Phase4", job_sketch="Check Virt RPM For %s" %gu_inst.prd)
            
            gu_inst.makeEffect2RPM(phase="Phase4.1")
            # Extend a enteral script
            gu_inst.impExteralScript('Virt_jenkins_cmd_hook')

            prd_filter = gu_inst.getGuestFilter(param[0])
            # Execute test case of guest installation
            gu_inst.upgradeVM(guestfilter=prd_filter)

            gu_inst.releaseHost()

    vir_opt = GuestUpgrade(prd, param[2], param[3], queue, upg_ver=param[5])
    LOGGER.info("Guest Installation Milestone test on product version [%s] on host [%s] starts to run" %(prd, vir_opt.host))

    if param[4] == 'milestone':
        _upgradeGuestMiles(vir_opt)
    else:
        _upgradeGuestDaily(vir_opt)

    vir_opt.writeLog2File()
    LOGGER.info("Guest Installation Milestone test on product version [%s] on host [%s] finished" %(prd, vir_opt.host))

    feature_desc = ("Target : Guest Upgrade Virtualization mainly verifies and compares the "
                    "virtualization administration result before and after upgrading "
                    "a virtual guest from LOW VERSION PRODUCT to HIGH VERSION PRODUCT," 
                    " to ensure that the virtual guests still can run normally."
                    "(Support xen & kvm type virtualization)\n")

    return vir_opt.assembleResult(prefix_name="Guest Upgrade -  ", feature_desc=feature_desc)

class MultipleProcessRun(MultipleProcessRun, object):
    """Class which supports multiple process running for virtualization
    """

    def __init__(self, options):
        super(MultipleProcessRun, self).__init__(options)
        self.guest_upgraded_ver = options.gu_guest_upg_prd.strip()
        self.param.append(self.guest_upgraded_ver)

    def startRun(self):
        self.host_list = AllStaticFuncs.getAvailHost(self.options.gu_host_list.split(","))
        self.task_list = self.options.gu_h_product_list.strip().split(",")

        #Pool size is defined through host number.
        if self.host_list:
            self.pool = multiprocessing.Pool(processes=len(self.host_list))
            LOGGER.debug("Create process pool[%d]" %len(self.host_list))
            self.initialQueue()
            self._guMultipleTask()
            self.closeAndJoinPool()
        else:
            self.prj_status["status"]= False
            self.createFileFlag()
            self.prj_status["info"] = "There is no available host"

    def _guMultipleTask(self):
        """Execute multiple taskes in processes pool only for guest installing
        """
        for task in self.task_list:
            #upgradeGuest(task, self.param,self.queue)

            self.result.append([task,
                                self.pool.apply_async(
                                    upgradeGuest,
                                    (task, self.param, self.queue)
                                    )])

DEBUG = False

#LOGGER = LoggerHandling(os.path.join(AllStaticFuncs.getBuildPath(), "sys.log"), logging.DEBUG)
