<?php
/* ****************************************************************************
  Copyright (c) 2011 Unpublished Work of SUSE. All Rights Reserved.
  
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

    /**
     * Logic of the list_testcases page 
     *
     * Gets all selected machines and updates their status if requested.
     */
//error_reporting(E_ALL | E_STRICT);

     if (!defined('HAMSTA_FRONTEND')) {
        $go = 'edit_machines';
        return require("index.php");
    }

    mysql_connect("qa.suse.de", "pkirsch", "atacand")
        or die("Keine Verbindung möglich: " . mysql_error());
	mysql_select_db("qadb");

	// get all available testsuites
	$result_testsuitenames = mysql_query("select testsuitename from testsuites order by testsuiteID;");

	$torun = array();

	if(isset($_POST['runthem'])) {
		echo "create Job for Groups: <br>";
		$runthem=$_POST['runthem'];
		// print_r($runthem);
		// search now for the special test
// Hint: i need the ltp-ctcs2-glue rpm paket for obtaining the tcf files
		if (file_exists("./inc/all_tcf")) {
		// first try: searching for a whole tcf file
			foreach ($runthem as $item) {
				$return= array();
				exec("grep $item ./inc/all_tcf",$return);
				// run the CTCS2 File
				foreach ($return as $v) {
					$v = preg_replace('/\/usr/',' ./tools/run /usr',$v);
					array_push ($torun, $v);
				}
			}
		}
	}	
	if(isset($_POST['runthem_testcase'])) {
		echo "create Job for Testcases: <br>";
		$runthem=$_POST['runthem_testcase'];
		// second try, searching for a special testcase
		if (file_exists("./inc/all_ltp")) {
			foreach ($runthem as $item) {
				$return=array();
				exec("grep $item ./inc/all_ltp",$return);
				// run the LTP File
				foreach ($return as $v) {
					$v = preg_replace('/\/usr/',' /usr/lib64/ltp/runalltests.sh -f /usr',$v);
					array_push ($torun, $v);
				}
			}

		
		} else {
			printf("ERROR: File not found 'all_ltp' or 'all_tcf', cannot create job file <br>");
		}
		
	}
	if(count($torun) > 0) {	
		// create a Job XML file 
		
		// valid skelett
		$skelett_1='<?xml version="1.0"?>
	<job>
        <config>
                <name>run special testcase</name>
                <debuglevel>10</debuglevel>
                <distributable>0</distributable>
                <parallel>0</parallel>
                <mail notify="0">pkirsch@suse.de</mail>
                <logdir>/tmp</logdir>
                <description>Special testcases/testsuites are running</description>
                <motd>Do not touch, special testsuites and testgroups are running. See http://qa/hamsta/ !</motd>
        </config>

        <commands>

                <!-- only one worker -->
                <worker>
                        <!-- Required -->
                        <command execution="forked">#!/bin/bash 
			cd /usr/lib/ctcs2 ';
		foreach ($torun as $v) {
			$skelett_1=$skelett_1."\n".$v;
		}
		$skelett_1=$skelett_1."\n".'</command>
                        <directory>/</directory>
                </worker>
        </commands>
</job>';
		//print_r($torun);
		$fh = fopen ("/tmp/HAMSTA_special_testcases.xml", "w+");	// no cool name :( guess no multi using :)
		fwrite($fh, $skelett_1);
		fclose($fh);
		printf("HAMSTA job xml file: /tmp/HAMSTA_special_testcases.xml created, now you can schedule it.");

	} else {  
	if(isset($_GET['show_testcases'])) {
		$show_testcases=$_GET['show_testcases'];
		echo "gesetzt mit $show_testcases <br>";
	// get all available testcases
		$result_testcases = mysql_query(" select tc.testcaseName  from testcases tc, test_result tr, tcf_results tcfr, tcf_group tcfg, testsuites ts  where tr.testcaseID=tc.testcaseID and tcfr.resultsID=tr.resultsID and tcfg.tcfID=tcfr.tcfID and ts.testsuiteid= tcfg.tcfnameID and ts.testsuiteName like '$show_testcases' group by tc.testcasename;");
		}
	}
    $html_title = "List testcases";
?>
