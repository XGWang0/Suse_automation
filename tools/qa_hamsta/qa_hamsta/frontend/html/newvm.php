<?php
    /**
     * Contents of the <tt>send_job</tt> page  
     */
    if (!defined('HAMSTA_FRONTEND')) {
        $go = 'newvm';
        return require("index.php");
    }
	$blockedMachines = array();
	$nonVH = array();
	$paravirtnotsupported = array();
	$fullvirtnotsupported = array();
	foreach ($machines as $machine) {
		if (($machine->is_busy() > 1)) {
			$blockedMachines[] = $machine->get_hostname();
		}
		if ($machine->get_role() != 'VH') {
			$nonVH[] = $machine->get_hostname();
		} else {
			if ($machine->get_type() != 'xen') $paravirtnotsupported[] = $machine->get_hostname();
			//TODO check full virt support!
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

<h5>You are trying to create new virtual machines on following virtualizaion hosts:<br />

<ul>
<?php foreach ($machines as $machine): ?>
<li><input type="hidden" name="a_machines[]" value="<?php echo($machine->get_id()); ?>"><a href="index.php?go=machine_details&amp;id=<?php echo($machine->get_id()); ?>"><?php echo($machine->get_hostname()); ?></a></li>
<?php endforeach; ?>
</ul></h5>

This page will allow you to customize the AutoYaST product installation for the machine(s) you have selected, including repository URLs and other options, or to upload your own custom AutoYaST profile. However, you can still simply copy the product url into the fields
<br /><br />

<form enctype="multipart/form-data" action="index.php?go=newvm" method="POST" onsubmit="return checkcontents(this);">

<table class="text-medium">
  <?php require ("req_rein_all.php"); ?>
  <?php require ("req_newvm.php"); ?>
  <?php require ("req_sut.php"); ?>
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
