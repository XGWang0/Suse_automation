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
	# Check for errors
	$errors = array();
	# Processing the job
	$cmd = "sshpass -p \"$rootpwd\" scp /usr/share/qa/tools/addsut.pl root@$sutname:/tmp/";
	system($cmd,$ret);
	if ( $ret != 0 ) {
		$errors['fail'] = "Can not scp to $sutname";
	} else {
		$repo_url = `/usr/share/qa/tools/get_qa_config install_qa_repository`;
		$repo_url = rtrim($repo_url);
		$master_ip = $_SERVER['SERVER_ADDR'];
		$master_net = `/usr/share/qa/tools/get_net_addr.pl`;
		$cmd = "sshpass -p \"$rootpwd\" ssh -o StrictHostKeyChecking=no root@$sutname /tmp/addsut.pl $master_ip $master_net $repo_url";
		$conn_type = `$cmd`;
        	if ( $conn_type != 'unicast' && $conn_type != 'multicast' ) {
			$errors['sutfail'] = $conn_type;
		} else {
			system("sshpass -p \"$rootpwd\" ssh -o StrictHostKeyChecking=no root@$sutname rm /tmp/addsut.pl");
		}
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
$html_title = "Add SUT";
?>
