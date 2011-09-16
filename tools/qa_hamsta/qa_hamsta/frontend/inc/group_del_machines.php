<?php
    /**
     * Logic of the group_del_machines page
     */
    if (!defined('HAMSTA_FRONTEND')) {
        $go = 'group_del_machines';
        return require("index.php");
    }

    $search = new MachineSearch();
    $search->filter_in_array(request_array("a_machines"));
    $machines = $search->query();
    
    if (request_str("submit")) {
		$machine_group_pairs = request_array("a_groups");// pair like: $machineID_$groupID
		if (is_null($machine_group_pairs)) {
			$error = "No groups selected.";
		} else {
			$failed = 0;
			foreach ($machine_group_pairs as $pair) {
				list($machine_id, $group_id) = split ("_",$pair);
				$group = Group::get_by_id($group_id);
				$machine = Machine::get_by_id($machine_id);
				if (!$group->del_machine($machine)) {
					$failed++;
				}
			}//end of foreach
		}//end of (is_null($machine_group_pairs) else
        if (empty($error)) {
            if ($failed) {
                $error = $failed . " machine(s) could not be deleted (possibly were not member?)";
            }
            $go = "groups";
            return require('inc/groups.php');
        }//end of empty($error)
    }//end of if (request_str("submit"))

    $html_title = "Remove from group";
?>
