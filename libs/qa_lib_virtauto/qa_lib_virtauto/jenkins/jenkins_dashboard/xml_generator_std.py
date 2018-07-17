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


PRJ_PREFIX_STRING = {'GI':"Virt Install\s+-\s+",
                     'HU':"Host-Upgrade\s+|Host-Migration\s+",
                     'GM':"Guest-Migration\s+",
                     'GU':"Guest Upgrade\s+-\s+|Virt Install\s+-\s+"}


PRJ_CLASS_NAME = {'GI':{'classname':'XMLForPrj1', 'prjname':'Prj1-Guest_Installation'},
                  'HU':{'classname':'XMLForPrj2', 'prjname':'Prj2-Host_Upgrade'},
                  'GM':{'classname':'XMLForPrj3', 'prjname':'Prj3-Guest_Migration'},
                  'GU':{'classname':'XMLForPrj4', 'prjname':'Prj4-Guest_Upgrade'}
                  }




PRJ1_FORMAT =['Status', 'Date', 'BuildID',
#              'SLES-11-SP3-64.KVM', 'SLES-11-SP3-64.XEN',
              'SLES-11-SP4-64.KVM', 'SLES-11-SP4-64.XEN',
              'SLES-12-SP0-64.KVM', 'SLES-12-SP0-64.XEN',
              'SLES-12-SP1-64.KVM', 'SLES-12-SP1-64.XEN',
              'SLES-12-SP2-64.KVM', 'SLES-12-SP2-64.XEN',
              ]

PRJ2_FORMAT =['Status', 'Date', 'BuildID',
              # SLE 11 SP3 and it's relevant scenarios
              'SLES-11-SP3-64.KVM -> SLES-11-SP4-64.KVM',
              'SLES-11-SP3-64.KVM -> SLES-12-SP0-64.KVM',
              'SLES-11-SP3-64.KVM -> SLES-12-SP1-64.KVM',
#              'SLES-11-SP3-64.KVM -> SLES-12-SP2-64.KVM',
              'SLES-11-SP3-64.XEN -> SLES-11-SP4-64.XEN',
              'SLES-11-SP3-64.XEN -> SLES-12-SP0-64.XEN',
              'SLES-11-SP3-64.XEN -> SLES-12-SP1-64.XEN',
#              'SLES-11-SP3-64.XEN -> SLES-12-SP2-64.XEN',

              # SLE 11 SP3 and it's relevant scenarios
              'SLES-11-SP4-64.KVM -> SLES-12-SP0-64.KVM',
              'SLES-11-SP4-64.KVM -> SLES-12-SP1-64.KVM',
              'SLES-11-SP4-64.KVM -> SLES-12-SP2-64.KVM',
              'SLES-11-SP4-64.XEN -> SLES-12-SP0-64.XEN',
              'SLES-11-SP4-64.XEN -> SLES-12-SP1-64.XEN',
              'SLES-11-SP4-64.XEN -> SLES-12-SP2-64.XEN',              

              # SLE 12 SP0 and it's relevant scenarios
              'SLES-12-SP0-64.KVM -> SLES-12-SP1-64.KVM',
              'SLES-12-SP0-64.KVM -> SLES-12-SP2-64.KVM',
              'SLES-12-SP0-64.XEN -> SLES-12-SP1-64.XEN',
              'SLES-12-SP0-64.XEN -> SLES-12-SP2-64.XEN',

              # SLE 12 SP1 and it's relevant scenarios
              'SLES-12-SP1-64.KVM -> SLES-12-SP2-64.KVM',
              'SLES-12-SP1-64.XEN -> SLES-12-SP2-64.XEN',          
              ]

PRJ3_FORMAT =['Status', 'Date', 'BuildID',
              # SLE 11 SP3 and it's relevant scenarios
              'SLES-11-SP3-64.KVM -> SLES-11-SP3-64.KVM',
              'SLES-11-SP3-64.KVM -> SLES-11-SP4-64.KVM',
              'SLES-11-SP3-64.KVM -> SLES-12-SP0-64.KVM',
              'SLES-11-SP3-64.KVM -> SLES-12-SP1-64.KVM',
#              'SLES-11-SP3-64.KVM -> SLES-12-SP2-64.KVM',
              'SLES-11-SP3-64.XEN -> SLES-11-SP3-64.XEN',
              'SLES-11-SP3-64.XEN -> SLES-11-SP4-64.XEN',

              # SLE 11 SP3 and it's relevant scenarios
              'SLES-11-SP4-64.KVM -> SLES-11-SP4-64.KVM',
              'SLES-11-SP4-64.KVM -> SLES-12-SP0-64.KVM',
              'SLES-11-SP4-64.KVM -> SLES-12-SP1-64.KVM',
#              'SLES-11-SP4-64.KVM -> SLES-12-SP2-64.KVM',
              'SLES-11-SP4-64.XEN -> SLES-11-SP4-64.XEN',         

              # SLE 12 SP0 and it's relevant scenarios
              'SLES-12-SP0-64.KVM -> SLES-12-SP0-64.KVM',
              'SLES-12-SP0-64.KVM -> SLES-12-SP1-64.KVM',
              'SLES-12-SP0-64.KVM -> SLES-12-SP2-64.KVM',
              'SLES-12-SP0-64.XEN -> SLES-12-SP0-64.XEN',
              'SLES-12-SP0-64.XEN -> SLES-12-SP1-64.XEN',
              'SLES-12-SP0-64.XEN -> SLES-12-SP2-64.XEN',

              # SLE 12 SP1 and it's relevant scenarios
              'SLES-12-SP1-64.KVM -> SLES-12-SP1-64.KVM',
              'SLES-12-SP1-64.KVM -> SLES-12-SP2-64.KVM',
              'SLES-12-SP1-64.XEN -> SLES-12-SP1-64.XEN',
              'SLES-12-SP1-64.XEN -> SLES-12-SP2-64.XEN',          
              
              # SLES 12 SP2 and it's relevant scenarios
              'SLES-12-SP2-64.XEN -> SLES-12-SP2-64.XEN',          
              'SLES-12-SP2-64.KVM -> SLES-12-SP2-64.KVM',
              ]


PRJ4_FORMAT = ['Status', 'Date', 'BuildID',
              #'SLES-11-SP3-64.KVM', 'SLES-11-SP3-64.XEN',
              'SLES-11-SP4-64.KVM', 'SLES-11-SP4-64.XEN',
              #'SLES-12-SP0-64.KVM', 'SLES-12-SP0-64.XEN',
              'SLES-12-SP1-64.KVM', 'SLES-12-SP1-64.XEN',
              'SLES-12-SP2-64.KVM', 'SLES-12-SP2-64.XEN',
              ]


PRJ_FORMAT = {'GI':PRJ1_FORMAT,
              'HU':PRJ2_FORMAT,
              'GM':PRJ3_FORMAT,
              'GU':PRJ4_FORMAT,}


class BuildDataCollectionStd(BuildDataCollection, object):
    def __init__(self, options, prj_format):
        super(BuildDataCollectionStd, self).__init__(options, prj_format)
        
        self.options = options
        self.prd_ver = self._getLatestPrd()

    def _getLatestPrd(self):
        if self.options.prd_ver is None:
            return sorted(STD_PRJ_JENKINS_PATH.keys(), reverse=True)[0]
        else:
            return self.options.prd_ver

    def _getCaseName(self, case_data):
        ''' Get test case name, this only for prj1
        '''
        if 'name' in case_data:
            
            for prj, prefix_string in PRJ_PREFIX_STRING.items():
                if re.search(self.prj_type, prj, re.I):
                    return re.sub(prefix_string, "", case_data['name']).strip()
            '''
            if self.prj_type == 'gi':
                return re.sub("Virt Install\s+-\s+", "", case_data['name']).strip()
            elif self.prj_type == "hu":
                LOGGER.debug("HU should run here")
                return re.sub("Host-Migration\s+", "", case_data['name']).strip()
            elif self.prj_type == "gm":
                return re.sub("Guest-Migration\s+", "", case_data['name']).strip()
            elif self.prj_type == "gu":
                return re.sub("Guest Upgrade\s+-\s+", "", case_data['name']).strip()
            '''

    def _getJenkinsJobRelativePath(self):

        for prj_type in STD_PRJ_JENKINS_PATH[self.prd_ver].keys():
            if re.search(self.prj_type, prj_type, re.I):
                return os.path.join("../../../../", STD_PRJ_JENKINS_PATH[self.prd_ver][prj_type])

        '''
        if self.prj_type == 'gi':
            aim_job_url = os.path.join("../../../../", STD_PRJ_JENKINS_PATH[self.prd_ver]['GI'])
        elif self.prj_type == 'hu':
            aim_job_url = os.path.join("../../../../", STD_PRJ_JENKINS_PATH[self.prd_ver]['HU'])
        elif self.prj_type == 'gm':
            aim_job_url = os.path.join("../../../../", STD_PRJ_JENKINS_PATH[self.prd_ver]['GM'])
            
        return aim_job_url
        '''

    def _getJenkinsJobUrl(self):

        cur_job_url = os.getenv("JOB_URL", os.getcwd())
        for prj_type in STD_PRJ_JENKINS_PATH[self.prd_ver].keys():
            if re.search(self.prj_type, prj_type, re.I):
                return os.path.join(cur_job_url, "../../../", STD_PRJ_JENKINS_PATH[self.prd_ver][prj_type])
        '''
        if self.prj_type == 'gi':
            aim_job_url = os.path.join(cur_job_url, "../../../", STD_PRJ_JENKINS_PATH[self.prd_ver]['GI'])
        elif self.prj_type == 'hu':
            aim_job_url = os.path.join(cur_job_url, "../../../", STD_PRJ_JENKINS_PATH[self.prd_ver]['HU'])
        elif self.prj_type == 'gm':
            aim_job_url = os.path.join(cur_job_url, "../../../", STD_PRJ_JENKINS_PATH[self.prd_ver]['GM'])

        return aim_job_url
        '''

    def _getPKLFileName(self):

        if self.prd_ver is None:
            prdver = ""
        else:
            prdver = self.prd_ver
        # Store data file
        pkl_file =  "last-build_%s_%s%s.pkl" %(self.prj_type, self.test_type, prdver)
        
        return os.path.join(self.pkl_folder, pkl_file)


class ParseCMDParamSTD(optparse.OptionParser, object):
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
        self.testtype_full_name = "Milestone"
        self.prj_format = self.getPrjFormat()
        self.bc = BuildDataCollectionStd(self.options, self.prj_format)

    def getLatestPrd(self):
        if self.options.prd_ver is None:
            return sorted(STD_PRJ_JENKINS_PATH.keys(), reverse=True)[0]
        else:
            return self.options.prd_ver

    def str_to_class(self, field):
        import types
        try:
            identifier = getattr(sys.modules[__name__], field)
        except AttributeError:
            raise NameError("%s doesn't exist." % field)
        if isinstance(identifier, (types.ClassType, types.TypeType)):
            return identifier
        raise TypeError("%s is not a class." % field)


    def __call__(self):
        status, all_data = self.bc.cmpBuildList()

        if status:
            if self.options.test_type == "dev":
                prd_ver = ""
            else:
                if self.options.prd_ver is None:
                    prd_ver = "latest"
                else:
                    prd_ver = "old"
            LOGGER.info(self.options)
            for prj, names in PRJ_CLASS_NAME.items():
                if re.search(self.options.prj_type, prj, re.I):
                    xml_name = "%s_%s%s.xml" %(names['prjname'], self.testtype_full_name, prd_ver)
                    prj_class = self.str_to_class(names['classname'])
                    xg = prj_class(name="%s %s Test Result" %(re.sub('[-_]'," ", names['prjname']), self.testtype_full_name),
                                   prj_format=self.prj_format)

            LOGGER.debug("XML NAME IS %s" %xml_name)
            xg.genBasicTr()
            xg.genTableRange(all_data)
            xg.genSectionRange()
            xg.wirte2XML(os.path.join(self.bc.archive_folder, xml_name))
            sys.exit(0)
        else:
            # No new build data
            sys.exit(1)

    def getPrjFormat(self):
        if self.options.prj_type in ["gi", "gu"]:
            format = PRJ_FORMAT[self.options.prj_type.upper()]
            return format
            #tmp_fromat = copy.copy(format[0:3])
        else:
            for prj in PRJ_FORMAT.keys():
                if re.search(self.options.prj_type, prj, re.I):
                    format = PRJ_FORMAT[prj]
        tmp_fromat = copy.copy(format[0:3])

        prd_ver = self.getLatestPrd()
        for scen in format[3:]:
            if prd_ver in scen:
                tmp_fromat.append(scen)
        LOGGER.debug("PRJ Format is %s" %str(tmp_fromat))
        return tmp_fromat


class XMLForPrj4(XMLForPrj2, object):
    
    def __init__(self, name, prj_format):
        super(XMLForPrj4, self).__init__(name, prj_format)


if __name__ == '__main__':
    #main()
    param_opt = ParseCMDParamSTD()
    options, _args = param_opt.parse_args()
    GenerateXML(options)()
