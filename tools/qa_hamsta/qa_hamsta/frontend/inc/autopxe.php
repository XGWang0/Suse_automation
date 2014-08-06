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
    $go = 'autopxe';
    return require("../index.php");
}

/* First check if the user has privileges to run this functionality. */
permission_or_disabled(array('perm'=>'autopxe_start'));

$search = new MachineSearch();
$search->filter_in_array(request_array("a_machines"));
$machines = $search->query();

if (request_str("submit")) {
	permission_or_redirect(array('perm'=>'autopxe_start'));
	$repourl = request_str("repourl");
	$type = request_str("type");
	$address = request_str("address");
	$is_hamsta = request_str("hamsta");
	if(empty($is_hamsta)) $is_hamsta = 'off';	
	$host_loop = request_str("loopback");
	if(empty($host_loop)) $host_loop = 'off';
	$cmd = 'sudo ssh -o StrictHostKeyChecking=no rd-qa@'.$config->pxeserver." \"autopxe.pl $repourl $type $address $is_hamsta $host_loop 1>/dev/null \"";

	system($cmd, $ret);
	$errors = array();

	switch ($ret) {
	case 0:
		$_SESSION['message'] = "AutoPXE configuration succeeded. Please network boot the server with $type '$address'"
				. " within 5 minutes to initiate an automated installation.";
		$_SESSION['mtype'] = "success";
		break;
	case 10:
		$errors['warning'] = "AutoPXE configuration warning. The AutoPXE configuration was a success (you do not need to run it again), however the 'atd' service was not loaded on your PXE server, which means that the automatic cleanup of the AutoPXE files will not happen. To fix this, please enable 'atd' on the PXE server (rcatd start; chkconfig atd on).";
		error_log ("autopxe.pl script reports 'atd' serviced not running (return code $ret)");
		break;
	case 20:
		$errors['creation'] = "AutoPXE configuration failed. Reason: the PXE file could not be created. Please file a bug or contact the automation team (qa-automation@suse.de) with the text of this error message.";
		error_log ("autopxe.pl reports it can not create PXE file (return code $ret). Command: $cmd");
		break;
	default:
		$errors['unknown'] = "AutoPXE configuration failed. Reason unknown (exit code ".$ret."). Please contact the automation team (qa-automation@suse.de) with the text of this error message. Note that AutoPXE works only in local QA subnet.";
		error_log ("autopxe.pl failed (return code $ret). Command: $cmd");
	}

	if (count($errors) != 0) {
		$_SESSION['message'] = implode("\n", $errors);
		$_SESSION['mtype'] = "fail";
	}
}

$html_title = "AutoPXE";
?>
