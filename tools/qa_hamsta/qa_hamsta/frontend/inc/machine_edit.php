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

$edit_fields = array('used_by'			=> 'Used By',
		     'expires'			=> 'Expires',
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

	if (!defined('HAMSTA_FRONTEND'))
	{
		$go = 'machine_edit';
		return require("index.php");
	}

	/* Verify user has rights to modify the machine. */
	$perm=array('owner'=>'machine_edit','other'=>'machine_edit_reserved');
	machine_permission_or_disabled($allmachines,$perm);
        /* If they are doing the shortcut field clearing */
	if (request_str("action") == "clear")
	{
		foreach ($allmachines as $machine_id)
		{
			$machine = Machine::get_by_id($machine_id);
			$used_by = $machine->get_used_by_login ();
			$machine->set_used_by(NULL);
			$machine->set_expires(NULL);
			$machine->set_reserved(NULL);
			$machine->set_usage("");
			Log::create($machine->get_id(), $used_by, 'RELEASE', "has unreserved this machine");
		}
		$go = "machines";
		return require('inc/machines.php');
	}

	# If they are trying to edit the machine settings
	# Keep in mind that there are potentially multiple machines being edited here
	else if (request_str("submit"))
	{
		machine_permission_or_redirect($allmachines,$perm);
		# First, check the data for errors
		$errors = array();

		# Check the expires, used_by and usage fields
		$expires_all = array_combine($allmachines, request_array('expires'));
		$used_by_all = array_combine($allmachines, request_array('used_by'));
		$usage_all = array_combine($allmachines, request_array('usage'));
		foreach ($allmachines as $machine_id)
		{
			$machine = Machine::get_by_id($machine_id);
			$name = $machine->get_hostname();
			$expires = $expires_all[$machine_id];
			$used_by = $used_by_all[$machine_id];
			$usage = $usage_all[$machine_id];
			if ($expires != '' && $used_by == '')
			{
				$errors['usedby_'.$machine_id] = $name.": Expires cannot be set without Used by set.";
			}
			if ($usage != '' && $used_by == '')
			{
				$errors['usage_'.$machine_id] = $name.": Usage cannot be set without Used by set.";
			}
			if ($expires == '0')
			{
				$errors['expires_'.$machine_id] = $name.": Expires cannot be 0.";
			}
			if ($expires != '' && !is_numeric($expires))
			{
				$errors['expires_num_'.$machine_id] = $name.": Expires must be numeric.";
			}
		}
		# If there are no errors, we go ahead and edit the machines
		if (count($errors) == 0)
		{
			foreach ($allmachines as $machine_id)
			{
				$machine = Machine::get_by_id($machine_id);
				$machine->set_consolesetdefault(0);
				#update perm here
                                $perms = request_array("perm_".$machine_id);
                                $perm_str="";
				if (count ($perms))
				  {
				    $perm_str = implode (",", $perms);
				  }
                                $machine->set_perm($perm_str);
			}
			foreach ( $edit_fields as $row => $label)
			{
				$input = request_array($row);
				foreach ($input as $machine_id => $r_value)
				{
					$machine = Machine::get_by_id($machine_id);
					if ($row == 'used_by') {
						$gfunc = "get_" . $row . "_login";
					} else {
						$gfunc = "get_" . $row;
					}
					$sfunc = "set_" . $row;

					$old_value = $machine->$gfunc ();
					$machine->$sfunc($r_value);

					if (strcmp ($old_value, $r_value)) {
						if (empty ($r_value)) {
							Log::create($machine->get_id(), $machine->get_used_by_login(), 'RELEASE', "has cleared the '$label' field");
						} else {
							Log::create($machine->get_id(), $machine->get_used_by_login(), 'CONFIG', "has set the value of '$label' to '$r_value'");
						}
					}
				}
			}

			$default_options = request_array("default_options");
			foreach ($default_options as $machine_id => $default_option_per_machine)
			{
				$machine = Machine::get_by_id($machine_id);
				if ($machine->get_def_inst_opt() != trim($default_option_per_machine))
				{
					$machine->set_def_inst_opt(trim($default_option_per_machine));
					Log::create($machine->get_id(), $machine->get_used_by_login(), 'CONFIG', "has set the 'Default Install Options' to '$default_option_per_machine'");
				}
			}
			Notificator::setSuccessMessage ('The requested actions were successfully completed.');
			$go = ($machine->get_role() == "VH") ? "qacloud" : "machine_edit";
		}
		
		# If there were errors, we set the fail message
		else
		{
			Notificator::setErrorMessage (implode("\n", $errors));
		}
   	}

	$search = new MachineSearch();
	$search->filter_in_array(request_array("a_machines"));
	$machines = $search->query();
	$html_title = "Edit machines";

?>

