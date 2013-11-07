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
        $go = 'vm-migrate';
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
	}
	if(count($nonVH) != 0) {
		echo "<div class=\"text-medium\">" .
			"The following machines are not virtualization hosts:<br /><br />" .
			"<strong>" . implode(", ", $nonVH) . "</strong><br /><br />" .
			"Please go back to deselect them (or convert them to virtualization hosts) and then try VM migration again." .
		"</div>";
	} elseif(count($blockedMachines) != 0) {
		echo "<div class=\"text-medium\">" .
			"The following machines are currently either marked as \"Not accepting jobs\", \"Reinstall Deny\" or \"Outdated (Blocked)\":<br /><br />" .
			"<strong>" . implode(", ", $blockedMachines) . "</strong><br /><br />" .
			"Please go back to free them up and then try VM migration again." .
		"</div>";
	} else {

?>

<h5>You are trying to migrate virtual machines on following virtual hosts<br />

<ul>
<?php foreach ($machines as $machine): ?>
<li><input type="hidden" name="a_machines[]" value="<?php echo($machine->get_id()); ?>"><a href="index.php?go=machine_details&amp;id=<?php echo($machine->get_id()); ?>"><?php echo($machine->get_hostname()); ?></a> &nbsp;&nbsp;
<?php if($machine->get_ishwvirt() == 0) echo $machine->get_hostname()." probably doesn't support full-virtualization. Use Para mode, please!"; ?>
</li>
<?php endforeach; ?>
</ul></h5>

<p>
This page will allow you to migrate virtual machines with given domain name on the virtual hosts you have selected to remote virtual hosts with given IP.
</p>

<form enctype="multipart/form-data" action="index.php?go=vm_migrate" method="POST" onsubmit="return checkcontents(this);">

<table class="text-medium">
  <tr>
    <td>Virtual machine domain name(required): </td>
    <td><input type="text" value="" size="50" name="domain_name"></td>
  </tr>
  <tr>
    <td>Remote virtual host IP(required): </td>
    <td><input type="text" value="" size="50" name="migrateeIP"></td>
  </tr>
  <tr>
    <td>Need live migration? </td>
    <td><input id="livemigration" class="left" type="checkbox" value="yes" name="livemigration"> Yes, I need live migration.</td>
  </tr>
  <tr>
    <td>How many times to migrate? </td>
    <td><input type="text" value="" size="50" name="migratetimes"></td>
  </tr>
  <tr>
    <td>Notification email address (optional):</td>
    <td><input type="text" name="mailto" value="<?php if(isset($_POST["mailto"])){echo $_POST["mailto"];} else if (isset($user)) { echo $user->getEmail(); } ?>" /> (if you want to be notified when the vm migration is finished)</td>
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
?>
