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
	$go = 'del_group_machines';
	return require("index.php");
}

$name = request_str("group");
$group = Group::get_by_name($name);
$machines = $group->get_machines();
$perm=array('perm'=>'group_edit','url'=>'index.php?go=groups');
permission_or_disabled($perm);
if (request_str("submit")) {
	permission_or_redirect($perm);
	$machine_list = request_array("machine_list");
	if (is_null($machine_list)) {
		$error = "No groups selected.";
	} else {
		$failed = 0;

		$machine_num = count($machine_list);

		$search = new MachineSearch();
		$search->filter_in_array($machine_list);
		$machines = $search->query();

		foreach ($machines as $machine) {
			if (!$group->del_machine($machine)) {
				$failed++;
			}
		} //end of foreach
	}
	if (empty($error)) {
		if ($failed) {
			$error = $failed . " machine(s) could not be deleted (possibly were not member?)";
		}
		$go = "groups";
		return require('inc/groups.php');
	}
}

$html_title = "Remove from group";
?>
