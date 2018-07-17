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
                 1. Guest installation test
                 2. Host migration test
                 3. Guest migration test (in processing)
                 Note: Script combines with jenkins
"""
import datetime
import optparse
import sys


class ParseCMDParam(optparse.OptionParser,object):
    """Class which parses command parameters
    """

    def __init__(self):
        optparse.OptionParser.__init__(
            self, 
            usage='Usage: %prog [options]',
            epilog="NOTE: These parameters supports all projects.")

        self.add_option("-t", "--test-type", action="store", type="string",
                        dest="test_type",
                        help=("Set test type, gi|hu|gm is available"
                              "\ngi represents Prj1 Guest Installation"
                              "\nhu represents Prj2 Host Upgrade"
                              "\ngm represetns Prj3 Guest Migration"))
        '''
        self.add_option("-r", "--repository", action="store", type="string",
                        dest="repo",
                        help=("Set path of repositroy for installing virtualization"))
        '''
        self.add_option("--virt-product-ver", action="store", type="string",
                        dest="product_ver",
                        help=("Product or repository version info"
                              "Usually, this parameter setting by automatic triggering as version info"
                              "displays in report"))
        self.add_option("--tst_mode", action="store", type="string",
                        dest="test_mode",# choices=['std','dev'],
                        help=("[std/dev], std means that using standard repo's package to execute test"
                              "dev means that using developer repo's package to run"))

        #Guest installing test parameters 
        group = optparse.OptionGroup(
            self,
            "Prj1:Guest Installing",
            "Execute test of guest installing on virtualization")

        self.add_option_group(group)
        group.add_option("--gi-host", action="store", type="string",
                        dest="gi_host_list",
                        help=("Input test machine[s] ip address or domain name which shows in hamsta server."
                              "Multiple ip address means that running test in parallel, "
                              "parallel number is count of machines"))
        group.add_option("--host-product", action="store", type="string",
                        dest="gi_h_product_list",
                        help=("Input product version of host, supporting product : \"SLES-11-SP4-64.XEN"
                              "SLES-11-SP4-64.KVM SLES-12-SP0-64.XEN SLES-12-SP0-64.KVM SLES-12-SP1-64.XEN"
                              "SLES-12-SP1-64.KVM\", using comma as separator"))
        group.add_option("--guest-product", action="store", type="string",
                        dest="gi_g_product_list",
                        help=("Guest product version as OS of vitual machine were installed on host machine."
                              "Product scope:\"nw-65,oes-11,oes-2,rhel-3,rhel-4,rhel-5,rhel-6,rhel-7,sled-10,"
                              "sled-11,sled-12,sles-10,sles-11,sles-12,sles-9,win-2k,win-2k12,win-2k12r2,"
                              "win-2k3,win-2k8,win-2k8r2,win-7,win-8,win-8.1,win-vista,win-xp\","
                              "Using comma as separator"))
        group.add_option("--guest-parallel-num", action="store", type="string",
                        dest="gi_g_concurrent_num",
                        help=("It means that multiple vitual machines were installed in parallel on host "))
        '''
        group.add_option("--virt-product-ver", action="store", type="string",
                        dest="gi_g_product_ver",
                        help=("Specify product build version"))
        '''
        #Host upgrade and vm-guest verfication test parameters
        group = optparse.OptionGroup(
            self,
            "Prj2:Host Upgrade",
            "Execute test for host upgrade and vm-guest verfication on virtualization")

        self.add_option_group(group)
        group.add_option("--hu-host", action="store", type="string",
                        dest="hu_host_list",
                        help=("Input test machine[s] ip address or domain name which shows in hamsta server."
                              "Multiple ip address means that running test in parallel, "
                              "parallel number is count of machines"))
        group.add_option("--hu-scenarios", action="store", type="string",
                        dest="hu_scenarios",
                        help=("All scenarios for host updating test"))
        group.add_option("--hu-guest-product", action="store", type="string",
                        dest="hu_g_product_list",
                        help=("Guest product version as OS of vitual machine were installed on host machine."
                              "Product scope:\"nw-65,oes-11,oes-2,rhel-3,rhel-4,rhel-5,rhel-6,rhel-7,sled-10,"
                              "sled-11,sled-12,sles-10,sles-11,sles-12,sles-9,win-2k,win-2k12,win-2k12r2,"
                              "win-2k3,win-2k8,win-2k8r2,win-7,win-8,win-8.1,win-vista,win-xp\","
                              "Using comma as separator"))

        #Host upgrade and vm-guest verfication test parameters
        group = optparse.OptionGroup(
            self,
            "Prj3:Guest Migration",
            "This tool is only for testing guest migration feature")
    
        self.add_option_group(group)
        group.add_option("--gm-host", action="store", type="string",
                        dest="gm_host_list",
                        help=("Input test machine[s] ip address or domain name which shows in hamsta server."
                              "Multiple ip address means that running test in parallel, "
                              "parallel number is count of machines"))
        group.add_option("--gm-scenarios", action="store", type="string",
                        dest="gm_scenarios",
                        help=("All scenarios for host updating test"))
        group.add_option("--gm-guest-product", action="store", type="string",
                        dest="gm_guest_prd",
                        help=("Destination host product version"))

def main():
    """Main function
    """

    #Parse commandline parameters
    start_time = datetime.datetime.now()
    param_opt = ParseCMDParam()
    options, _args = param_opt.parse_args()
    if options.test_type == "gi":
        import jenkins_run_devel_prj1 as jr
    elif options.test_type == "hu":
        import jenkins_run_devel_prj2 as jr
    elif options.test_type == "gm":
        import jenkins_run_devel_prj3 as jr

    #Initial environment
    jr.AllStaticFuncs.cleanJosnFIle()

    #Instance for multiple process    
    mpr = jr.MultipleProcessRun(options)
    mpr.startRun()

    #Collect all result and generate json file
    tcmap=mpr.getResultMap()

    #Compress result of project
    jr.AllStaticFuncs.compressFile(jr.AllStaticFuncs.getBuildPath())
    
    #Verify project result and mark status
    if mpr.getMulPoolStatus()["status"] is True:
        exit_code = 0
    else:
        jr.LOGGER.warn(mpr.getMulPoolStatus()["info"])
        exit_code = 5
    #LOGGER.debug("Returned value : %d" %exit_code)
    sys.exit(exit_code)

if __name__ == "__main__":
    main()
