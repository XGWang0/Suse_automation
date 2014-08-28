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

/* Check if the machines are suited for reinstall. */
if (check_machines_before_reinstall ($machines, 'upgrade')) {
?>

<h5>You are trying to upgrade the following machine(s) to a higher release with Autoyast</h5>

<ul>
<?php foreach ($machines as $machine): ?>
<li><input type="hidden" name="a_machines[]" value="<?php echo($machine->get_id()); ?>"><a class="text-small-bold" href="index.php?go=machine_details&amp;id=<?php echo($machine->get_id()); ?>"><?php echo($machine->get_hostname()); ?></a></li>
<?php endforeach; ?>
</ul>

<p>
With default upgrade method only the product at the installation repo URL. All other options will be ignored.<br/>
If you need to change parameters of the installation in this form, select the custom type.
</p>

<form enctype="multipart/form-data" action="index.php?go=upgrade" method="POST" onsubmit="return checkcontents(this);">
<table class="text-medium">
  <tr>
    <td>Upgrade method:</td>
    <td><label><input type="radio" id="upgradedef" name="installmethod" value="default">By default</label>
      <label><input type="radio" id="upgradediy" name="installmethod" value="custom">Customized</label>
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
	  <input type="text" name="repo_producturl" id="repo_producturl" size="70" value="<?php if(isset($_POST["repo_producturl"])){echo $_POST["repo_producturl"];} ?>" title="required: url" /><span class="required">*</span>
	  &nbsp;&nbsp;Registration Code:&nbsp;<input type="text" name="rcode[]" id="rcode_product" size="20" value="<?php if(isset($_POST["rcode"][0])){echo $_POST["rcode"][0];} ?>"/>
	</td>
  </tr>
  <tr>
	<td>Addon URL (optional, support multiple): </td>
	<td>
	  <label for="addon_products">Product:</label> <select name="addon_products" id="addon_products" style="width: 200px;"></select>
	  <label for="addon_archs">Arch:</label> <select name="addon_archs" id="addon_archs" style="width: 80px;" onchange="checkReinstallDropdownArchitectures()"></select>
	  <span id="addon_archs_warning" class="text-red text-small bold"></span>
	</td>
   </tr>
  <tr>
	<td></td>
	<td>
	  <input type="text" name="addon_url[]" id="addon_producturl" size="70" value="<?php if(isset($_POST["addon_producturl"])){echo $_POST["addon_producturl"];} ?>" />
	  &emsp;Registration Code:&nbsp;<input type="text" name="rcode[]" id="rcode_addon" size="20" value="<?php if(isset($_POST["rcode_product"][1])){echo $_POST["rcode_product"][1];} ?>"/>
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
  			<option value="full">Full distro</option>
		  </select>
		<span id='patterns_modified' class='modified'></span>
		</legend>
		<div id="available_patterns"></div>
		<div id="addon_patterns"></div>
        <div id="more_patterns"><label style="width: 1000; float: left;">More patterns: <input type="text" size="75" name="patterns[]" /></label></div>
	  </fieldset>
	</td>
  </tr>
  <tr>
	<td>Installation options (optional): </td>
	<td><input type="text" name="installoptions" size="70" value="<?php echo $installoptions; ?>" /> (e.g. <em>vnc=1 vncpassword=12345678</em>)<br /><strong>Note:</strong> Do not put any sensitive passwords, since it is plain text. VNC passwords must be 8+ bytes long.
	<?php if($installoptions_warning != "") {echo ("</br> <font color=\"red\" >$installoptions_warning</font>");} ?>
	</td>
  </tr>
  <tr>
	<td>Additional RPMs (optional): </td>
	<td><input type="text" name="additionalrpms" size="70" value="<?php if(isset($_POST["additionalrpms"])){echo $_POST["additionalrpms"];} else echo ($config->lists->arlist);?>" /></td>
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
		"SMT server: <strong>$smtserver</strong> (<strong>Note:</strong> This must be configured in config.ini by an admin.)." .
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
	<td><input type="text" name="mailto" value="<?php if(isset($_POST["mailto"])) {echo $_POST["mailto"];} else if (isset ($user)) { echo ($user->getEmail ());} ?>" /> (if you want to be notified when the installation is finished)</td>
  </tr>
</table>	
<input type="submit" name="proceed" value="proceed" id="proceed">
<?php
	foreach ($machines as $machine):
		echo('<input type="hidden" name="a_machines[]" value="'.$machine->get_id().'">');
	endforeach;

	print_install_post_data ();
}
?>
</form>

<script src="js/install_product.js"></script>
