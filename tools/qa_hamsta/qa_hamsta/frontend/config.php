<?php
/* ****************************************************************************
  Copyright © 2011 Unpublished Work of SUSE. All Rights Reserved.
  
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
 */

# Database login

define("PDO_DATABASE", "mysql:host=localhost;dbname=hamsta_db");
#define("PDO_DATABASE", "mysql:dbname=hamsta_db");
define("PDO_USER", "hwdb");
define("PDO_PASSWORD", "");

# Master connection

define ("CMDLINE_HOST", "localhost");
define ("CMDLINE_PORT", "18431");

# Directories with XML files - first is system path, second is web path
define ("XML_DIR", "/usr/share/hamsta/xml_files" );
define ("XML_WEB_DIR", "/xml_files" );
define ("XML_MULTIMACHINE_DIR", XML_DIR."/multimachine");
define ("XML_MULTIMACHINE_WEB_DIR", XML_WEB_DIR."/multimachine");
define ("XML_VALIDATION", "/usr/share/hamsta/xml_files/Validation_test.xml" );

# Please modify following lines according to your local. This is used for reinstall repo/sdk url drop down list

# CN repo. (default)
define ("REPO_INDEX_URL", "http://147.2.207.242/repo-index/cn.repo.json");
define ("SDK_INDEX_URL", "http://147.2.207.242/repo-index/cn.sdk.json");

# US repo.
#define ("REPO_INDEX_URL", "http://147.2.207.242/repo-index/us.repo.json");
#define ("SDK_INDEX_URL", "http://147.2.207.242/repo-index/us.sdk.json");

# CZ repo.
#define ("REPO_INDEX_URL", "http://qadb.suse.de/hamsta/cz.repo.json");
#define ("SDK_INDEX_URL", "http://qadb.suse.de/hamsta/cz.sdk.json");

# DE repo.
#define ("REPO_INDEX_URL", "http://147.2.207.242/repo-index/de.repo.json");
#define ("SDK_INDEX_URL", "http://147.2.207.242/repo-index/de.json");

# Validation test machine and URL setting, must use **IP address** in vmlist value.
$vmlist=array("i386"=>"147.2.207.49", "x86_64"=>"147.2.207.119", "ia64"=>"N/A", "s390x"=>"N/A", "ppc64"=>"N/A", "x86-xen"=>"147.2.207.44", "x86_64-xen"=>"147.2.207.151"); 

# Hidden fields
# select 0+ from: 'hostname','status_string','used_by','usage','group','product','architecture','architecture_capable','kernel','cpu_numbers','memory_size','disk_size','cpu_vendor','affiliation','ip_address','maintainer_string','notes','unique_id','serialconsole','powerswitch','role','type','vh'
$fields_hidden=array('unique_id','disk_size');

# Define the test suite list. TS=Test Suites, AT=AutoTest, AR=AdditionalRPMs
define ("TSLIST", "qa_test_bonnie qa_test_dbench qa_test_libmicro qa_test_ltp qa_test_memeat qa_test_memtester qa_test_netperf qa_test_newburn qa_test_apache_testsuite qa_test_apparmor qa_test_bash qa_test_bind qa_test_bzip2 qa_test_cabextract qa_test_clamav qa_cluster qa_test_coreutils qa_test_cpio qa_test_cracklib qa_test_evince qa_test_evolution qa_test_fetchmail qa_test_findutils qa_test_firefox qa_test_fs_stress qa_test_ftpload qa_test_gzip qa_test_indent qa_test_iosched qa_kotd qa_test_logrotate qa_lsb qa_test_lvm2 qa_test_net-snmp qa_test_nfs qa_test_openssh qa_phonorix qa_test_php5 qa_test_php5-server qa_test_postfix qa_test_process_stress qa_test_samba qa_sap qa_test_sched_stress qa_test_sharutils qa_test_siege qa_test_stress qa_test_tomboy qa_test_yast2 qa_test_zypper qa_test_reaim qa_test_sysbench qa_test_tiobench qa_test_gnome");
#define ("ATLIST", "aborttest aio_dio_bugs aiostress barriertest bash_shared_mapping btreplay cerberus compilebench cpu_hotplug cyclictest dacapo dbt2 disktest dma_memtest ebizzy fsdev fsfuzzer fs_mark fsstress fsx hackbench hwclock iosched_bugs iozone ipv6connect isic kernelbuild kvm kvmtest libhugetlbfs linus_stress lsb_dtk ltp memory_api monotonic_time npb parallel_dd perfmon pi_tests pktgen posixtest qemu_iotests real_time_tests rmaptest rttester scrashme selftest signaltest sleeptest sparse spew stress synctest systemtap tbench tsc uptime xmtest");
define ("ATLIST", "iozone sleeptest posixtest aiostress bonnie cerberus disktest");
define ("ARLIST", "python iftop git tclx");

# Fields shown in the machine listing by default  
#$display_fields=array("status_string", "used_by", "usage", "product", "architecture_capable", "kernel", "type");

# Define typic install mode patterns
$default_gnome_pattern = array("desktop-base", "apparmor", "desktop-gnome", "documentation", "x11");
$default_kde_pattern = array("desktop-base", "apparmor", "desktop-kde", "desktop-kde3", "desktop-kde4", "documentation", "x11");

# Define PXE server address
# CN PXE server
$pxeserver="147.2.207.240";

# CZ PXE server
#$pxeserver="10.20.136.1";

# DE PXE server
#$pxeserver="10.10.136.1";


# CN SMT server
#$smtserver="https://147.2.207.207/center/regsvc";

# Sane default SMT server
$smtserver="https://smt.novell.com/center/regsvc";

?>
