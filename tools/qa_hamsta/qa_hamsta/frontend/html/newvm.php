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
     * Contents of the <tt>newvm</tt> page  
     */
    if (!defined('HAMSTA_FRONTEND')) {
        $go = 'newvm';
        return require("index.php");
    }
if (User::isLogged())	
  $user = User::getById (User::getIdent (), $config);

	$blockedMachines = array();
	$nonVH = array();
	$paravirtnotsupported = array();
	$fullvirtnotsupported = array();
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
	} else {

?>

<h5>You are trying to create new virtual machines on following virtualization hosts<br />

<ul>
<?php foreach ($machines as $machine): ?>
<li><input type="hidden" name="a_machines[]" value="<?php echo($machine->get_id()); ?>"><a href="index.php?go=machine_details&amp;id=<?php echo($machine->get_id()); ?>"><?php echo($machine->get_hostname()); ?></a> &nbsp;&nbsp;
<?php if($machine->get_ishwvirt() == 0) echo $machine->get_hostname()." probably doesn't support full-virtualization. Use Para mode, please!"; ?>
</li>
<?php endforeach; ?>
</ul></h5>

<p>
This page will allow you to customize the AutoYaST product installation for the machine(s) you have selected, including repository URLs and other options, or to upload your own custom AutoYaST profile. However, you can still simply copy the product url into the fields.
</p>

<form enctype="multipart/form-data" action="index.php?go=newvm" method="POST" onsubmit="return checkcontents(this);">
  <?php require ("req_rein_all.php"); ?>
  <?php require ("req_newvm_com_conf.php"); ?>
  <?php require ("req_newvm_linux_conf.php"); ?>
  <div class="row">
    <label for="userfile">Upload custom autoyast profile</label>
    <input type="file" name="userfile" id="userfile">
    <input type="button" value="clear" onclick='clear_filebox("userfile")'>
  </div>
  <div class="row">
    <label for="setupfordesktop">Setup host for running desktop tests?</label>
    <input type="checkbox" name="setupfordesktop" id="setupfordesktop"  value="yes">
          <span>Yes, setup for running desktop test.</span>
  </div>
  <div class="row">
    <label for="kexecboot">Load installtion by Kexec?</label>
    <input type="checkbox" name="kexecboot" id="kexecboot"  value="yes">
          <span>Yes, load by Kexec.</span>
  </div>
  <div class="row">
    <label for="mailto" >Notification email address (optional):</label>
    <input id="mailto" type="text" name="mailto" value="<?php if(isset($_POST["mailto"])){echo $_POST["mailto"];} else if (isset($user)) { echo $user->getEmail(); } ?>" /> (if you want to be notified when the installation is finished)
  </div>

<br />
<?php
	echo ('<input type="submit" name="proceed" value="Proceed">');
	foreach ($machines as $machine):
		echo('<input type="hidden" name="a_machines[]" value="'.$machine->get_id().'">');
	endforeach;

	print_install_post_data ();
}
?>
</form>

<script src="js/install_product.js"></script>
