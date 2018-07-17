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
     * Logic of the group_del_machines page
     */
    if (!defined('HAMSTA_FRONTEND')) {
        $go = 'group_del_machines';
        return require("index.php");
    }

    $search = new MachineSearch();
    $search->filter_in_array(request_array("a_machines"));
    $machines = $search->query();
    $perm=array('perm'=>'group_edit','url'=>'index.php?go=group_del_machines');
    permission_or_disabled($perm);
    if (request_str("submit")) {
	    permission_or_redirect($perm);
		$machine_group_pairs = request_array("a_groups");// pair like: $machineID_$groupID
		if (is_null($machine_group_pairs)) {
			$error = "No groups selected.";
		} else {
			$failed = 0;
			foreach ($machine_group_pairs as $pair) {
				list($machine_id, $group_id) = explode ("_",$pair);
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
