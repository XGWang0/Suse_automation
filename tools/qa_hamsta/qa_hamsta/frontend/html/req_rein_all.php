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
if (User::isLogged())
  $user = User::getById (User::getIdent (), $config);

require("timezone.php");
?>

  <tr>
	<td class="">
		<label for="repo_products">Product:</label> 
	</td>
	<td>
		<select name="repo_products" id="repo_products" style=""></select>
	</td>
	<td>
	  <input type="text" name="repo_producturl" id="repo_producturl" size="" value="<?php if(isset($_POST["repo_producturl"])){echo $_POST["repo_producturl"];} ?>" title="required: url" />
	  <span class="required">*</span>
	  <span id="mininotification" class="text-red text-small bold"></span>
	</td>
  </tr>

  <tr>
	<td>
		<label for="addon_products">Add-on 1:</label>
	<td>
		<select name="addon_products" id="addon_products" style=""></select>
	</td>
	<td>
		<input type="text" name="addon_url[]" id="addon_producturl" size="" value="<?php if(isset($_POST["addon_producturl"])){echo $_POST["addon_producturl"];} ?>" />
	</td>
	<td>
	  <button type="button" onclick="anotherrepo()"> + </button>
	  <span id="mininotification" class="text-red text-small bold"></span>
	  <div id="additional_repo"></div>
	</td>
  </tr>

  <tr>
	<td colspan="4">
	  <fieldset>
		<legend>
		  <select name="typicmode" id="typicmode">
  			<option value="text">Text</option>
  			<option value="gnome">Default Gnome</option>
			<option value="kde">Default KDE</option>
			<option value="full">Full distro</option>
		  </select>
               <span id='patterns_modified' class='modified'></span>
		</legend>
		<input type="checkbox" id="pat1" checked/>
		<label for="pat1">pat1</label>
		<input type="checkbox" id="pat2"/>
		<label for="pat2">pat2</label>
		<input type="checkbox" id="pat3"/>
		<label for="pat3">pat3</label>
		<input type="checkbox" id="pat4" checked/>
		<label for="pat4">pat4</label>
		<input type="checkbox" id="pat5"/>
		<label for="pat5">pat5</label>
		<input type="checkbox" id="pat6"/>
		<label for="pat6">pat6</label>
	  </fieldset>
	</td>
  </tr>

  <tr>
	<td>
		<label for="additionalpatterns">Additional patterns</label>
	</td>
        <td>
		<input type="text" name="additionalpatterns" size="" value="<?php if(isset($_POST["additionalrpms"])){echo $_POST["additionalrpms"];} else echo ($config->lists->arlist);?>" />
	</td>
  </tr>


  <tr>
	<td>
		<label for="additionalrpms">Additional packages</label>
	</td>
        <td>
		<input type="text" name="additionalrpms" size="" value="<?php if(isset($_POST["additionalrpms"])){echo $_POST["additionalrpms"];} else echo ($config->lists->arlist);?>" />
	</td>
  </tr>

  <tr>
    <td>Timezone </td>
    <td>
	<select id="timezone" name="timezone">
    <?php
	$tz_default = $config->timezone->default;

	foreach ($arrtimezones as $zone)
	{
		$opt = '<option';
		if (isset ($tz_default) && $tz_default == $zone)
		{
			$opt .= ' selected="selected"';
		}
		echo ($opt . " value=\"$zone\">$zone</option>" . PHP_EOL);
	}

    ?>
	</select></td>
  </tr>

  <tr>
	<td>Updates</td>
	<td><select name="startupdate" id="startupdate">
		<option value="update-none">no updates</option>
		<option value="update-smt">local SMT</option>
		<option value="update-reg">registration code</option>
		<option value="update-opensuse">OpenSuSE only</option>
	</select></td>
  </tr>
				
				
  <tr>
	<td>Registration Email</td>
	<td><input type="text" name="update-reg-email" value="bill.gates@microsoft.com"/></td>
  </tr>
  
  <tr>
	<td>Registration Code for product</td>
	<td><input type="text" name="rcode" id="rcode_product" value="666-666-666"/></td>
  </tr>

  <tr>
	<td>Registration Code for add-on repo #1:</td>
	<td><input type="text" name="rcode" id="rcode_product" size="" value="123-456-789" /></td>
	<td><input type="button" onclick="anotherrcode()" value="+" /></td>
  </tr>

  <tr>
	<td>Installation options (optional): </td>
        <td>
		<input type="text" name="installoptions" size="" value="<?php echo $installoptions; ?>" /> 
        	<?php 
		if($installoptions_warning != "") 
			{echo ("</br> <font color=\"red\" >$installoptions_warning</font>");} 
		?>
        </td>
	<td colspan="2"> (e.g. <em>vnc=1 vncpassword=12345678</em>) </td>
  </tr>
 
  <tr>
	<td colspan="4">
		<strong>Note:</strong> Don't put any sensitive passwords, since it is plain text. VNC passwords must be 8+ bytes long.
	</td>
  </tr>

