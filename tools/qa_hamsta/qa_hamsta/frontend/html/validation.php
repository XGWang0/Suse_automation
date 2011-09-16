<form action="index.php?go=validation" method="post" name="validation" onsubmit="return checkcheckbox(this);">
<p>
<b>Validate this build: </b>
<select name="buildnumber" id="buildnumber" style="width: 200px;">
<?php
    $json = file_get_contents(REPO_INDEX_URL);
    if ($json != ""){
        $tmp = array();
        foreach(json_decode($json) as $iso)
            $tmp[] = $iso->{"product"};
        foreach(array_unique($tmp) as $buildnr)
            echo "<option value=$buildnr>$buildnr</option>";
    }
?>
</select>
<br><b>SDK repo URL (only required by some test suites): </b>
<input type="text" name="sdk_producturl" id="sdk_producturl" size="55" value="<?php if(isset($_POST["sdk_producturl"])){echo $_POST["sdk_producturl"];}?>" />
</p>
<table>
	<?php
		echo "Please choose which arch(s) you want to validate:<br/></p>";
		$i=0;
		while (list($key, $value) = each($vmlist)) {
			if ($i%4==0) {echo "<tr>";}
			if ($value != "N/A") {
				$machine=Machine::get_by_ip($value);
				if ($machine) { 
					echo "<td><input name=validationmachine[] type=checkbox value=$key />$key,(".$machine->get_hostname()." IP: ".$value.")&nbsp;&nbsp</td>";
				} else {
					echo "<td><b>Please check if $value is reachable!</b></td>";
				}
			}
			if ($i%4==3) {echo "</tr>";}
			if ($i==count($vmlist)) {echo "</tr>";}
			$i++;
		}
	?>
</table>
<p>Write your email here: <input type="text" name="mailto" value="<?php if(isset($_POST["mailto"])){echo $_POST["mailto"];} ?>" />
<a onmouseout="MM_swapImgRestore()" onmouseover="MM_swapImage('qmark','','../hamsta/images/qmark1.gif',1)">
<img src="../hamsta/images/qmark.gif" name="qmark" id="qmark" border="0" width="18" height="20" title="click me for clues of email" onclick="window.open('../hamsta/helps/email.html','channelmode', 'width=550, height=450, top=250, left=450')"/></a>
<br /><br />
<input type="submit" name="submit" value="Start Validation"></form>

