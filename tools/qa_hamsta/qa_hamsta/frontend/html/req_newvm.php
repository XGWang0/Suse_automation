  <tr>
	<td>Virtualization type: </td>
	<td><select name="virttype">
		<option <?php if(count($paravirtnotsupported)>0){echo "selected=\"1\"";} ?> value="fv">Full</option>
		<option <?php if(count($paravirtnotsupported)>0){echo "disabled=\"1\"";} else {echo "selected=\"`\"";} ?> value="pv">Para</option>
	</select></td>
  </tr>
  <tr>
    <td>Virtualizied CPU count (optional): </td>
    <td><select id="virtcpu" name="virtcpu"><option value="0">default</option>
          <?php 
			for($i=1;$i<=8;$i++) {
				echo "<option value=\"$i\">$i</option>";
			}
		  ?>
		</select>
	</td>	
  </tr>
  <tr>
    <td>Virtualizied memory size (optional): <br>Available Memory: <?php echo "$virtavaimem"; ?>MB</td>
    <td>
      Initial Memory (MB):&nbsp;<input type="text" id="virtinitmem" name="virtinitmem" size="4"><br>
      Maximum Memory (MB):&nbsp;<input type="text" id="virtmaxmem" name="virtmaxmem" size="4">
    </td>  
  </tr>
  <tr>
    <td>Virtualizied disks (optional): <br/>Available disk space: <?php echo "$virtavaidisk"; ?>B</td>
    <td>
      <label><input type="checkbox" id="virtdiskdef" name="virtdiskdef" onclick="showvirtdisk()">use one disk with default type & size</label><br/>
      <div id="virtdisk">Virtual Disk type: <select id="virtdisktypes" name="virtdisktypes[]"><?php foreach ($virtdisktypes as $type) { echo "<option value=\"$type\">$type</option>"; } ?>
      </select>&nbsp;&nbsp;
      Virtual Disk size (GB): <input type="text" id="virtdisksizes" name="virtdisksizes[]" size="4">&nbsp;(put a dot "." for default size)&nbsp;&nbsp;<input type="button" size="5" onclick="anotherdisk()" value="+">
      <span id="additional_disk"></span></div>
    </td>
  </tr>
  <tr>
    <td>Graphics mode: (default is gnome for SLED): </td>
    <td><select name="graphicmode" id="graphicmode">
    		<option <?php if(isset($_POST["graphicmode"]) and $_POST["graphicmode"] == "nographic"){echo "selected";} ?> value="nographic">No graphical desktop</option>
    		<option <?php if(isset($_POST["graphicmode"]) and $_POST["graphicmode"] == "gnome"){echo "selected";} ?> value="gnome">Gnome desktop</option>
    		<option <?php if(isset($_POST["graphicmode"]) and $_POST["graphicmode"] == "kde"){echo "selected";} ?> value="kde">KDE desktop</option>
		</select> (No graphical desktop means xorg desktop for SLED)
	</td>
  </tr>
