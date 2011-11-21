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
	 * Logic of the edit_machines page 
	 *
	 * Gets all selected machines and updates their status if requested.
	 */

	$edit_fields = array('used_by', 'expires', 'usage','maintainer_string','anomaly','powerswitch','serialconsole','consoledevice','consolespeed','consolesetdefault','affiliation');
	$allmachines = request_array("a_machines");

	if (!defined('HAMSTA_FRONTEND'))
	{
		$go = 'edit_machines';
		return require("index.php");
	}

	# If they are doing the shortcut field clearing	
	if (request_str("action") == "clear")
	{
		foreach ($allmachines as $machine_id)
		{
			$machine = Machine::get_by_id($machine_id);
			$machine->set_used_by("");
			$machine->set_expires(NULL);
			$machine->set_reserved(NULL);
			$machine->set_usage("");
			Log::create($machine->get_id(), $machine->get_used_by(), 'RELEASE', "has unreserved this machine");
		}
		$go = "machines";
		return require('inc/machines.php');
	}

	# If they are trying to edit the machine settings
	# Keep in mind that there are potentially multiple machines being edited here
	else if (request_str("submit"))
	{
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
                                foreach ( $perms as $perm )
                                {
                                        $perm_str = $perm_str . ",$perm";
                                }
                                preg_replace("^.","",$perm_str);
                                $machine->set_perm($perm_str);
			}
			foreach ( $edit_fields as $row)
			{
				$input = request_array($row);
				foreach ($input as $machine_id => $r_value)
				{
					$machine = Machine::get_by_id($machine_id);
					$sfunc = "set_" . $row;
					$machine->$sfunc($r_value);
					if ($r_value == "")
					{
						Log::create($machine->get_id(), $machine->get_used_by(), 'RELEASE', "has cleared the $row field");
					}
					else
					{
						Log::create($machine->get_id(), $machine->get_used_by(), 'CONFIG', "has set the $row as $r_value");
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
					Log::create($machine->get_id(), $machine->get_used_by(), 'CONFIG', "has set the default install options to \"$default_option_per_machine\"");
				}
			}

			$go = "machines";
			header("Location: index.php");
		}
		
		# If there were errors, we set the fail message
		else
		{
			$_SESSION['message'] = implode("\n", $errors);
			$_SESSION['mtype'] = "fail";
		}
   	}

	$search = new MachineSearch();
	$search->filter_in_array(request_array("a_machines"));
	$machines = $search->query();
	$html_title = "Edit machines";

?>

