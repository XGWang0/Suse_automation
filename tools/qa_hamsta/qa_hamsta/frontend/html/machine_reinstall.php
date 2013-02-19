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
<h5>You are trying to reinstall the following machine(s) with Autoyast:</h5>
<ul>
<?php foreach ($machines as $machine): ?>
<li><input type="hidden" name="a_machines[]" value="<?php echo($machine->get_id()); ?>"><a class="text-small-bold" href="index.php?go=machine_details&amp;id=<?php echo($machine->get_id()); ?>"><?php echo($machine->get_hostname()); ?></a></li>
<?php endforeach; ?>
</ul>

<form enctype="multipart/form-data" action="index.php?go=machine_reinstall" method="POST" onsubmit="return checkcontents(this);">
<table class="text-medium">
<?php require ("req_rein_all.php"); ?>
<?php require ("req_rein.php"); ?>
<?php require ("req_validation.php"); ?>
<?php require ("req_sut.php"); ?>
  <tr>
	<td>Notification email address (optional):</td>
	<td><input type="text" name="mailto" value="<?php if(isset($_POST["mailto"])){echo $_POST["mailto"];} else if (isset($user)) { echo $user->getEmail(); } ?>" /> (if you want to be notified when the installation is finished)</td>
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
