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
?>

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
	  SDK #1: <input type="text" name="addon_url[]" id="sdk_producturl" size="70" value="<?php if(isset($_POST["sdk_producturl"])){echo $_POST["sdk_producturl"];} ?>" />
	  &emsp;<button type="button" onclick='anotherrepo()'> + </button>
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
        <td>Additional RPMs (optional): </td>
        <td><input type="text" name="additionalrpms" size="70" value="<?php if(isset($_POST["additionalrpms"])){echo $_POST["additionalrpms"];} else echo ARLIST;?>" /></td>
  </tr>
  <tr>
        <td>Installation options (optional): </td>
        <td><input type="text" name="installoptions" size="70" value="<?php echo $installoptions; ?>" /> (e.g. <em>vnc=1 vncpassword=12345678</em>)<br /><strong>Note:</strong> Don't put any sensitive passwords, since it is plain text. VNC passwords must be 8+ bytes long.
        <?php if($installoptions_warning != "") {echo ("</br> <font color=\"red\" >$installoptions_warning</font>");} ?>
        </td>
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
        print "\" /> <br />\n";
	print "Registration Code for main product: <input type=\"text\" name=\"rcode[]\" id=\"rcode_product\" size=\"20\" value=\"";
		if(isset($_POST["rcode"][0])){echo $_POST["rcode"][0];} 
		print "\">\n<br />";
		print "Registration Code for SDK repo #1: <input type=\"text\" name=\"rcode[]\" id=\"rcode_product\" size=\"20\" value=\"";
		if(isset($_POST["rcode"][1])){echo $_POST["rcode"][1];}
		print "\" /><input type=\"button\" onclick=\"anotherrcode()\" value=\"+\" /><br />";
		print "<div id=\"additional_rcode\"></div></div>";
?>
    </td>
  </tr>
