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
	 * Contents of the <tt>machine_details</tt> page  
	 */
if (!defined('HAMSTA_FRONTEND')) {
	$go = 'machine_details';
	return require("index.php");
}

?>
<script src="js/filter_log.js"></script>
<h2 class="text-medium text-blue bold">Machine overview</h2>
<table class="list text-main">
	<tr>
		<th>Element</th>
		<th>Value</th>
		<th>&nbsp;</th>
	</tr>
<?php
	$rh = new ReservationsHelper ($machine);
	foreach ($fields_list as $key=>$value) {
		$arr_res = array();
		$fstring = "get_".$key;
		$valuer = null;

		if (method_exists ($machine, $fstring)) {
			$valuer = $machine->$fstring();
		}

		if (isset ($valuer) && is_array($valuer)) { #get_group will return an array
			foreach ($valuer as $tmparr) 
				$arr_res[] = $tmparr[0];
			echo ("<tr><td>$value</td><td>");
			foreach ($arr_res as $res)
				echo "$res ";
			echo ("</td><td>");
			if(method_exists('MachineSearch',"filter_$key"))
				foreach ($arr_res as $res)
					echo ("<a href=index.php?go=machines&amp;".$key."=".urlencode($res).">Search_".$res."</a> ");
		} else {
			if (in_array ($key, array ('used_by', 'reserved'))) {
				echo ("<tr><td>$value</td><td>"
				      . $rh->printUsersToTable ()
				      ."</td><td>");
			} else {
				echo ("<tr><td>$value</td><td>$valuer</td><td>");
				if ($valuer != NULL && method_exists('MachineSearch',"filter_$key")) {
					echo("<a href=index.php?go=machines&amp;".$key."=".urlencode($valuer).">Search</a>");
				}
			}
		}
		echo "</td></tr>";
	}
?>
</table>			

<div style="margin-top: 6px; margin-left: 3px;">
	<span class="text-main text-blue bold" style="position: relative; bottom: 6px;">Actions: </span>

<?php print machine_icons($machine,$user); ?>
</div>

<h2 class="text-medium text-blue bold">Last jobs</h2>
<table class="list text-main" id="lastjobs">
	<thead>
	<tr>
		<th>ID</th>
		<th>Status</th>
		<th>Name</th>
		<th>Started</th>
		<th>Stopped</th>
		<th>Actions</th>
	</tr>
	</thead>

	<?php
		/* Get this machines last 10 jobs. */
		$last_jobs = $machine->get_all_jobs (10);
		foreach ($last_jobs as $job):
	?>
		<tr>
			<td><a href="index.php?go=job_details&amp;id=<?php echo($job->get_id()); ?>"><?php echo($job->get_id()); ?></a></td>
                        <td><span class="<?php echo($job->get_status_string()); ?>">
                                <?php echo($job->get_status_string()); ?></span>
			</td>
			<td><?php echo($job->get_name()); ?></td>
			<td><?php echo($job->get_started()); ?></td>
			<td><?php echo($job->get_stopped()); ?></td>
			<td>
		<?php
			if (isset ($user) && ! $job->is_finished ()) {
		?>
			<a href="index.php?go=job_details&amp;id=<?php echo($job->get_id()); ?>&amp;finished_job=1" class="text-main">Set finished</a>
		<?php
			}
			if (isset ($user) && $job->can_cancel ()) {
		?>
		    	<a href="index.php?go=jobruns&amp;action=cancel&amp;id=<?php echo($job->get_id()); ?>">Cancel</a>
		<?php
			}
		?>
		        </td>
		</tr>
		<?php endforeach; ?>

</table>

<a href="index.php?go=jobruns&amp;machine=<?php echo($machine->get_id()); ?>" class="text-small">Show complete list</a>
<?php 
	if( count ($last_jobs) > 0 && isset ($user) )	{
		echo '<p><a href="index.php?go=machine_purge&amp;id=' . $machine->get_id() . '&amp;purge=job">Purge job history</a></p>' . "\n";
	}
?>
<?php if ( isset($configuration) ) { ?>
<?php if($configuration->get_id() == $machine->get_current_configuration()->get_id()): ?>
	<h2 class="text-medium text-blue bold">Current configuration</h2>
<?php else: ?>
	<h2 class="text-medium text-blue bold">Configuration <?php echo($configuration->get_id()); ?></h2>
<?php endif; ?>
<table class="list text-main">
	<tr>
		<th>ID</th>
		<th colspan="2">Description</th>
		<th colspan="2">Driver</th>
	</tr>
	<?php foreach ($configuration->get_modules() as $module): ?>
		<tr
			<?php if($module->contains_text($highlight)): ?>
			class="search_result"
			<?php endif; ?>
		>
			<td><a href="index.php?go=module_details&amp;module=<?php echo($module->get_name()); ?>&amp;id=<?php echo($module->get_version()); ?>&amp;highlight=<?php echo($highlight); ?>"><?php echo($module->get_name()); ?></a></td>
			<td><?php echo($module->__toString()); ?></td>
			<td><a href="index.php?go=machines&amp;s_module=<?php echo(urlencode($module->get_name())); ?>&amp;s_module_description=<?php echo(urlencode($module->__toString())); ?>">Search</a></td>
			<td><?php echo($module->get_driver()); ?></td>
			<td><a href="index.php?go=machines&amp;s_module=<?php echo(urlencode($module->get_name())); ?>&amp;s_module_driver=<?php echo(urlencode($module->get_driver())); ?>">Search</a></td>
		</tr>
	<?php endforeach; ?>
</table>

<?php } else { ?>
      <h2 class="text-medium text-blue bold">Configuration not set</h2>
<?php } ?>

<h2 class="text-medium text-blue bold">Previous configurations</h2>
<form action="index.php?go=diff_config" method="post">
<table class="list text-main">
	<tr>
		<th>&nbsp;</th>
		<th>ID</th>
		<th>First online</th>
		<th>Last used</th>
	</tr>
	<?php	$configs=$machine->get_configurations(); 
		foreach ($configs as $configuration): ?>
		<tr>
			<td>
				<input type="radio" name="config1" value="<?php echo($configuration->get_id()); ?>">
				<input type="radio" name="config2" value="<?php echo($configuration->get_id()); ?>">
			</td>
			<td><a href="index.php?go=machine_details&amp;id=<?php echo($machine->get_id()); ?>&amp;config=<?php echo($configuration->get_id()); ?>"><?php echo($configuration->get_id()); ?></a></td>
			<td><?php echo($configuration->get_created()); ?></td>
			<td><?php echo($configuration->get_last_activity()); ?></td>
		</tr>
	<?php endforeach; ?>
</table>
<input type="submit" value="Compare">
</form>
<?php

	if( count($configs) > 1 && isset ($user)) {
		echo '<p><a href="index.php?go=machine_purge&amp;id=' . $machine->get_id() . '&amp;purge=config">Purge configuration history</a></p>' . "\n";
	}
	echo "<h2 class=\"text-medium text-blue bold\">Action history</h2>";

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
	
	if(count($machine_logs) != 0) {
		echo "</table>";
		if($machine_logs_number == 20) {
			echo "<span class=\"text-small\">Only the last 20 entries are shown,</span> <a href=\"index.php?go=action_history&amp;id=" . $machine->get_id() . "\" class=\"text-small\">click here to see the complete list</a>.";
		}
		if (isset ($user))
		  {
		echo '<p><a href="index.php?go=machine_purge&amp;id=' . $machine->get_id() . '&amp;purge=log">Purge log history</a></p>' . "\n";
		  }

	}

?>
<script type="text/javascript">
	var TSort_Data = new Array ('lastjobs','i','s','s','d','d');
	var TSort_Initial = "0D";
	tsRegister();
</script> 
