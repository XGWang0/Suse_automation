  <tr>
   	<td>Repartition the entire disk?</td>
	<td><label>Yes, use <input type="text" size="5" name="repartitiondisk" value="<?php if(isset($_POST["repartitiondisk"])){echo $_POST["repartitiondisk"];} ?>">% free disk for root partition(e.g. 80%; 100%)</label></td>
  </tr>
  <tr>
    <td>Upload custom autoyast profile (optional):</td>
    <td><input type="file" name="userfile" id="userfile">
    <input type="button" value="clear" onclick='clear_filebox("userfile")'>
    </td>
  </tr>
  <tr>
	<td>Setup host for running desktop tests?</td>
	<td><label><input type="checkbox" name="setupfordesktop" value="yes">Yes, setup for running desktop test.</label>
  </tr>

