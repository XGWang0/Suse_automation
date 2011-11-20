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
     * Contents of the <tt>send_job</tt> page  
     */
    if (!defined('HAMSTA_FRONTEND')) {
        $go = 'vhreinstall';
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

<h5>You are trying to reinstall the following machines as virtualization host(s) with Autoyast:<br />

<ul>
<?php foreach ($machines as $machine): ?>
<li><input type="hidden" name="a_machines[]" value="<?php echo($machine->get_id()); ?>"><a href="index.php?go=machine_details&amp;id=<?php echo($machine->get_id()); ?>"><?php echo($machine->get_hostname()); ?></a></li>
<?php endforeach; ?>
</ul></h5>

	Alternativelly, you can <a href="index.php?go=reinstall&amp;a_machines[]=<?php echo implode("&amp;a_machines[]=", request_array("a_machines")); ?>">reinstall those machines as SUTs</a>.
<br /><br />

This page will allow you to customize the AutoYaST product installation for the machine(s) you have selected, including repository URLs and other options, or to upload your own custom AutoYaST profile. However, you can still simply copy the product url into the fields
<br /><br />

<form enctype="multipart/form-data" action="index.php?go=vhreinstall" method="POST" onsubmit="return checkcontents(this);">

<table class="text-medium">
  <?php require ("req_rein_all.php"); ?>
  <?php require ("req_vhrein.php"); ?>
  <tr>
    <td>Notification email address (optional):</td>
    <td><input type="text" name="mailto" value="<?php if(isset($_POST["mailto"])){echo $_POST["mailto"];} ?>" /> (if you want to be notified when the installation is finished)</td>
  </tr>
</table>    
<br />
<?php
        echo ('<input type="submit" name="proceed" value="Proceed">');
        foreach ($machines as $machine):
            echo('<input type="hidden" name="a_machines[]" value="'.$machine->get_id().'">');
        endforeach;
?>
</form>

<?php
}
require("req_reinstfuncs.php");
?>
