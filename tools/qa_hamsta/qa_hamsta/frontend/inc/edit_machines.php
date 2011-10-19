<?php
/* ****************************************************************************
  Copyright © 2011 Unpublished Work of SUSE. All Rights Reserved.
  
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
	$edit_fields = array('used_by', 'expires', 'usage','busy','maintainer_string','anomaly','powerswitch','serialconsole','consoledevice','consolespeed','consolesetdefault','affiliation');
	$allmachines = request_array("a_machines");
    if (!defined('HAMSTA_FRONTEND')) {
        $go = 'edit_machines';
        return require("index.php");
    }
    if(request_str("action") == "clear") {
		foreach($allmachines as $machine_id) {
			$machine = Machine::get_by_id($machine_id);
			$machine->set_used_by("");
			$machine->set_expires(NULL);
			$machine->set_reserved(NULL);
			$machine->set_usage("");
			$machine->set_consolesetdefault(0);
			Log::create($machine->get_id(), $machine->get_used_by(), 'RELEASE', "has unreserved this machine");
		}
		$go = "machines";
	return require('inc/machines.php');
	}
	else if (request_str("submit")) {
		$errors = array();
		$input = request_array('expires');
		foreach ($input as $value) {
			$expires = $value;
		}
		$input = request_array('used_by');
		foreach ($input as $value) {
			$used_by = $value;
		}
		$input = request_array('usage');
		foreach ($input as $value) {
			$usage = $value;
		}
		if ($expires != '' && $used_by == '') {
			$errors['usedby'] = "Expires cannot be set without Used by set.";
		}
		if ($usage != '' && $used_by == '') {
			$errors['usage'] = "Usage cannot be set without Used by set.";
		}
		if ($expires == '0') {
			$errors['expires'] = "Expires cannot be 0.";
		}
		if (!is_numeric($expires)) {
			$errors['expires'] = "Expires must be numeric.";
		}
		if (count($errors) == 0) {
		foreach ($allmachines as $machine_id) {
	    		$machine = Machine::get_by_id($machine_id);
	    		$machine->set_consolesetdefault(0);
		}
		foreach ( $edit_fields as $row) {
			$input = request_array($row);
			foreach ($input as $machine_id => $r_value) {
				$machine = Machine::get_by_id($machine_id);
				$sfunc = "set_" . $row;
                $machine->$sfunc($r_value);
                if($r_value == "") {
                    Log::create($machine->get_id(), $machine->get_used_by(), 'RELEASE', "has cleared the $row field");
                } else {
                    Log::create($machine->get_id(), $machine->get_used_by(), 'CONFIG', "has set the $row as $r_value");
                }
            }
        }

        $default_options = request_array("default_options");
        foreach ($default_options as $machine_id => $default_option_per_machine) {
            $machine = Machine::get_by_id($machine_id);
            if ($machine->get_def_inst_opt() != trim($default_option_per_machine)) {
                $machine->set_def_inst_opt(trim($default_option_per_machine));
                Log::create($machine->get_id(), $machine->get_used_by(), 'CONFIG', "has set the default install options to \"$default_option_per_machine\"");
            }
        }
        $go = "machines";
		header("Location: index.php");
		} else {
			$_SESSION['message'] = implode("\n", $errors);
			$_SESSION['mtype'] = "fail";
		}
    }
    $search = new MachineSearch();
    $search->filter_in_array(request_array("a_machines"));
    $machines = $search->query();
    $html_title = "Edit machines";
?>
