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
    $go = 'autopxe';
    return require("../index.php");
}

/* First check if the user has privileges to run this functionality. */
if ( User::isLogged () && User::isRegistered (User::getIdent (), $config) )
  {
    $user = User::getInstance ($config);
    if ( ! $user->isAllowed ('autopxe_start') )
      {
        Notificator::setErrorMessage ("You do not have privileges to use AutoPXE.");
        header ("Location: index.php");
        exit ();
      }
  }
else
  {
    Notificator::setErrorMessage ("You have to logged in and registered to use AutoPXE.");
    header ("Location: index.php");
    exit ();
  }

$search = new MachineSearch();
$search->filter_in_array(request_array("a_machines"));
$machines = $search->query();

if (request_str("submit")) {
	$repourl = request_str("repourl");
	$type = request_str("type");
	$address = request_str("address");
	$is_hamsta = request_str("hamsta");
	$cmd = 'sudo ssh -o StrictHostKeyChecking=no rd-qa@'.$pxeserver." \"autopxe.pl $repourl $type $address $is_hamsta 1>/dev/null \"";
	system($cmd, $ret);
	$errors = array();
	if ($ret == 0) {
		$_SESSION['message'] = "AutoPXE configuration was a success! Please network boot the server with ".$type." '".$address."'"." within 5 minutes to initiate an automated installation.";
		$_SESSION['mtype'] = "success";
	} else if ($ret == 255) {
		$errors['autopxepl'] = "AutoPXE configuration failed! Reason: autopxe.pl usage was incorrect. Please contact the automation team (qa-automation@suse.de) with the text of this error message.";
	} else if ($ret == 10) {
		$errors['warning'] = "AutoPXE configuration warning! The AutoPXE configuration was a success (you do not need to run it again), however the 'atd' service was not loaded on your PXE server, which means that the automatic cleanup of the AutoPXE files will not happen. To fix this, please enable 'atd' on the PXE server (rcatd start; chkconfig atd on).";
	} else if ($ret == 20) {
		$errors['creation'] = "AutoPXE configuration failed! Reason: the PXE file could not be created. Please file a bug or contact the automation team (qa-automation@suse.de) with the text of this error message.";
	} else {
		$errors['unknown'] = "AutoPXE configuration failed! Reason: Unknown (exit code ".$ret."). Please contact the automation team (qa-automation@suse.de) with the text of this error message.";
	}
	if (count($errors) != 0) {
		$_SESSION['message'] = implode("\n", $errors);
		$_SESSION['mtype'] = "fail";
	}
}

$html_title = "AutoPXE";
?>
