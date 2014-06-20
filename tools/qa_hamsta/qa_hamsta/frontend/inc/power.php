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
     * Logic of the powercycling functions
     *
     * Starts or stops selected machine (via powerswitch or hardware management console)
     */
    if(!defined('HAMSTA_FRONTEND')) {
        $go = 'power';
        return require("index.php");
    }

    $html_title = "Start/Stop/Restart machine";

    $allmachines = request_array("a_machines");
    machine_permission_or_redirect ($allmachines,
				    array ('owner' => 'machine_powerswitch',
					   'other' => 'machine_powerswitch_reserved',
					    'errmsg' => 'You have to be logged in and have privileges to use power.'));

    if (request_str("action") == "start") {
	foreach ($allmachines as $machine_id) {
		$machine = Machine::get_by_id($machine_id);
		$result = $machine->start_machine();
		}
	}
    else if (request_str("action") == "restart") {
	foreach ($allmachines as $machine_id) {
		$machine = Machine::get_by_id($machine_id);
		$result = $machine->restart_machine();
		}
	}

    else if (request_str("action") == "stop") {
	foreach ($allmachines as $machine_id) {
		$machine = Machine::get_by_id($machine_id);
		$result = $machine->stop_machine();
		}
	}

?>
