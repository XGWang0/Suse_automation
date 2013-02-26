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
        $go = 'newvm-win';
        return require("index.php");
    }
if (User::isLogged())
  $user = User::getById (User::getIdent (), $config);

	$blockedMachines = array();
	$nonVH = array();
	$paravirtnotsupported = array();
	$fullvirtnotsupported = array();
	$ishwvirt = 0;
	$arrhwvirt = array();
	foreach ($machines as $machine) {
		if ($machine->is_busy() || ! $machine->has_perm('job')) {
			$blockedMachines[] = $machine->get_hostname();
		}
		if ($machine->get_role() != 'VH') {
			$nonVH[] = $machine->get_hostname();
		} else {
			if ($machine->get_type() != 'xen') $paravirtnotsupported[] = $machine->get_hostname();
		}
		$virtavaimem = $machine->get_vmusedmemory() < 512 ? $machine->get_vmusedmemory() : $machine->get_vmusedmemory() - 512; #Dom0 will cost 512MB
        $virtavaidisk = $machine->get_avaivmdisk();
		$ishwvirt += $machine->get_ishwvirt();
		$arrhwvirt[$machine->get_hostname()]=$machine->get_ishwvirt();
	}

	if(count($nonVH) != 0) {
		echo "<div class=\"text-medium\">" .
			"The following machines are not virtualization hosts:<br /><br />" .
			"<strong>" . implode(", ", $nonVH) . "</strong><br /><br />" .
			"Please go back to deselect them (or convert them to virtualization hosts) and then try new VM installation again." .
		"</div>";
	} elseif(count($blockedMachines) != 0) {
		echo "<div class=\"text-medium\">" .
			"The following machines are currently either marked as \"Not accepting jobs\", \"Reinstall Deny\" or \"Outdated (Blocked)\":<br /><br />" .
			"<strong>" . implode(", ", $blockedMachines) . "</strong><br /><br />" .
			"Please go back to free them up and then try new VM creation again." .
		"</div>";
	} elseif($ishwvirt != count($machines)) {
		echo "<div class=\"text-medium\">" .
			"The following machines are not support virtualization by HardWare, cannot install Windows VM: <br /><br />";
		foreach ($arrhwvirt as $key=>$value)
			if ($value == "0")
				echo "<strong> $key </strong><br />";
		echo "<br />Please go back to to deselect them and then try new VM installation again. </div>\n";
	} else {

?>

<h5>You are trying to create new virtual machines on following virtualization hosts:<br />

<ul>
<?php foreach ($machines as $machine): ?>
<li><input type="hidden" name="a_machines[]" value="<?php echo($machine->get_id()); ?>"><a href="index.php?go=machine_details&amp;id=<?php echo($machine->get_id()); ?>"><?php echo($machine->get_hostname()); ?></a></li>
<?php endforeach; ?>
</ul></h5>

This page will allow you to install a Windows for the virtual machine(s) you have selected. However, you can still simply copy the product path into the fields.
<br /><br />

<form enctype="multipart/form-data" action="index.php?go=newvm-win" method="POST" onsubmit="return checkcontents(this);">

<table class="text-medium">
  <?php require ("req_newvm_win.php"); ?>
  <?php require ("req_newvm_com_conf.php"); ?>
  <tr>
    <td>Notification email address (optional):</td>
    <td><input type="text" name="mailto" value="<?php if(isset($_POST["mailto"])){echo $_POST["mailto"];} else if (isset($user)) { echo $user->getEmail(); } ?>" /> (if you want to be notified when the installation is finished)</td>
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
