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
 * Logic of the delete_groups page
 *
 * Deletes the group if the form has been confirmed.
 */
if (!defined('HAMSTA_FRONTEND')) {
	$go = 'delete_groups';
	return require("index.php");
}

$group = Group::get_by_name(request_str("group"));
$perm=array('perm'=>'group_delete','url'=>'index.php?go=groups');
permission_or_disabled($perm);
if (request_int("confirmed")) {
	permission_or_redirect($perm);
	$group->delete();

	/* Try to get a session namespace to store the field values
	 * for displayed machines. */
	try
	{
		$ns_machine_filter = new Zend_Session_Namespace ('machineDisplayFilter');
	}
	catch (Zend_Session_Exception $e)
	{
		/* This is unfortunate. Might be caused by disabled cookies
		 * or some fancy browser. */
		$ns_machine_filter = null;
	}

	/* Remove the [machines page] filter of this group because it
	 * was deleted. */
	if (isset ($ns_machine_filter)
		&& isset ($ns_machine_filter->fields['group'])
		&& $ns_machine_filter->fields['group'] == $group->get_name ())
	{
		unset ($ns_machine_filter->fields['group']);
	}

	$go = "groups";
	return require('inc/groups.php');
}

$html_title = "Delete Group ".$group->get_name();
?>
