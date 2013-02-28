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
 * Logic of the create_group page
 *
 * Get all machines that should be used for the creation of a new group
 * and create this group, if the form was submitted.
 */
if (!defined('HAMSTA_FRONTEND')) {
	$go = 'create_group';
	return require("index.php");
}

$submit=request_str('submit');
$action=request_str('action');

$perm=array('perm'=>'group_create','url'=>'index.php?go=create_group');
#permission_or_disabled($perm);

# fetch machines
$machines=array();
if( $action=='create_group' || $action=='addmachine' )	{
	$a_machines = request_array("a_machines");
	# See if this is an edit or an add
	if( $action=='create_group' && !$a_machines )	{
		redirect(array('errmsg'=>"You need to select at least one machine"));
	}
	$search = new MachineSearch();
	if($a_machines != NULL)
		$search->filter_in_array($a_machines);
	else
		$search->filter_role('SUT');
	$machines = $search->query();
}

$id=request_str('id');
$name_got=request_str('name');
$desc_got=request_str('desc');
if( $id)	{
	$group=Group::get_by_id($id);
	if($group == null)
		error_redirect('Unable to retrieve group data. Please try again.');
	$name=$group->get_name();
	$desc=$group->get_description();
}


if ($submit) {
	switch($action) {
	case "add": 		# new empty group
	case "create_group":	# new group with machines
		if(!$name_got){
			$error = "You must enter a group name.";
			break;
		}

#		permission_or_redirect($perm);
		$groupCreateResult = Group::create($name_got, $desc_got, $machines);
		if($groupCreateResult == -2)
			$error='There is already a group with that name! Please try again.';
		else if($groupCreateResult < 0)
			$error='There was an unknown error creating the group. Please try again.';
		else
			store_success('Group created!');
		break;

	case "edit":		# edit name + desc
		if( !strlen($name_got) )	{
			$error='You must enter a group name.';
			break;
		}
		# Make sure this is a valid group before proceeding
		if($group == null)
			error_redirect('Group does not exist');
		if (!$name_got) {
			$error="You must enter a group name.";
			break;
		}
		$groupCreateResult = $group->edit($name_got, $desc_got);
		if($groupCreateResult == -2)
			$error='There is another group with that name! Please try again.';
		else if($groupCreateResult < 0)
			$error='There was an unknown error editing the group. Please try again.';
		else	{
			store_success('Group modified!');
			# Try to get a session namespace to store the field values
			# for displayed machines. This is needed to update filter on
			# List Machines page. 
			try	{
				$ns_machine_filter = new Zend_Session_Namespace ('machineDisplayFilter');
				if ( isset ($ns_machine_filter->fields['group'])
					&& $ns_machine_filter->fields['group'] == $name )	{
						$ns_machine_filter->fields['group'] = $name_got;
					}
			}	
			catch (Zend_Session_Exception $e)	{
			}
		}
		break;

	case "addmachine":	# add machines to group
		if (is_null($group)) 
			error_redirect("The selected group for adding the machine(s) to does not exist.");
		$failed=0;
		foreach($machines as $machine) {
			if (!$group->add_machine($machine)) {
				$failed++;
			}
		}
		if ($failed)
			error_redirect($failed . " machine(s) could not be added (possibly were already member?)");
		break;
	}

	if (empty($error)) {
		$go = "groups";
		return require('inc/groups.php');
	}
}

$html_title = "Add to group";

function error_redirect($text)
{
	redirect(array('errmsg'=>$text,'url'=>'index.php?go=groups'));
}

function store_success($text)
{
	$_SESSION['mtype']='success';
	$_SESSION['message']=$text;
}

?>
