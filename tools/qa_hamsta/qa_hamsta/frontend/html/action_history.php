<?php
	/**
	 * Contents of the <tt>action_history</tt> page
	 */
	if (!defined('HAMSTA_FRONTEND')) {
		$go = 'action_history';
		return require("index.php");
	}

	echo "<script src=\"js/filter_log.js\"></script>\n";
	echo "<h2 class=\"text-medium text-blue bold\">Complete machine action history for " . $machine->get_hostname() . "</h2>";

	if($machine_logs_number == 0) {

		echo "<div class=\"text-main\">There are no log entries to show.</div>";

	} else {
		echo "<div id=\"log_filter\"></div>\n";
		echo "<table class=\"list text-main\" id=\"machine_log\">\n";
		echo "<tr>";
		echo "<th>Date/Time</th>";
		echo "<th>Type</th>";
		echo "<th style=\"width: 600px;\">Action</th>";
		echo "</tr>\n";
		
		foreach ($machine_logs as $logEntry) {
			$cls = sprintf("class=\"%s\"", $logEntry->get_log_type());
			echo "<tr $cls>";
			echo "<td>" . $logEntry->get_log_time() . "</td>";
			echo "<td>" . $logEntry->get_log_type() . "</td>";
			echo "<td>" . ($logEntry->get_log_user() == "" ? "ANONYMOUS" : htmlspecialchars($logEntry->get_log_user())) . " " . htmlspecialchars($logEntry->get_log_text()) . "</td>";
			echo "</tr>\n";		
		}
		echo "<script language=\"JavaScript\"><!--\n filter_init(\"machine_log\",\"log_filter\",0);\n --></script>\n";
	}
	
	if($machine_logs_number != 0) {
		echo "</table>";
	}

?>
