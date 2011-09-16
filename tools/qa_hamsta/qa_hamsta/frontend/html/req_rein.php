  <?php if(count($machines)==1): ?>
    <tr>
	<td> available root partition (optional): </td>
      <td>
        <select name="subpartition" id="subpartition">
        <?php 
             $arr_partitions=explode(',',$root_partitions);
             echo "  <option value=\"\">(use current root partition)</option>\n";
             foreach ($arr_partitions as $partition) {
                 echo "  <option value=\"$partition\">$partition</option>\n";
             } 
        ?>	
        </select>
      </td>
    </tr>
  <?php endif; ?>
  <tr>
	<td>File system for root partition (optional): </td>
	<td>
	  <select name="rootfstype">
		<option <?php if(isset($_POST["rootfstype"]) and $_POST["rootfstype"] == "reiser"){echo "selected";} ?> value="reiser">reiser</option>
		<option <?php if(isset($_POST["rootfstype"]) and $_POST["rootfstype"] == "ext2"){echo "selected";} ?> value="ext2">ext2</option>
		<option <?php if(!isset($_POST["rootfstype"]) or $_POST["rootfstype"] == "ext3"){echo "selected";} ?> value="ext3">ext3</option>
		<option <?php if(isset($_POST["rootfstype"]) and $_POST["rootfstype"] == "xfs"){echo "selected";} ?> value="xfs">xfs</option>
		<option <?php if(isset($_POST["rootfstype"]) and $_POST["rootfstype"] == "jfs"){echo "selected";} ?> value="jfs">jfs</option>
	  </select>
	</td>
  </tr>
  <tr>
    <td>Bootloader placement (Expert option):</td>
      <td>
        <select name="defaultboot">
          <option value="">root, no change</option>
          <option <?php if( isset($_POST["defaultboot"]) and $_POST["defaultboot"] == "root") {echo "selected";} ?> value="root">root, set active</option>
          <option <?php if( isset($_POST["defaultboot"]) and $_POST["defaultboot"] == "MBR") {echo "selected";} ?> value="MBR">MBR, set active</option>
        </select>
       ( Where to place bootloader, if to set the active flag. )
    </td>
  </tr>
  <tr>
	<td>Install and boot into XEN?</td>
	<td><label><input type="checkbox" name="xen" value="xen">Yes, boot into XEN</label>
  </tr>
