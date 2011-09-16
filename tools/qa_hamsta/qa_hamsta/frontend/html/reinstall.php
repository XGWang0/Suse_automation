<?php
	if (!defined('HAMSTA_FRONTEND')) {
		$go = 'send_job';
		return require("index.php");
	}
	$blockedMachines = array();
	$virtualMachines = array();
	$hasChildren = array();
	foreach ($machines as $machine) {
		if (($machine->is_busy() > 1)) {
			$blockedMachines[] = $machine->get_hostname();
		}
		if(preg_match ('/^vm\//', $machine->get_type())) {
			$virtualMachines[] = $machine->get_hostname();
		}
		if(count($machine->get_children()) > 0) {
			$hasChildren[] = $machine->get_hostname();
		}
	}
	if(count($blockedMachines) != 0) {
		echo "<div class=\"text-medium\">" .
			"The following machines are currently either marked as \"Not accepting jobs\", \"Reinstall Deny\" or \"Outdated (Blocked)\":<br /><br />" .
			"<strong>" . implode(", ", $blockedMachines) . "</strong><br /><br />" .
			"Please go back to free them up and then try your reinstall again." .
			"</div>";
	} elseif (count($virtualMachines) != 0) {
		echo "<div class=\"text-medium\">" .
			"The following machines are virtual machines:<br /><br />" .
			"<strong>" . implode(", ", $virtualMachines) . "</strong><br /><br />" .
			"It is not possible to reinstall virtual machines (you can delete them in QA Cloud and than create new ones)." .
			"</div>";
	} elseif (count($hasChildren) != 0) {
		echo "<div class=\"text-medium\">" .
			"The following machines currently contain virtual machines:<br /><br />" .
			"<strong>" . implode(", ", $hasChildren) . "</strong><br /><br />" .
			"It is not possible to reinstall virtual hosts with virtual machines (you can delete them in QA Cloud before reinstalling virtual host)." .
			"</div>";

	} else {
?>
<h5>You are trying to reinstall the following machine(s) with Autoyast:<br />

<ul>
<?php foreach ($machines as $machine): ?>
<li><input type="hidden" name="a_machines[]" value="<?php echo($machine->get_id()); ?>"><a href="index.php?go=machine_details&amp;id=<?php echo($machine->get_id()); ?>"><?php echo($machine->get_hostname()); ?></a></li>
<?php endforeach; ?>
</ul></h5>

<form enctype="multipart/form-data" action="index.php?go=reinstall" method="POST" onsubmit="return checkcontents(this);">
<table class="text-medium">
<?php require ("req_rein_all.php"); ?>
<?php require ("req_rein.php"); ?>
<?php require ("req_validation.php"); ?>
<?php require ("req_sut.php"); ?>
  <tr>
	<td>Notification email address (optional):</td>
	<td><input type="text" name="mailto" value="<?php if(isset($_POST["mailto"])){echo $_POST["mailto"];} ?>" /> (if you want to be notified when the installation is finished)</td>
  </tr>
</table>	
<input type="submit" name="proceed" value="Proceed">
<?php
	foreach ($machines as $machine):
		echo('<input type="hidden" name="a_machines[]" value="'.$machine->get_id().'">');
	endforeach;
?>
</form>

<?php
}
require("req_reinstfuncs.php");
?>
