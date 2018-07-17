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

import copy
import datetime
import sys
import time
import pickle
import json
import re
import os
import optparse
import logging
from lxml import etree
from urllib2 import urlopen, HTTPError


DEV_PRJ_JENKINS_PATH = {'GI':'VIRT_DEV_TEST/job/Prj1-Guest_Installation_Unit/',
                        'HU':'VIRT_DEV_TEST/job/Prj2-Host_Upgrade_Unit/',
                        'GM':'VIRT_DEV_TEST/job/Prj3-Guest_Migration_Unit/',}

STD_PRJ_JENKINS_PATH = {'SLES-12-SP2':{'GI':'VIRT_MILES_TEST_SLE12SP2/job/Prj1-Guest_Installation_MileStone/',
                                       'HU':'VIRT_MILES_TEST_SLE12SP2/job/Prj2-Host_Upgrade_MileStone/',
                                       'GM':'VIRT_MILES_TEST_SLE12SP2/job/Prj3-Guest_Migration_MileStone/',
                                       'GU':'VIRT_MILES_TEST_SLE12SP2/job/Prj4-Guest_Upgrade_MileStone/'},

                        'SLES-12-SP1':{'GI':'VIRT_MILES_TEST_SLE12SP1/job/Prj1-Guest_Installation_MileStone/',
                                       'HU':'VIRT_MILES_TEST_SLE12SP1/job/Prj2-Host_Upgrade_MileStone/',
                                       'GM':'VIRT_MILES_TEST_SLE12SP1/job/Prj3-Guest_Migration_MileStone/',},
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
              'SLES-11-SP3-64.KVM -> SLES-12-SP2-64.KVM',
              'SLES-11-SP3-64.XEN -> SLES-11-SP4-64.XEN',
              'SLES-11-SP3-64.XEN -> SLES-12-SP0-64.XEN',
              'SLES-11-SP3-64.XEN -> SLES-12-SP1-64.XEN',
              'SLES-11-SP3-64.XEN -> SLES-12-SP2-64.XEN',

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
              'SLES-11-SP3-64.KVM -> SLES-12-SP2-64.KVM',
              'SLES-11-SP3-64.XEN -> SLES-11-SP3-64.XEN',
              'SLES-11-SP3-64.XEN -> SLES-11-SP4-64.XEN',

              # SLE 11 SP3 and it's relevant scenarios
              'SLES-11-SP4-64.KVM -> SLES-11-SP4-64.KVM',
              'SLES-11-SP4-64.KVM -> SLES-12-SP0-64.KVM',
              'SLES-11-SP4-64.KVM -> SLES-12-SP1-64.KVM',
              'SLES-11-SP4-64.KVM -> SLES-12-SP2-64.KVM',
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

class LoggerHandling(object):
    """Class which support to add five kind of level info to file
    and standard output 
    """
    def __init__(self, log_level=logging.DEBUG):

        logging.basicConfig(level=log_level,
                            format='%(asctime)s %(filename)s[line:%(lineno)d] [%(process)d]-[%(threadName)s] %(levelname)-6s | %(message)s',
                            datefmt='%a, %d %b %Y %H:%M:%S',
                            #filename=log_file,
                            #filemode='w'
                            )

        console = logging.StreamHandler()

        console.setLevel(log_level)
        formatter = logging.Formatter('%(asctime)s [%(process)d] [%(threadName)s]: %(levelname)-8s %(message)s')
        console.setFormatter(formatter)

        self.logger = logging.getLogger('')
        #self.logger.addHandler(console)

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

class JenkinsAPI(object):
    
    def __init__(self):
        self.jenkins_url = ''

    def getJobStatus(self, url, job_name):
        jobs_data = self.getJobsData(url)
        
        for job in jobs_data:
            if job['name'] == job_name:
                if job['color'] == 'blue':
                    return 'pending'
                elif job['color'] == 'blue':
                    pass

    @staticmethod
    def checkURLPatchWithAgent(url):
        import requests
        #TODO maybe need to install package requests when python version is lower than 2.7.8
        headers = {
         'User-Agent': 'Mozilla'
        }
        
        try:
            r = requests.get(url, headers=headers)
            status = r.status_code
            if status == 200:
                LOGGER.debug("Successfully access url [%s]" %url)
                return True
            else:
                LOGGER.debug("Failed to access url , status_code is %s" %str(status))
                return False
        except requests.exceptions.ConnectionError, e:
            LOGGER.debug("checkURLPatchWithAgent exception %s" %str(e))
            return False

    @staticmethod
    def checkURLPath(url):
        try:
            w = urlopen("%s" %url)
            return True
        except HTTPError,e:
            LOGGER.debug("URL [%s] %s" %(url,e) )
            return False
        except Exception, e:
            LOGGER.debug("URL [%s] %s" %(url,e) )
            return False

    @staticmethod
    def getBuildList(url):
        #url = 'http://127.0.0.1:8080/job/test'
        url = os.path.join(url, 'api', 'json?pretty=true', '&tree=builds[number,url]')
        job_status = ""
        builds_data = []
        
        if JenkinsAPI().checkURLPath(url):
            req = urlopen(url)
            data = json.loads(req.read())
            if "builds" in data:
                builds_data = data["builds"]
        
        return builds_data

    @staticmethod
    def getBuildStatus(url):
        #url = 'http://127.0.0.1:8080/job/test'
        url = os.path.join(url, 'api', 'json?pretty=true', '&tree=result')
        job_status = ""
        builds_data = []
        builds_status = "FAILURE"
        if JenkinsAPI().checkURLPath(url):
            req = urlopen(url)
            data = json.loads(req.read())
            if "result" in data:
                if data["result"] is None:
                    builds_status = "RUNNING"
                else:
                    builds_status = data["result"]

        return builds_status

    @staticmethod
    def getBuildTimeStamp(url):
        #url = 'http://127.0.0.1:8080/job/test'
        url = os.path.join(url, 'api', 'json?pretty=true', '&tree=timestamp')
        builds_date = 0
        if JenkinsAPI().checkURLPath(url):
            req = urlopen(url)
            data = json.loads(req.read())
            if "timestamp" in data:
                builds_date = data["timestamp"]

        ltime=time.localtime(int(builds_date/1000))
        timeStr=time.strftime("%Y-%m-%d %H:%M:%S", ltime)
        
        return timeStr

    @staticmethod
    def getBuildDIsplayName(url):
        #url = 'http://127.0.0.1:8080/job/test'
        url = os.path.join(url, 'api', 'json?pretty=true', '&tree=displayName')
        builds_name = ""
        if JenkinsAPI().checkURLPath(url):
            req = urlopen(url)
            data = json.loads(req.read())
            if "displayName" in data:
                if data["displayName"]:
                    builds_name = data["displayName"]
        
        return builds_name

    @staticmethod
    def getBuildPath(joburl):
        url_l = joburl.replace(os.getenv("JENKINS_URL",""), "")
        url_l = os.path.join(os.getenv("JENKINS_HOME",""), url_l)
        url_j = url_l.replace("%sjob%s" %(os.sep, os.sep), '%sjobs%s' %(os.sep, os.sep))
        #build_path = os.path.join(url_j, "builds", os.getenv("BUILD_NUMBER", "1"))
        build_path = os.path.join(url_j, "builds")
        LOGGER.debug("BUild path is [%s]" %build_path)
        if os.path.exists(build_path):
            return build_path
        else:
            return ""

def getCDATA(data):
    return etree.CDATA(data)

class IMAGE(object):

    def __init__(self, src, align="middle", **attrs):
        base_attr = {'src':src,}
        base_attr.update(attrs)
        self.imgET = etree.Element("img", base_attr)

    def genIMGSTR(self, imet):
        return u'%s' %etree.tostring(imet)

    def getImageOnCDATA(self):
        imgstr = self.genIMGSTR(self.imgET)
        return getCDATA(imgstr)

    def getIMGET(self):
        return self.imgET

    def toString(self):
        return etree.tostring(self.imgET, pretty_print=True, encoding="UTF-8",
                              method="xml", xml_declaration=True, standalone=None)


class TD(object):

    def __init__(self, value="td", bgcolor="", fontcolor="",
                 title="", fontattribute="",  align="", width="", flg=True, **attrs):
        basic_attr = {'value':value,
                     'bgcolor':bgcolor,
                     'fontcolor':fontcolor,
                     'title':title,
                     'fontattribute':fontattribute,
                     'align':align,
                     'width':width}
    
        basic_attr.update(attrs)
        if flg is False:
            self.tdET = etree.Element("td")
        else:
            self.tdET = etree.Element("td", basic_attr)

    def addText2TD(self, text):
        self.tdET.text = text

    def appendET2TD(self, sub_et):
        self.tdET.append(sub_et)

    def getTDET(self):
        return self.tdET

    def toString(self):
        return etree.tostring(self.tdET, pretty_print=True, encoding="UTF-8",
                              method="xml", xml_declaration=True, standalone=None)


class TR(object):

    def __init__(self, value="tr", bgcolor="", fontcolor="GREEN",
                 title="", fontattribute="",  align="", width="", **attrs):
        
        basic_attr = {'value':value,
                     'bgcolor':bgcolor,
                     'fontcolor':fontcolor,
                     'title':title,
                     'fontattribute':fontattribute,
                     'align':align,
                     'width':width}
        basic_attr.update(attrs)
        self.trET = etree.Element("tr", basic_attr)

    def addText2TR(self, text):
        self.trET.text = text

    def appendET2TR(self, sub_et):
        self.trET.append(sub_et)

    def getTRET(self):
        return self.trET

    def toString(self):
        return etree.tostring(self.trET, pretty_print=True, encoding="UTF-8",
                              method="xml", xml_declaration=True, standalone=None)

class TABLE(object):

    def __init__(self, **attrs):

        self.tableET = etree.Element("table", attrs)

    def addText2Table(self, text):
        self.tableET.text = text

    def appendET2Table(self, sub_et):
        self.tableET.append(sub_et)

    def getTableET(self):
        return self.tableET

    def toString(self):
        return etree.tostring(self.tableET, pretty_print=True, encoding="UTF-8",
                              method="xml", xml_declaration=True, standalone=None)


class ACCORDION(object):

    def __init__(self, name="Prj1 ", **attrs):
        basic_attr = {'name':name,}
        basic_attr.update(attrs)
        
        self.accordionET = etree.Element("accordion", basic_attr)

    def addText2Accordion(self, text):
        self.accordionET.text = text

    def appendET2Accordion(self, sub_et):
        self.accordionET.append(sub_et)

    def getAccordionET(self):
        return self.accordionET

    def toString(self):
        return etree.tostring(self.accordionET, pretty_print=True, encoding="UTF-8",
                              method="xml", xml_declaration=True, standalone=None)


class FIELD(object):

    def __init__(self, name="Data Statistic", titlecolor="", value="", detailcolor="", href="", **attrs):
        basic_attr = {'name':name,
                     'titlecolor':titlecolor,
                     'value':value,
                     'detailcolor':detailcolor,
                     'href':href
                     }
        basic_attr.update(attrs)
        
        self.fieldET = etree.Element("field", basic_attr)

    def addText2Field(self, text):
        self.fieldET.text = text

    def appendET2Field(self, sub_et):
        self.fieldET.append(sub_et)

    def getFieldET(self):
        return self.fieldET

    def toString(self):
        return etree.tostring(self.fieldET, pretty_print=True, encoding="UTF-8",
                              method="xml", xml_declaration=True, standalone=None)

class SECTION(object):

    def __init__(self, name="", fontcolor="", **attrs):
        basic_attr = {'name':name,
                     'fontcolor':fontcolor,
                     }
        basic_attr.update(attrs)
        
        self.sectionET = etree.Element("section", basic_attr)

    def addText2Section(self, text):
        self.sectionET.text = text

    def appendET2Section(self, sub_et):
        self.sectionET.append(sub_et)

    def getSectionET(self):
        return self.sectionET

    def toString(self):
        return etree.tostring(self.sectionET, pretty_print=True, encoding="UTF-8",
                              method="xml", xml_declaration=True, standalone=None)

    def write2File(self, filename):
        with open(filename, "w+") as f:
            f.truncate()
            f.write(self.toString())


class XMLForPrj1(object):
    def __init__(self, name, prj_format):

        self.sECTION = SECTION()
        self.fIELD = FIELD()
        self.aCCORDION = ACCORDION(name=name)
        self.tABLE = TABLE(title="")
        
        self.TR_FORMAT = prj_format
    
    def genBasicTr(self):
        tdlist = [TD(value=td, fontattribute="bold", fontcolor="blue") for td in self.TR_FORMAT]
        tr = self.genTRRange(tdlist)
        self.tABLE.appendET2Table(tr.getTRET())
            
    
    def genTRRange(self, tdlist):
        tR = TR()
        for t in tdlist:
            tR.appendET2TR(t.getTDET())
        return tR

    def genTableRange(self, data):
        for item in data:
            tdlist = []
            LOGGER.info("ITEM IS %s" %str(item))
            for ele in self.TR_FORMAT:
                
                LOGGER.debug("ELE IS %s" %str(ele))
                if ele == 'BuildID':
                    tdlist.append(TD(value=item[ele][1], href=item['URL']))
                elif ele == 'Status':
                    imget = IMAGE(src=item['Status']).getImageOnCDATA()
                    td = TD(flg=False)
                    td.addText2TD(imget)
                    tdlist.append(td)
                elif ele == "Date":
                    tdlist.append(TD(value=item[ele]))
                else:
                    if '|' in item[ele][0]:
                        if int(item[ele][0].split("|")[-1]) > 0:
                            font_colur = "red"
                        else:
                            font_colur = "green"
                        
                        tdlist.append(TD(value=item[ele][0], fontcolor=font_colur, href=item[ele][1]))

                    else:
                        tdlist.append(TD(value=item[ele]))

            tR = self.genTRRange(tdlist)
            self.tABLE.appendET2Table(tR.getTRET())

    def genSectionRange(self):      
        
        self.aCCORDION.appendET2Accordion(self.tABLE.getTableET())
        self.fIELD.addText2Field(getCDATA("  "))
        self.sECTION.appendET2Section(self.fIELD.getFieldET())
        self.sECTION.appendET2Section(self.aCCORDION.getAccordionET())

    def createArchivePath(self):
        build_path = JenkinsAPI().getBuildPath(os.getenv("JOB_URL",""))
        build_archive_path = os.path.join(build_path, os.getenv("BUILD_NUMBER","1"), "archive")
        LOGGER.debug("Archive path is [%s]" %build_archive_path)
        if build_path:
            if os.path.exists(build_archive_path):
                pass
            else:
                os.mkdir(build_archive_path)
            return build_archive_path
        else:
            LOGGER.error("Failed to get build path, exit!!")
            sys.exit(10)

    def wirte2XML(self, filename):
        LOGGER.debug("xml content is %s" %str(self.sECTION.toString()))

        #filename = os.path.join(self.createArchivePath(), filename)
        LOGGER.info("XML file abs path is [%s]" %filename)
        #if os.path.exists(filename):
        #    os.remove(filename)
        self.sECTION.write2File(filename)


class XMLForPrj2(XMLForPrj1, object):
    
    def __init__(self, name, prj_format):
        super(XMLForPrj2, self).__init__(name, prj_format)

    def genBasicTr(self):
        tdlist = [TD(value=td, fontattribute="bold; font-size:13px", fontcolor="blue") for td in self.TR_FORMAT]
        tr = self.genTRRange(tdlist)
        self.tABLE.appendET2Table(tr.getTRET())

    def genTableRange(self, data):
        for item in data:
            tdlist = []
            LOGGER.info("ITEM IS %s" %str(item))
            for ele in self.TR_FORMAT:
                
                LOGGER.debug("ELE IS %s" %str(ele))
                if ele == 'BuildID':
                    tdlist.append(TD(value=item[ele][1], href=item['URL'], fontattribute="; font-size:13px"))
                elif ele == 'Status':
                    imget = IMAGE(src=item['Status']).getImageOnCDATA()
                    td = TD(flg=False)
                    td.addText2TD(imget)
                    tdlist.append(td)
                elif ele == "Date":
                    tdlist.append(TD(value=item[ele], fontattribute="; font-size:13px"))
                else:
                    if ele in item:
                        if '|' in item[ele][0]:
                            if int(item[ele][0].split("|")[-1]) > 0:
                                font_colur = "red"
                                ele_status = "FAILED"
                            else:
                                font_colur = "green"
                                ele_status = "PASSED"
                            
                            tdlist.append(TD(value=ele_status, fontcolor=font_colur, href=item[ele][1], fontattribute="; font-size:13px"))
    
                        else:
                            tdlist.append(TD(value=item[ele], fontattribute="; font-size:13px"))
                    else:
                        pass

            tR = self.genTRRange(tdlist)
            self.tABLE.appendET2Table(tR.getTRET())


class XMLForPrj3(XMLForPrj2, object):
    
    def __init__(self, name, prj_format):
        super(XMLForPrj3, self).__init__(name, prj_format)

class BuildDataCollection(object):

    def __init__(self, options, prj_format):

        # Supply jenkins job url and job local path
        self.prj_type = options.prj_type
        self.test_type = options.test_type
        self.case_count = options.case_count is not None and options.case_count or 0

        # Get tr format structure
        #self.xml_format = self.getPrjXmlFormat()
        self.xml_format = copy.copy(prj_format)
       
        self.xml_folder = os.path.join(os.getenv("JENKINS_HOME", os.getcwd()), "VIRT-DASHBOARD")
        self.pkl_folder = self.creatFolder("pkl")
        self.archive_folder = self.creatFolder("archive")
        
        # Get jenkins url
        self.jenkins_url = os.getenv("JENKINS_URL", os.getcwd())
        
        # Initial pic table according to build status
        self.jenkins_url = 'http://127.0.0.1:8080'
        self.build_status_img = {"RUNNING":   os.path.join(self.jenkins_url, '/userContent/pic/blue_anime.gif'),
                                 "SUCCESS":os.path.join(self.jenkins_url, '/userContent/pic/blue.png'),
                                 "FAILURE":os.path.join(self.jenkins_url, '/userContent/pic/red.png'),
                                 "ABORTED":os.path.join(self.jenkins_url, '/userContent/pic/aborted.png')}

    '''
    def getPrjXmlFormat(self):

        tmp_format = []
        if self.prj_type == 'gi':
            tmp_format = copy.copy(PRJ1_FORMAT)
        elif self.prj_type == 'hu':
            tmp_format = copy.copy(PRJ2_FORMAT)
        else:
            tmp_format = copy.copy(PRJ3_FORMAT)
        
        tmp_format.append("URL")
        
        return tmp_format
    '''

    def creatFolder(self, folder):
        def _makeDir(path):
            if os.path.exists(path):
                pass
            else:
                os.mkdir(path)

        sub_folder = os.path.join(self.xml_folder, folder) 
        _makeDir(self.xml_folder)
        _makeDir(sub_folder)
        
        return sub_folder

    def _getPKLFileName(self, prdver=""):

        # Store data file
        pkl_file =  "last-build_%s_%s%s.pkl" %(self.prj_type, self.test_type, prdver)
        
        return os.path.join(self.pkl_folder, pkl_file)

    def getLastBuildData(self):
        ''' Reload the build data for last time getting
        '''
        build_data = []
        #build_file = os.path.join(self.pkl_folder, self.pkl_file)
        build_file = self._getPKLFileName()
        
        if os.path.exists(build_file):
            with open(build_file, "r") as f:
                build_data = pickle.load(f)
        
        return build_data

    def saveCurrBuildData(self, data):
        ''' Dump data to local file
        '''

        build_data = []
        #build_file = os.path.join(self.pkl_folder, self.pkl_file)
        build_file = self._getPKLFileName()
        if os.path.exists(build_file):
            os.remove(build_file)

        with open(build_file, "wr") as f:
            LOGGER.debug("Dump data [%s] to file [%s]" %(str(data), build_file))
            build_data = pickle.dump(data, f)

    def _getBuildStatusImg(self, url):
        ''' Get the image path according build status, this pic will show on dashboard
        '''
        image_url = ""
        build_status = JenkinsAPI().getBuildStatus(url)
        if build_status in self.build_status_img:
            image_url = self.build_status_img[build_status]
        else:
            image_url = ""
        LOGGER.debug("Image url is %s" %image_url)
        return image_url

    def _getCurrResultUrl(self, url):
        ''' Concat the cucumber repost url
        '''
        cucumber_report_url =  os.path.join(url, 'cucumber-html-reports')
        LOGGER.debug("The cucumber htmal report is %s" %cucumber_report_url)
        return cucumber_report_url

    def _getCaseName(self, case_data):
        ''' Get test case name, this only for prj1
        '''
        if 'name' in case_data:
            if self.prj_type == 'gi':
                return re.sub("Virt Install\s+-\s+", "", case_data['name']).strip()
            elif self.prj_type == "hu":
                LOGGER.debug("HU should run here")
                return re.sub("Host-Upgrade\s+|Host-Migration\s+", "", case_data['name']).strip()
            else:
                return re.sub("Guest-Migration\s+", "", case_data['name']).strip()
                
    def _getCaseNum(self, case_data):
        ''' Count step number, contain passed number, failed number and all
        '''
        pass_cases = fail_cases = 0
        if 'elements' in case_data:
            for scen in case_data['elements']:
                for step in scen['steps']:
                    if 'result' in step:
                        if 'status' in step['result']:
                            if step['result']['status'] == 'passed':
                                pass_cases += 1
                            else:
                                fail_cases += 1
        
        return (str(pass_cases+fail_cases), str(pass_cases), str(fail_cases))              

    def _getCaseUrl(self, case_data, build_num):
        tmp_url =""
        prd_job_url = os.path.join(self._getJenkinsJobUrl(), build_num, "cucumber-html-reports")
        if 'uri' in case_data:
            tmp_url = re.sub("\s+", "", case_data['uri']) + '.html'
            abs_tmp_url = os.path.join(prd_job_url, tmp_url)
            LOGGER.debug("Abs Case url is [%s]" %abs_tmp_url)
            if JenkinsAPI().checkURLPatchWithAgent(abs_tmp_url) is True:
                return tmp_url
            else:
                tmp_url = re.sub(">", "-", case_data['uri']) + '.html'
                abs_tmp_url = os.path.join(prd_job_url, tmp_url)
                LOGGER.debug("Abs Case url is [%s]" %abs_tmp_url)
                if JenkinsAPI().checkURLPatchWithAgent(abs_tmp_url):
                    return tmp_url
                else:
                    return ""

    def _getScenResult(self, buildnum, jenkins_path):
        ''' Get build data
        '''
        all_scens_data = {}
        # Get the json file absolute path
        local_abs_build_path = os.path.join(jenkins_path, str(buildnum), "cucumber-html-reports", "result.json")
        LOGGER.debug("Json local path is %s" %local_abs_build_path)
        
        if not os.path.exists(local_abs_build_path) or os.path.getsize(local_abs_build_path) == 0:
            LOGGER.warn("File [%s] does not exist or json file is empty" %(local_abs_build_path))
        else:
            # Reload json file as data strucutre
            with open(local_abs_build_path, "r") as f:          
                result_json = json.load(f)
                LOGGER.debug("Json file : %s" %(str(result_json)))
            for feat in result_json:
                scen_name = self._getCaseName(feat)
                step_nums = self._getCaseNum(feat)
                case_url = self._getCaseUrl(feat, buildnum)
                
                LOGGER.debug("Case url is [%s]" %case_url)
                LOGGER.debug("Scenario name is :%s" %str(scen_name))
                LOGGER.debug("Scenario has step number : %s" %(str(step_nums)))
                if scen_name:
                    all_scens_data[scen_name] = [step_nums, case_url]

        return all_scens_data

    def _updateBuildMap(self, build_map, build_number, build_name, build_date, build_status, build_steps, build_url):
        ''' Update map using new data
        '''
        build_map['Status'] = self.build_status_img[build_status.strip()]
        build_map['Date'] = build_date
        build_map['BuildID'] = [build_number, build_name]
        build_map['URL'] = build_url

        # Concatenate case count and case url, [0]: case nums; [1]:case url        
        for scenname, scendata in build_steps.items():
            build_map[str(scenname)] = [str('|'.join(scendata[0])),
                                        os.path.join(build_url, scendata[1])]
        
        return build_map

    #### This Parts should be changed when you want to add some projects #################################################
    def _getJenkinsJobRelativePath(self):
        if self.test_type == "dev":
            if self.prj_type == 'gi':
                aim_job_url = os.path.join("../../../../", DEV_PRJ_JENKINS_PATH['GI'])
            elif self.prj_type == 'hu':
                aim_job_url = os.path.join("../../../../", DEV_PRJ_JENKINS_PATH['HU'])
            elif self.prj_type == 'gm':
                aim_job_url = os.path.join("../../../../", DEV_PRJ_JENKINS_PATH['GM'])

        return aim_job_url

    def _getJenkinsJobUrl(self):
        cur_job_url = os.getenv("JOB_URL", os.getcwd())

        #cur_job_url = 'http://147.2.207.67:8080/job/VIRTUALIZATION/job/31VIRT_DASHBOARD/job/11DashBoard-Prj1_Guest_Installation_Unit/'
        if self.test_type == "dev":
            if self.prj_type == 'gi':
                aim_job_url = os.path.join(cur_job_url, "../../../", DEV_PRJ_JENKINS_PATH['GI'])
            elif self.prj_type == 'hu':
                aim_job_url = os.path.join(cur_job_url, "../../../", DEV_PRJ_JENKINS_PATH['HU'])
            elif self.prj_type == 'gm':
                aim_job_url = os.path.join(cur_job_url, "../../../", DEV_PRJ_JENKINS_PATH['GM'])

        return aim_job_url

    #### This Parts should be changed when you want to add some projects #################################################

    def _getJenkinsBuildData(self):

        aim_job_url = self._getJenkinsJobUrl()
        
        LOGGER.info("Jenkins job url is [%s]" %aim_job_url)

        build_data = JenkinsAPI().getBuildList(aim_job_url)
        #JenkinsAPI().getBuildList('http://147.2.207.67:8080/job/VIRTUALIZATION/job/VIRT_DEV_TEST/job/Prj1-Guest_Installation_Unit')
        LOGGER.debug("Current Build List is %s" %str(build_data))
        
        return build_data

    def _getSubCases(self, data):
        if self.case_count == 0:
            return data
        else:
            return data[0:int(self.case_count)]

    '''
    def _getDiffBuildList(self, curr_build_data, last_build_data):
        # Filter build id from build data. This operation is only for set
        
        curr_build_number = map(lambda k:str(k["number"]), curr_build_data)

        last_build_data = filter(lambda x:x['Status'] != self.build_status_img['RUNNING'], last_build_data)
        last_running_build_data = filter(lambda x:x['Status'] == self.build_status_img['RUNNING'], last_build_data)
        last_build_number = map(lambda k:str(k["BuildID"][0]), last_build_data)

        curr_set_data = set(curr_build_number)
        last_set_data = set(last_build_number)

        diff_build_data = list(curr_set_data - last_set_data)

        if last_set_data - curr_set_data:
            for i, value in enumerate(list(last_set_data - curr_set_data)):
                for s_b in last_build_data:
                    if value == s_b["BuildID"][0]:
                        last_build_data = last_build_data.pop(i)

        elif diff_build_data:
            for d_b in list(curr_set_data - last_set_data):
                if d_b in last_running_build_data:
                    if JenkinsAPI().getBuildStatus(curr_data["url"]) == "RUNNING":
                    
                
        curr_build_number = map(lambda k:str(k["number"]), curr_build_data)

        last_build_data = filter(lambda x:x['Status'] != self.build_status_img['RUNNING'], last_build_data)
        last_running_build_data = filter(lambda x:x['Status'] == self.build_status_img['RUNNING'], last_build_data)
        last_build_number = map(lambda k:str(k["BuildID"][0]), last_build_data)
        
        # Get different build id on both current and older build list
        rest_build_number = list(set(curr_build_number) - set(last_build_number))
        
        if rest_build_number:
            rest_build_number.extend(last_running_build_data)
        else:
            for running_build in last_running_build_data:
                for curr_data in curr_build_data:
                    if running_build == str(curr_data["number"]):
                        if JenkinsAPI().getBuildStatus(curr_data["url"]) == "RUNNING":
                            break
                        else:
                            rest_build_number.append(running_build)
        
        
                            
        LOGGER.debug("The diff build list is [%s]" %(str(rest_build_number)))
    '''
        
    def cmpBuildList(self):
        ''' Compare older build list and current build list and then append the different builds to map and file
        '''
        return_code = True
        # Get current build list
        #curr_build_data = JenkinsAPI().getBuildList('http://147.2.207.67:8080/job/VIRTUALIZATION/job/VIRT_DEV_TEST/job/Prj1-Guest_Installation_Unit')
        curr_build_data = self._getJenkinsBuildData()
        LOGGER.debug("Current build list is %s" %(str(curr_build_data)))
        
        # Get build list from last time geting
        last_build_data = self.getLastBuildData()
        LOGGER.debug("Last build list is %s" %(str(last_build_data)))
        
        # Filter build id from build data. This operation is only for set
        curr_build_number = map(lambda k:str(k["number"]), curr_build_data)

        last_build_number = map(lambda k:str(k["BuildID"][0]), last_build_data)

        # Remove diff data from last build data
        diff_build_last_vs_curr = list(set(last_build_number) - set(curr_build_number))
        cp_last_build_data = copy.deepcopy(last_build_data)
        for db_lc in diff_build_last_vs_curr:
            for i, db_l in enumerate(cp_last_build_data):
                if db_lc == db_l["BuildID"][0]:
                    last_build_data.remove(db_l)

        # Get finished build data
        last_norunning_build_data = filter(lambda x:x['Status'] != self.build_status_img['RUNNING'], last_build_data)
        # Get running build data
        last_running_build_data = filter(lambda x:x['Status'] == self.build_status_img['RUNNING'], last_build_data)
        
        LOGGER.debug("RUnning data is %s" %last_running_build_data)
        LOGGER.debug("Current data is %s" %curr_build_data)
        #Get build number list from finished build data
        last_no_build_number = map(lambda k:str(k["BuildID"][0]), last_norunning_build_data)
        
        #Get all build list 
        last_build_number = map(lambda k:str(k["BuildID"][0]), last_build_data)

        # Get different build id on both current and older build list
        rest_build_number = list(set(curr_build_number) - set(last_build_number))
        LOGGER.debug("The diff build list is [%s]" %(str(rest_build_number)))

        for bd_running in last_running_build_data:
            for bd_curr in curr_build_data:
                if str(bd_curr['number']) == str(bd_running["BuildID"][0]):
                    if JenkinsAPI().getBuildStatus(bd_curr["url"]) == "RUNNING":
                        last_norunning_build_data.append(bd_running)
                    else:
                        rest_build_number.append(bd_running["BuildID"][0])
                    break
                else:
                    continue

        if rest_build_number:
            LOGGER.info("There are new builds data that need to be analyze. build data: [%s] " %str(rest_build_number))
            # Traverse rest build list
            for build_data in rest_build_number:
                diff_build_map = {}.fromkeys(self.xml_format, "--")
                for curr_data in curr_build_data:
                    LOGGER.debug("current build data is [%s]" %(str(build_data)))
                    if build_data == str(curr_data["number"]):
                        build_number = build_data
                        build_name = JenkinsAPI().getBuildDIsplayName(curr_data["url"])

                        build_status = JenkinsAPI().getBuildStatus(curr_data["url"])
                        build_date = JenkinsAPI().getBuildTimeStamp(curr_data["url"])
                        #build_steps = self._getScenResult(build_data, "/tmp/tmp_jenkins_builds")
                        #build_steps = self._getScenResult(build_data, self.jenkins_job_path)
                        build_path = JenkinsAPI().getBuildPath(self._getJenkinsJobUrl())
                        build_url = os.path.join(self._getJenkinsJobRelativePath(), 
                                                 build_number, "cucumber-html-reports")
                        build_steps = self._getScenResult(build_data, build_path)



                        LOGGER.debug("Build number is [%s]" %str(build_date))
                        LOGGER.debug("Build date is [%s]" %str(build_number))
                        LOGGER.debug("Build name is [%s]" %str(build_name))
                        LOGGER.debug("Build status is [%s]" %str(build_status))
                        LOGGER.debug("Build steps is [%s]" %(str(build_steps)))
                        LOGGER.debug("Build url is [%s]" %str(build_url))

                        self._updateBuildMap(diff_build_map, build_number, build_name, build_date, build_status, build_steps, build_url)

                        last_norunning_build_data.append(diff_build_map)

            last_build_data = sorted(last_norunning_build_data, key=lambda x:int(x['BuildID'][0]), reverse=True)
            self.saveCurrBuildData(last_build_data)
        else:
            LOGGER.info("There is no new build data")
            return_code = False
        
        LOGGER.debug("All build data : %s" %str(last_build_data))
        return (return_code, self._getSubCases(last_build_data))


class GenerateXML(object):
    
    def __init__(self, options):
        self.options = options
        self.prj_format = self.getPrjFormat()
        self.bc = BuildDataCollection(self.options, self.prj_format)

    def getPrjFormat(self):
        if self.options.prj_type == "gi":
            return PRJ1_FORMAT
        elif self.options.prj_type == "hu":
            return PRJ2_FORMAT
        elif self.options.prj_type == "gm":
            return PRJ3_FORMAT

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

            # There are build data needed to update
            if self.options.prj_type == "gi":
                xml_name = "Prj1-Guest_Installation_%s%s.xml" %(self.testtype_full_name, prd_ver)
                xg = XMLForPrj1(name="Prj1 Guest Installation %s Test Result" %self.testtype_full_name,
                                prj_format=self.prj_format)
            elif self.options.prj_type == "hu":
                xml_name = "Prj2-Host_Upgrade_%s%s.xml" %(self.testtype_full_name, prd_ver)
                xg = XMLForPrj2(name="Prj2 Host Upgrade %s Test Result" %self.testtype_full_name,
                                prj_format=self.prj_format)
            else:
                xml_name = "Prj3-Guest_Migration_%s%s.xml"%(self.testtype_full_name, prd_ver)
                xg = XMLForPrj3(name="Prj3 Guest Migration %s Test Result" %self.testtype_full_name,
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


LOGGER = LoggerHandling(log_level=logging.DEBUG)

if __name__ == '__main__':
    pass
    #main()
    #param_opt = ParseCMDParamDEV()
    #options, _args = param_opt.parse_args()
    #GenerateXML(options)()
