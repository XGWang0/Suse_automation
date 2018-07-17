#!/usr/bin/env python
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
  Description: This script is the main portal for generating dashboard of virt test
  Function & Scope: All type virt test dashboard
"""

from xml_generator_lib import *


class ParseCMDParamDEV(optparse.OptionParser, object):
    """Class which parses command parameters
    """

    def __init__(self):
        optparse.OptionParser.__init__(
            self, 
            usage='Usage: %prog [options]',
            epilog="NOTE: This script only for collecting virt test data.")

        # guest installation

        self.add_option("-p", "--project-type", action="store", type="string",
                        dest="prj_type",
                        help=("Set test type, gi|hu|gm is available"
                              "\ngi represents Prj1 Guest Installation"
                              "\nhu represents Prj2 Host Upgrade"
                              "\ngm represetns Prj3 Guest Migration"))
        
        self.add_option("-t", "--test-type", action="store", type="string",
                        dest="test_type",
                        help=("Set test type, dev|std|is available"
                              "\nstd Milestone/Daily test"
                              "\ndev Unit test"))

        self.add_option("-n", "--case-count", action="store", type="int",
                        dest="case_count",
                        help=("Keep ${case count} cases result. No using this parameter means keeping all data."))
        #''
    
        self.add_option("--job-url", action="append", type="string",
                        dest="job_url",
                        help=("Input product version, just like sles-12-sp0-64 and sles-11-sp4-64,"
                              "This parameter as detecting object is used to check changed packages, if yes,"
                              "job of prj1 will be triggered automatically. This parameter supports multiple uses,"
                              "such as \"--gi-prd sles-12-sp0-64 --gi-prd sles-12-sp1-64\""))

        self.add_option("--job-path", action="store", type="string",
                        dest="job_path",
                        help=("Input the job link of prj1 in here"))
        #''
        LOGGER.debug("Params : " + str(sys.argv))

class GenerateXML(GenerateXML, object):
    
    def __init__(self, options):
        super(GenerateXML, self).__init__(options)
        self.testtype_full_name = "Unit"
        self.prj_format = self.getPrjFormat()
        self.bc = BuildDataCollection(self.options, self.prj_format)

    def getPrjFormat(self):
        if self.options.prj_type == "gi":
            format = PRJ1_FORMAT
        elif self.options.prj_type == "hu":
            format = PRJ2_FORMAT
        else:
            format = PRJ3_FORMAT

        return format


if __name__ == '__main__':
    #main()
    param_opt = ParseCMDParamDEV()
    options, _args = param_opt.parse_args()
    GenerateXML(options)()