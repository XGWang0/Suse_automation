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

	if (!defined('HAMSTA_FRONTEND')) {
		$go = 'machine_send_job';
		return require("index.php");
	}

	if (User::isLogged())
	  $user = User::getById (User::getIdent (), $config);

	$blockedMachines = array();
	$virtualMachines = array();
	$hasChildren = array();
	foreach ($machines as $machine) {
		if( ! $machine->has_perm('job') || ! $machine->has_perm('install') ) {
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
Machines:
<?php foreach ($machines as $machine): ?>
<span class="machine_name">
	<a class="text-small-bold" href="index.php?go=machine_details&amp;id=<?php echo($machine->get_id()); ?>"><?php echo($machine->get_hostname()); ?></a><input class="x" type="button" value="x"/>

</span>
<?php endforeach; ?>

<form enctype="multipart/form-data" action="index.php?go=machine_reinstall" method="POST" onsubmit="return checkcontents(this);">
<input id="summary" type="checkbox"/>
<label for="summary">show summary</label>
<div id="finish">
	<label for="summary"><input type="button" value="Edit"/></label>
	<input type="submit" value="Submit"/>
</div>
<div class="tabs">
	<div id='tab-product' class="tab">
		<input type="radio" id="tab1" name="tab-group-1" checked/>
		<div class="content">
			<div class="breadcrumb">
				<label for="tab1"><input type="button" value="Prev" class="disabled"/></label>
				<label for="tab2"><input type="button" value="Next"/></label>
				<label for="summary"><input type="button" value="Finish"/></label>
				<label class='pos active first' for="tab1">Product</label>
				>>
				<label class='pos' for="tab2">Disk</label>
				>>
				<label class='pos' for="tab3">Advanced</label>
			</div>
			<?php require ("req_rein_all.php"); ?>
		</div>
	</div>
	<div id='tab-disk' class="tab">
		<input type="radio" id="tab2" name="tab-group-1"/>
		<div class="content">
			<div class="breadcrumb">
				<label for="tab1"><input type="button" value="Prev"/></label>
				<label for="tab3"><input type="button" value="Next"/></label>
				<label for="summary"><input type="button" value="Finish"/></label>
				<label class='pos first' for="tab1">Product</label>
				>>
				<label class='pos active' for="tab2">Disk</label>
				>>
				<label class='pos' for="tab3">Advanced</label>
			</div>
			<?php require ("req_rein.php"); ?>
		</div>
	</div>
	<div id='tab-advanced' class="tab">
		<input type="radio" id="tab3" name="tab-group-1"/>
		<div class="content">
			<div class="breadcrumb">
				<label for="tab2"><input type="button" value="Prev"/></label>
				<label for="tab3"><input type="button" value="Next" class="disabled"/></label>
				<label for="summary"><input type="button" value="Finish"/></label>
				<label class='pos first' for="tab1">Product</label>
				>>
				<label class='pos' for="tab2">Disk</label>
				>>
				<label class='pos active' for="tab3">Advanced</label>
			</div>
			<?php require ("req_sut.php"); ?>
		</div>
	</div>
</div>
<?php
	foreach ($machines as $machine):
		echo('<input type="hidden" name="a_machines[]" value="'.$machine->get_id().'">');
	endforeach;
?>

</form>

<?php
} // else -- reinstallation happens
?>

<script>
<?php require ('js/install_product.js'); ?>
</script>
