<?php
/* ****************************************************************************
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
	$sutname = request_str("sutname");
	$rootpwd = request_str("rootpwd");
	$mailto = request_str("mailto");
	$master_ip = $_SERVER['SERVER_ADDR'];

	# Save errors here
	$errors = array();

	$sshpass_cmd = sprintf ('sshpass -p "%s"', $rootpwd);
	$addsut_path = '/usr/share/qa/tools/addsut.pl';
	$ssh_options = 'StrictHostKeyChecking=no';

	# Copy the executable to the host machine
	$scp_cmd = "scp -o $ssh_options $addsut_path root@$sutname:/tmp/";
	$cmd = escapeshellcmd ($sshpass_cmd . ' ' . $scp_cmd);
	system ($cmd, $ret);

	# In case of success, the command is executed, otherwise an error is reported
	if ( $ret != 0 ) {
		$errors['fail'] = "Can not scp to $sutname. Check the ssh service.";
	} else {
		$repo_url = `/usr/share/qa/tools/get_qa_config install_qa_repository`;
		$repo_url = rtrim($repo_url);
		$master_net = `/usr/share/qa/tools/get_net_addr.pl`;
		$ssh_cmd = "ssh -o $ssh_options root@$sutname /tmp/addsut.pl"
			. " $master_ip $master_net $repo_url";
		$cmd = escapeshellcmd ($sshpass_cmd . ' ' . $ssh_cmd);
		$conn_type = system ($cmd);

        	if ( $conn_type != 'unicast' && $conn_type != 'multicast' ) {
			$errors['sutfail'] = $conn_type;
		} else {
			# Remove the binary from temporary location
			$ssh_cmd = "ssh -o $ssh_options root@$sutname rm /tmp/addsut.pl";
			$cmd = escapeshellcmd ($sshpass_cmd . ' ' . $ssh_cmd);
			system ($cmd);
		}
	}

	if (count($errors)==0) {
		$_SESSION['message'] = "$sutname is connected by $conn_type";
		$_SESSION['mtype'] = "success";
		$mailsub = "\"Add SUT: $sutname to master: $master_ip success\"";
	} else {
		$_SESSION['message'] = implode("\n", $errors);
		$_SESSION['mtype'] = "fail";
		$mailsub = "\"Add SUT: $sutname to master: $master_ip failed\"";
	}

	if (!empty($mailto)) {
		$mailtext = "\"".$_SESSION['message']."\"";
		system("echo $mailtext | mailx $mailto -s $mailsub -r hamsta-master@suse.de");
	}
}
$html_title = "Add SUT";
?>
