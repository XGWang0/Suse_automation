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
     * Contents of the <tt>vhreinstall</tt> page  
     */
    if (!defined('HAMSTA_FRONTEND')) {
        $go = 'vhreinstall';
        return require("index.php");
    }
if (User::isLogged())
  $user = User::getById (User::getIdent(), $config);

	$blockedMachines = array();
	$virtualMachines = array();
	$hasChildren = array();
    $ishwvirt = 0;
    $arrhwvirt = array();
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
        $ishwvirt += $machine->get_ishwvirt();
        $arrhwvirt[$machine->get_hostname()]=$machine->get_ishwvirt();
	}
	if(count($blockedMachines) != 0) {
		echo "<div class=\"text-medium\">" .
			"<p>The following machines are currently either marked as \"Not accepting jobs\", \"Reinstall Deny\" or \"Outdated (Blocked)\".</p>" .
			"<strong>" . implode(", ", $blockedMachines) . "</strong>" .
			"<p>Please go back to free them up and then try your reinstall again.</p>" .
		"</div>";
	} elseif (count($virtualMachines) != 0) {
		echo "<div class=\"text-medium\">" .
			"<p>The following machines are virtual machines.</p>" .
			"<strong>" . implode(", ", $virtualMachines) . "</strong>" .
			"<p>It is not possible to reinstall virtual machines (you can delete them in QA Cloud and than create new ones).</p>" .
			"</div>";
	} elseif (count($hasChildren) != 0) {
		echo "<div class=\"text-medium\">" .
			"<p>The following machines currently contain virtual machines.</p>" .
			"<strong>" . implode(", ", $hasChildren) . "</strong>" .
			"<p>It is not possible to reinstall virtual hosts with virtual machines (you can delete them in QA Cloud before reinstalling virtual host).</p>" .
			"</div>";
	} elseif ($ishwvirt != count($machines)) {
		echo "<div class=\"text-medium\">" .
		"<p>The following machines probably do not support hardware virtualization.</p>";
		foreach ($arrhwvirt as $key=>$value)
			if ($value == "0")
					echo "<strong>" . $key . "</strong>";
		echo "<p>Please go back and try other machines.</p></div>\n";
	} else {

?>

<h5>You are trying to reinstall the following machines as virtualization host(s) with Autoyast<br />

<ul>
<?php foreach ($machines as $machine): ?>
<li><input type="hidden" name="a_machines[]" value="<?php echo($machine->get_id()); ?>"><a href="index.php?go=machine_details&amp;id=<?php echo($machine->get_id()); ?>"><?php echo($machine->get_hostname()); ?></a></li>
<?php endforeach; ?>
</ul></h5>

<p>
Alternativelly, you can <a href="index.php?go=machine_reinstall&amp;a_machines[]=<?php echo implode("&amp;a_machines[]=", request_array("a_machines")); ?>">reinstall those machines as SUTs</a>.
</p>

<p>
This page will allow you to customize the AutoYaST product installation for the machine(s) you have selected, including repository URLs and other options, or to upload your own custom AutoYaST profile. However, you can still simply copy the product url into the fields
</p>

<form enctype="multipart/form-data" action="index.php?go=vhreinstall" method="POST" onsubmit="return checkcontents(this);">

  <?php require ("req_rein_all.php"); ?>
  <?php require ("req_vhrein.php"); ?>
  <div class='row'>
    <label for='mailto'>Notification email address (optional):</label>
    <input type="text" name="mailto" id="mailto" value="<?php if(isset($_POST["mailto"])){echo $_POST["mailto"];} else if (isset($user)) { echo $user->getEmail(); } ?>" /> (if you want to be notified when the installation is finished)
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
