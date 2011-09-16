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
			"The following machines are currently either marked as \"Not accepting jobs\", \"Upgrade Deny\" or \"Outdated (Blocked)\":<br /><br />" .
			"<strong>" . implode(", ", $blockedMachines) . "</strong><br /><br />" .
			"Please go back to free them up and then try your upgrade again." .
			"</div>";
	} elseif (count($virtualMachines) != 0) {
		echo "<div class=\"text-medium\">" .
			"The following machines are virtual machines:<br /><br />" .
			"<strong>" . implode(", ", $virtualMachines) . "</strong><br /><br />" .
			"It is not possible to upgrade all virtual machines (you can delete them in QA Cloud and than create new ones)." .
			"</div>";
	} elseif (count($hasChildren) != 0) {
		echo "<div class=\"text-medium\">" .
			"The following machines currently contain virtual machines:<br /><br />" .
			"<strong>" . implode(", ", $hasChildren) . "</strong><br /><br />" .
			"It is not possible to upgrade virtual hosts with virtual machines (you can delete them in QA Cloud before upgrade virtual host)." .
			"</div>";

	} else {
?>
<h5>You are trying to upgrade the following machine(s) to a higher release with Autoyast:<br />

<ul>
<?php foreach ($machines as $machine): ?>
<li><input type="hidden" name="a_machines[]" value="<?php echo($machine->get_id()); ?>"><a href="index.php?go=machine_details&amp;id=<?php echo($machine->get_id()); ?>"><?php echo($machine->get_hostname()); ?></a></li>
<?php endforeach; ?>
</ul></h5>
<script language="javascript">
//Will provide a better way
function upmethod(myvar)
{
	if (myvar == "default") {
		alert ("upgrade by default! Only \"Installation repo URL\" is useable, others will not be included.");
	} else {
		alert ("upgrade by customized options, all below options can work!");
	}
}
</script>
<form enctype="multipart/form-data" action="index.php?go=upgrade" method="POST" onsubmit="return checkcontents(this);">
<table class="text-medium">
  <tr>
    <td>Upgrade method:</td>
    <td><label><input type="radio" id="upgradedef" name="installmethod" value="default" onclick="upmethod('default');">By default</label>
      <label><input type="radio" id="upgradediy" name="installmethod" value="custom" onclick="upmethod('custom');">Customized</label>
    </td>
  </tr>
  <tr>
	<td width=380>Installation repo URL (required): </td>
	<td>
	  <label for="repo_products">Product:</label> <select name="repo_products" id="repo_products" style="width: 200px;"></select>
	  <label for="repo_archs">Arch:</label> <select name="repo_archs" id="repo_archs" style="width: 80px;" onchange="checkReinstallDropdownArchitectures()"></select>
	  <span id="repo_archs_warning" class="text-red text-small bold"></span>
	</td>
   </tr>
  <tr>
	<td></td>
	<td>
	  <input type="text" name="repo_producturl" id="repo_producturl" size="70" value="<?php if(isset($_POST["repo_producturl"])){echo $_POST["repo_producturl"];} ?>" title="required: url" onchange="alert('WARNING!\n\nIf you change the \'Installation repo URL\' manually then the \'Available patterns\' shown on this page may not reflect the actual product you are installing. The installation itself may work just fine, however, it is likely that you will not end up with the right set of patterns.\n\nWhile we support editing the installation URL manually, it is not advised to do so (rather, you should use the pre-populated installation URLs in the dropdown boxes).\n\nIf you insist on modifying the URL by hand, your safest bet is to de-select all of the \'Available patterns\' below and then install the patterns that you want after the installation completes.\n\n(Note: This will be fixed in our next release).');" /><span class="required">*</span>
	  &nbsp;&nbsp;Registration Code:&nbsp;<input type="text" name="rcode[]" id="rcode_product" size="20" value="<?php if(isset($_POST["rcode"][0])){echo $_POST["rcode"][0];} ?>"/>
	</td>
  </tr>
  <tr>
	<td>SDK/Addon URL (optional, support multiple): </td>
	<td>
	  <label for="sdk_products">Product:</label> <select name="sdk_products" id="sdk_products" style="width: 200px;"></select>
	  <label for="sdk_archs">Arch:</label> <select name="sdk_archs" id="sdk_archs" style="width: 80px;" onchange="checkReinstallDropdownArchitectures()"></select>
	  <span id="sdk_archs_warning" class="text-red text-small bold"></span>
	</td>
   </tr>
  <tr>
	<td></td>
	<td>
	  <input type="text" name="addon_url[]" id="sdk_producturl" size="70" value="<?php if(isset($_POST["sdk_producturl"])){echo $_POST["sdk_producturl"];} ?>" />
	  &emsp;Registration Code:&nbsp;<input type="text" name="rcode[]" id="rcode_sdk" size="20" value="<?php if(isset($_POST["rcode_product"][1])){echo $_POST["rcode_product"][1];} ?>"/>
	  &emsp;<button type="button" onclick="anotherrepo()"> + </button>
	  <div id="additional_repo"></div>
	</td>
  </tr>
  <tr>
	<td>Available patterns (optional) : </td>
	<td>
	  <fieldset>
		<legend>
		  <select name="typicmode" id="typicmode" onchange="changepattern()">
  			<option value="text">Text</option>
  			<option value="gnome">Default Gnome</option>
			<option value="kde">Default KDE</option>
  			<option value="full">Full install</option>
		  </select>
		<span id='patterns_modified' class='modified'></span>
		</legend>
		<div id="available_patterns"></div>
		<div id="sdk_patterns"></div>
        <div id="more_patterns"><label style="width: 1000; float: left;">More patterns: <input type="text" size="75" name="patterns[]" /></label></div>
	  </fieldset>
	</td>
  </tr>
  <tr>
	<td>Installation options (optional): </td>
	<td><input type="text" name="installoptions" size="70" value="<?php echo $installoptions; ?>" /> (e.g. <em>vnc=1 vncpassword=12345678</em>)<br /><strong>Note:</strong> Don't put any sensitive passwords, since it is plain text. VNC passwords must be 8+ bytes long.
	<?php if($installoptions_warning != "") {echo ("</br> <font color=\"red\" >$installoptions_warning</font>");} ?>
	</td>
  </tr>
  <tr>
	<td>Additional RPMs (optional): </td>
	<td><input type="text" name="additionalrpms" size="70" value="<?php if(isset($_POST["additionalrpms"])){echo $_POST["additionalrpms"];} ?>" /></td>
  </tr>
  <tr>
	<td>Install Updates for OS?</td>
	<td>
<?php
	# We provide a checkbox for them to say whether they want updates or not
	# If they check the box, we give them additional update options
	print "<select name=\"startupdate\" id=\"startupdate\">" .
		"<option value=\"update-none\"" . ((isset($_POST['startupdate']) and $_POST['startupdate'] == "update-none") ? " selected=\"selected\"" : "") . ">Don't install updates</option>" .
		"<option value=\"update-smt\"" . ((isset($_POST['startupdate']) and $_POST['startupdate'] == "update-smt") ? " selected=\"selected\"" : "") . ">Install updates (register using local SMT)" .
		"<option value=\"update-reg\"" . ((isset($_POST['startupdate']) and $_POST['startupdate'] == "update-reg") ? " selected=\"selected\"" : "") . ">Install updates (register using registration code)" .
		"<option value=\"update-opensuse\"" . ((isset($_POST['startupdate']) and $_POST['startupdate'] == "update-opensuse") ? " selected=\"selected\"" : "") . ">Install updates (for OpenSuSE only)" .
	"</select> " .
	"(Must choose \"register using registration code\" option if you fill registration code)";

	# The additional update options are whether to update with SMT or regcode
	print "<div id=\"updateoptions-smt\" class=\"text-small\" style=\"margin: 5px; padding: 5px; border: 1px solid red; display: " . ((isset($_POST['startupdate']) and $_POST['startupdate'] == "update-smt") ? "block" : "none") . ";\">" .
		"SMT server: <strong>$smtserver</strong> (<strong>Note:</strong> This must be configured in config.php by an admin)." .
		"<input type=\"hidden\" name=\"update-smt-url\" value=\"$smtserver\" />" .
	"</div>";
	print "<div id=\"updateoptions-reg\" class=\"text-small\" style=\"margin: 5px; padding: 5px; border: 1px solid red; display: " . ((isset($_POST['startupdate']) and $_POST['startupdate'] == "update-reg") ? "block" : "none") . ";\">" .
	"Registration Email: <input type=\"text\" name=\"update-reg-email\" value=\"";
	if (isset($_POST["update-reg-email"])) echo $_POST["update-reg-email"];
	print "\" /></div>";
?>
	</td>
  </tr>
  <tr>
	<td>Also run validation tests?</td>
	<td><input type="checkbox" value="yes" name="startvalidation"<?php if(isset($_POST['startvalidation']) and $_POST['startvalidation'] == "yes"){echo " checked=\"checked\"";} ?> />Yes, run validation tests automatically after the installation</td>
  </tr>
	<td>Notification email address (optional):</td>
	<td><input type="text" name="mailto" value="<?php if(isset($_POST["mailto"])){echo $_POST["mailto"];} ?>" /> (if you want to be notified when the installation is finished)</td>
  </tr>
</table>	
<input type="submit" name="proceed" value="proceed" id="proceed">
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
