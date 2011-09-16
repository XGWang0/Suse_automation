<?php
	/**
	 * Logic of the action history page
	 */
	if (!defined('HAMSTA_FRONTEND')) {
		$go = 'action_history';
		return require("index.php");
	}

	$machine = Machine::get_by_id(request_int("id"));

	$machine_logs = $machine->get_log_entries($machine->get_id());
	$machine_logs_number = count($machine_logs);

	$html_title = "Action History";

?>
