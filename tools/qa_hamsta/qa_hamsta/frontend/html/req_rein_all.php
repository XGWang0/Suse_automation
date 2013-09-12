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

  Registration &amp; update:
  <input type='radio' id='reg_none' name='startupdate' value='update-none' checked='checked'/><label for='reg_none'>none</label>
  <input type='radio' id='reg_oss'  name='startupdate' value='update-opensuse'/><label for='reg_none'>openSUSE</label>
  <input type='radio' id='reg_smt'  name='startupdate' value='update-smt'/><label for='reg_none'>SMT</label>
  <input type='radio' id='reg_code' name='startupdate' value='update-reg'/><label for='reg_none'>code</label>
  <span id='regmail'>
    <label for='update-reg-mail'>Registration e-mail</label>
    <input id='update-reg-email' type='text' value='' name='update-reg-email'/>
  </span>
  </br>
  <div class='row' id='smt'>
<?php
  print "SMT server: <strong>$config->smtserver</strong> (<strong>Note:</strong> This has to be configured in config.ini by admin.)."
        . "<input type='hidden' value= $config->smtserver name='update-smt-url' />";

?>
  </div>
  <div class='row'>
	<label for="repo_products">Product</label> 
	<select name="repo_products" id="repo_products" class='url'></select>
	<input type='radio' class='arch' name='product_arch' id='product_arch1' checked='checked' value='x86_64'/>
	<label for='product_arch1'>x86_64</label>
	<input type='radio' class='arch' name='product_arch' id='product_arch2'  value='i586'/>
	<label for='product_arch1'>i586</label>
	<label for='repo_produceurl' class='url'>URL</label>
	<input type="text" name="repo_producturl" id="repo_producturl" class='url'  value="<?php if(isset($_POST["repo_producturl"])){echo $_POST["repo_producturl"];} ?>" title="required: url" />
	<span class='rcode'>
		<label for='rcode_product'>Reg.code</label>
		<input type='text' class='regprefix' name='regprefix_product' id='regprefix_prod' value=''/>
		<input type='text' class='regcode'   name='rcode_product'     id='rcode_product'  value=''/>
	</span>
  </div>

  <div class='row addons' id='first-addon'>
	<label for="addon_products">Add-on 0</label>
	<select name="addon_products" id="addon_products" class="url"></select>
	<input type='radio' class='arch' name='addon0_arch' id='addon0_arch1' checked='checked' value='x86_64'/>
	<label for='addon0_arch1'>x86_64</label>
	<input type='radio' class='arch' name='addon0_arch' id='addon_arch2'  value='i586'/>
	<label for='addon_arch2'>i586</label>
	<label for='addon_producturl' class='url'>URL</label>
	<input type="text" name="addon_url[]" id="addon_producturl" class='url' value="<?php if(isset($_POST["addon_producturl"])){echo $_POST["addon_producturl"];} ?>" />
	<span class='rcode'>
		<label for="rcode_product">Reg.code</label>
		<input type='text' class='regprefix' name="regprefox[]" id='regprefix0' value=''/>
		<input type='text' class='regcode'   name="regcode[]" id='rcode_a0' value=''/>
	</span>
	<div class="addon_btns">
		<label for='addon1'><input type='button' class='addonbtn' value='+' onclick='anotherrepo()'/></label>
		<input type='button' class='addonbtn disabled' value='-'/>
	</div>
  </div>

  <div class='row'>
	  <fieldset>
		<legend>
		<label for="typicmode">Installation type</label>
		  <select name="typicmode" id="typicmode">
  			<option value="text">Text</option>
  			<option value="gnome">Default Gnome</option>
			<option value="kde">Default KDE</option>
			<option value="full">Full distro</option>
		  </select>
		<span id='patterns_modified' class='modified'></span>
		</legend>
		<div id="available_patterns" class=''></div>
		<div id="addon_patterns"><div id="addon_pattern_1"></div></div>
	</fieldset>
  </div>

  <div id="more_patterns" class='row'>
	<label for="patterns">Additional patterns</label>
        <input type="text" name="patterns"/>
  </div>

  <div class='row'>
	<label for="additionalrpms">Additional packages</label>
	<input type="text" name="additionalrpms" value="<?php if(isset($_POST["additionalrpms"])){echo $_POST["additionalrpms"];} else echo ($config->lists->arlist);?>" />
  </div>

  <div class='row'>
	<label for='timezone'>Timezone</label>
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
	</select>
  </div>

  <div class='row'>
	<label for="installoptions">Installation options </label>
	<input type="text" name="installoptions" value="<?php echo $installoptions; ?>" /> 
        <?php 
		if ($installoptions_warning != "") 
			{echo ("</br> <font color=\"red\" >$installoptions_warning</font>");} 
	?>
	<span> (e.g. <em>vnc=1 vncpassword=12345678</em>) </span>
  </div>
 
  <div class='row note'>
	<strong>Note:</strong> Don't put any sensitive passwords, since it is plain text. VNC passwords must be 8+ bytes long.
  </div>

