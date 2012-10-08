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

<script>
$(document).ready(function() {
	var archs = Array("i386","x86","x86-xen","x86_64","x86_64-xen","ia64","ppc","s390");
	for(i=0;i<archs.length;i++) {
		$("#"+archs[i]).hide();
	}
});

function validarch(archs) {
	var reg = /i.86/;
	var usedarchs = archs.toString().split(",");

	for(i=0;i<usedarchs.length;i++) {
		if (usedarchs[i] == "x86_64" ) {
			$("#x86_64").show();
			$("#x86_64-xen").show();
		} else if (reg.exec(usedarchs[i])) {
			$("#i386").show();
			$("#x86-xen").show();
		} else {
			$("#"+usedarchs[i]).show();
		}
	}
}
</script>
<form action="index.php?go=validation" method="post" name="validation" onsubmit="return checkcheckbox(this);">
<p>
<b>Validate this build: </b>
<?php
	$json = file_get_contents(REPO_INDEX_URL);
	if ($json != "") {
	    $products = array();
	    $archs = array();
	    foreach(json_decode($json) as $iso) {
	        $products[] = $iso->{"product"};
			if (array_key_exists($iso->{"product"}, $archs)) {
				$archs[$iso->{"product"}] .= "," . $iso->{"arch"};
			} else {
				$archs[$iso->{"product"}] = $iso->{"arch"};
			}
	    }
		echo "<select name=\"buildnumber\" id=\"buildnumber\" style=\"width: 200px;\">\n";
		echo "<option selected=\"\"></option>\n";
		foreach(array_unique($products) as $buildnr) {
			$arch = $archs["$buildnr"];
			echo "<option value=\"$buildnr\" onclick=\"validarch('$arch')\">$buildnr</option>\n";	
		}
		echo "</select>\n";
	}
?>
	
<br><b>SDK repo URL (only required by some test suites): </b>
<input type="text" name="sdk_producturl" id="sdk_producturl" size="55" value="<?php if(isset($_POST["sdk_producturl"])){echo $_POST["sdk_producturl"];}?>" />
</p>
<table>
	<?php
		echo "Please choose which arch(s) you want to validate:<br/></p>\n";
		$i=0;
		while (list($key, $value) = each($vmlist)) {
			if ($i%4==0) {echo "<tr>";}
			if ($value != "N/A") {
				$machine=Machine::get_by_ip($value);
				if ($machine) { 
					echo "<td><div id=\"$key\"><input name=\"validationmachine[]\" type=\"checkbox\" value=\"$key\" />$key,(".$machine->get_hostname()." IP: ".$value.")&nbsp;&nbsp</div></td>\n";
				} else {
					echo "<td><b>Please check if $value is reachable!</b></td>\n";
				}
			}
			if ($i%4==3) {echo "</tr>";}
			if ($i==count($vmlist)) {echo "</tr>";}
			$i++;
		}
	?>
</table>
<p>Write your email here: <input type="text" name="mailto" value="<?php if(isset($_POST["mailto"])){echo $_POST["mailto"];} else if (isset($user)) { echo $user->getEmail(); } ?>" />
<a onmouseout="MM_swapImgRestore()" onmouseover="MM_swapImage('qmark','','../hamsta/images/qmark1.gif',1)">
<img src="../hamsta/images/qmark.gif" name="qmark" id="qmark" border="0" width="18" height="20" title="click me for clues of email" onclick="window.open('../hamsta/helps/email.html','channelmode', 'width=550, height=450, top=250, left=450')"/></a>
<br /><br />
<input type="submit" name="submit" value="Start Validation"></form>
