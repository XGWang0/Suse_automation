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
 * Logic of the reinstall page 
 */
if (!defined('HAMSTA_FRONTEND')) {
	$go = 'addsut';
	return require("index.php");
}

/* Check if user is logged in + registered. */
permission_or_disabled();

# Procee the request
if (request_str("proceed")) {
	permission_or_redirect();
	# Request parameters
	//$hostnametype = request_str("hostnametype");
	$sutname = request_str("sutname");
	$rootpwd = request_str("rootpwd");
	$mailto = request_str("mailto");
	$conn_type = 'multicast';
	$repos = array(
			"SLE_10_SP1" => "SLE_10_SP1_Head",
			"SLE_10_SP2" => "SLE_10_SP2_Head",
			"SLE_10_SP3" => "SLE_10_SP3",
			"SLE_10_SP4" => "SLE_10_SP4",
			"SLE_10_SP4_Update" => "SLE_10_SP4_Update",
			"SLE_11_SP1_Update" => "SLE_11_SP1_Update",
			"SLE_Factory" => "SLE_Factory",
			"Factory_Head" => "SUSE_Factory_Head",
			"SLE_11_SP1" => "SUSE_SLE-11-SP1_GA",
			"SLE_11_SP2" => "SUSE_SLE-11-SP2_GA",
			"SLE_11_SP3" => "SUSE_SLE-11-SP3_GA",
			"SLE_11" => "SUSE_SLE-11_GA",
			"SLE_11_Update" => "SUSE_SLE-11_Update",
			"openSUSE_11.4" => "openSUSE_11.4",
			"openSUSE_12.1" => "openSUSE_12.1",
			"openSUSE_12.2" => "openSUSE_12.2",
			"openSUSE_Factory" => "openSUSE_Factory");

	# Check for errors
	$errors = array();
	# Processing the job
	$cmd = "sshpass -p \"$rootpwd\" ssh -o StrictHostKeyChecking=no root@$sutname ";
	$mycmd = $cmd . "\"grep -qi openSUSE /etc/issue\"";
	system($mycmd, $ret);
	if ($ret != 0) { //SLE
		$repo = "SLE_";
		$mycmd = $cmd . "\"grep -i VERSION /etc/SuSE-release | sed -e 's/[A-Za-z =]//g'\"";
		$OSVer = system($mycmd, $ret);
		$mycmd = $cmd . "\"grep PATCHLEVEL /etc/SuSE-release | sed -e 's/[A-Za-z= ]//g'\"";	
		$PVer = system($mycmd, $ret);
		if ($ret == 0) { // OS like: SLE_11_SP2 etc
			$repo .= $OSVer . "_SP" . $PVer;
		} else {
			$repo .= $OSVer;
		}
	} else {
		$repo = "openSUSE_";
		$mycmd = $cmd . "\"cat /etc/SuSE-release | grep -i VERSION | sed -e 's/[A-Za-z =]//g'\"";
		$OSVer = system($mycmd);
		$repo .= $OSVer;
	}
	$repo_url = `/usr/share/qa/tools/get_qa_config install_qa_repository`;
	$repo_url = rtrim($repo_url) . "/" . $repos[$repo] . "/";
	$mycmd = $cmd . " zypper --no-gpg-checks -n ar $repo_url hamsta 1>/dev/null";
	system($mycmd, $ret);
	if ($ret != 0) {
		$errors["repo_add"] = "Cannot add hamsta repo as $repo_url to SUT.";
	}
	$mycmd = $cmd . " zypper --no-gpg-checks --gpg-auto-import-keys in -y qa_hamsta 1>/dev/null";
	system($mycmd, $ret);
	if ($ret != 0) {
		$errors["hamsta_inst"] = "qa_hamsta cannot be added to SUT.";
	}
	$mycmd = $cmd . " /usr/share/qa/tools/get_net_addr.pl";
	$sut_net_addr = system($mycmd);
	$master_ip = $_SERVER['SERVER_ADDR'];
	if ( $sut_net_addr != system("/usr/share/qa/tools/get_net_addr.pl") ) {
		$mycmd =$cmd . "\"sed -i s/hamsta_multicast_address=\'239.192.10.10\'/hamsta_multicast_address=\'$master_ip\'/ /etc/qa/00-hamsta-common-default\"";
		system($mycmd, $ret);
		$conn_type = 'unicast';
		if ($ret != 0) {
			$errors["unicast"] = "config unicast failed.";
		}
	}
	$mycmd = $cmd . "rchamsta start";
	system($mycmd, $ret);
	if ($ret != 0) {
		$errors["hamsta_start"] = "Cannot start hamsta service on SUT.";
	}
	if (count($errors)==0) {
		$_SESSION['message'] = "$sutname is connected by $conn_type";
		$_SESSION['mtype'] = "success";
		$mailsub = "\"Add SUT:$sutname to master:$master_ip success\"";
	} else {
		$_SESSION['message'] = implode("\n", $errors);
		$_SESSION['mtype'] = "fail";
		$mailsub = "\"Add SUT:$sutname to master:$master_ip failed\"";
	}
	if (!empty($mailto)) {
		$mailtext = "\"".$_SESSION['message']."\"";
		system("echo $mailtext | mailx $mailto -s $mailsub -r hamsta-master@suse.de");
	}
}
$html_title = "Add_SUT";
?>
