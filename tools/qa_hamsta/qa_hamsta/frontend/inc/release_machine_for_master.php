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

if (!defined('HAMSTA_FRONTEND')) {
	return require("index.php");
}

$config = ConfigFactory::build();
$search = new MachineSearch ();
$search->filter_in_array (request_array("a_machines"));
$machines = $search->query ();

/* If authentication is not used, it is not possible to get the
 * user. */
if ($config->authentication->use) {
	$perm_release_master_reservation = array('owner'=>'release_machine_for_master','other'=>'release_machine_for_master_reserved');
	if (! machine_permission($machines,$perm_release_master_reservation)){
		Notificator::setErrorMessage ('You need to login or have enough permissions to release hamsta master reservation on machines.');
		header ('Location: index.php');
		exit ();
	}
}

# Here is when no authentication is used or authentication is passed with enough perm.
$names = array ();
$err_names = array ();
foreach ($machines as $machine) {
	if ($machine->send_master_release()) {
		$names[] = $machine->get_hostname();
	} else {
		$err_names[] = $machine->get_hostname();
		#$error = (empty($error) ? "" : $error) . "<p> ".$machine->get_hostname().": ".$machine->errmsg."</p>";
		$error = (empty($error) ? "" : $error) . $machine->get_hostname().": ".$machine->errmsg;
	}
}

$msg = '';
if (count ($names)) {
	$msg = 'These machines were succesfully released from hamsta master: ' . join (', ', $names) . '. ';
}
if (count ($err_names)) {
	if ($msg) {
		$msg .= ' ';
	}
	$msg .= 'Could not release from hamsta master machines: ' . join (', ', $err_names) . '. ';
}
if ($error) {
	$msg .= " $error";
}
if ($msg) {
	Notificator::setSuccessMessage ($msg);
}

header ('Location: index.php');
exit ();

?>
