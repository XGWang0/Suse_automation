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
