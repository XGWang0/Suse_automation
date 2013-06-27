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
	 * Logic of the machine_edit page 
	 *
	 * Gets all selected machines and updates their status if requested.
	 */

if (!defined('HAMSTA_FRONTEND')) {
	$go = 'machine_edit';
	return require("index.php");
}

require_once ('lib/MachineEditController.php');

$edit_fields = array('used_by'			=> 'Reservations',
		     'usage'			=> 'Usage',
		     'maintainer_string'	=> 'Maintainer',
		     'anomaly'			=> 'Notes',
		     'powerswitch'		=> 'Power Switch',
		     'powertype'		=> 'Power Type',
		     'powerslot'		=> 'Power Slot',
		     'serialconsole'		=> 'Serial Console',
		     'consoledevice'		=> 'Console Device',
		     'consolespeed'		=> 'Console Speed',
		     'consolesetdefault'	=> 'Enable Console',
		     'affiliation'		=> 'Affiliation');

$allmachines = request_array("a_machines");

$search = new MachineSearch();
$search->filter_in_array(request_array("a_machines"));
$machines = $search->query();

$mecontroller = new MachineEditController ($machines, $edit_fields);

/* Verify user has rights to modify the machine. */
$perm=array('owner'=>'machine_edit','other'=>'machine_edit_reserved');
machine_permission_or_disabled($allmachines,$perm);

/* Remove reservation for logged in user. */
if (request_str("action") == "clear") {
	$mecontroller->processRequest ('clear');
	header ('Location: index.php');
	exit ();
} else if (request_str ('submit')) {
	machine_permission_or_redirect($allmachines,$perm);
	$mecontroller->processRequest ('submit');
}

$html_title = "Edit machines";

?>
