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
?>

  <?php if(count($machines)==1): ?>
    <div class='row'>
	<label for="subpartition">Root partition</label>
        <select name="subpartition" id="subpartition">
        <?php 
             $arr_partitions=explode(',',$root_partitions);
             echo "  <option value=\"\">(use current root partition)</option>\n";
             foreach ($arr_partitions as $partition) {
                 echo "  <option value=\"$partition\">$partition</option>\n";
             } 
        ?>	
        </select>
    </div>
  <?php endif; ?>
  
  <div class='row'>
	<label for="repartitiondisk">Use</label>
	<input type="text" size="5" name="repartitiondisk" id="repartitiondisk" value=""/>% of free disk for root partition
  </div>

  <div class='row'>
	<label for="rootfstype">Filesystem</label>
	  <select name="rootfstype" id="rootfstype">
		<option <?php if(isset($_POST["rootfstype"]) and $_POST["rootfstype"] == "reiser"){echo "selected";} ?> value="reiser">reiser</option>
		<option <?php if(isset($_POST["rootfstype"]) and $_POST["rootfstype"] == "ext2"){echo "selected";} ?> value="ext2">ext2</option>
		<option <?php if(!isset($_POST["rootfstype"]) or $_POST["rootfstype"] == "ext3"){echo "selected";} ?> value="ext3">ext3</option>
		<option <?php if(isset($_POST["rootfstype"]) and $_POST["rootfstype"] == "xfs"){echo "selected";} ?> value="xfs">xfs</option>
		<option <?php if(isset($_POST["rootfstype"]) and $_POST["rootfstype"] == "jfs"){echo "selected";} ?> value="jfs">jfs</option>
	  </select>
  </div>

  <div class='row'>
	<label for="defaultboot">Bootloader</label>
        <select name="defaultboot" id="defaultboot">
          <option value="">root, no change</option>
          <option <?php if( isset($_POST["defaultboot"]) and $_POST["defaultboot"] == "root") {echo "selected";} ?> value="root">root, set active</option>
          <option <?php if( isset($_POST["defaultboot"]) and $_POST["defaultboot"] == "MBR") {echo "selected";} ?> value="MBR">MBR, set active</option>
        </select>
  </div>

  <div class='row'>
	<input id="kexecboot" type="checkbox" name="kexecboot" value="yes"
		<?php if ($requires_kexec) print ' checked="checked"'?>/>
	<label for="kexecboot">Load installation by Kexec</label>
	<?php if ($requires_kexec) print '(Some machine requires kexec for reinstall because it uses grub2.)'; ?>
  </div>

  <div class='row'>
	<input type="checkbox" name="xen" value="xen" id="xen"/>
	<label for="xen">Install and boot into XEN</label>
  </div>
