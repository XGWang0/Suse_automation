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

<?php
/* Check if we have a filesystem type sent from POST request. */
$fstype = request_str ('rootfstype') ? request_str ('rootfstype') : 'default';
$fstypes = array ('default', 'reiser', 'ext2', 'ext3', 'xfs', 'jfs');
$selected = $fstypes[array_search ($fstype, $fstypes)];
?>
  <div class='row'>
	<label for="rootfstype">Filesystem</label>
	  <select name="rootfstype" id="rootfstype" title="The filesystem type for products before SLE 12 and openSUSE 13.1 and below is ext3. Otherwise the installation lets the installator to decide filesystem type based on product version.">
		<?php
		foreach ($fstypes as $type) {
			printf ('<option value="%s"%s>%s</option>' . PHP_EOL,
					$type,
					($selected == $type ? ' selected' : ''),
					$type);
		}
		?>
	  </select>
	  Default option leaves the choice on installer. See option tooltip for more.
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
	<input id="kexecboot" type="checkbox" name="kexecboot" value="yes" />
	<label for="kexecboot">Load installation by Kexec</label>
  </div>

  <div class='row'>
	<input type="checkbox" name="xen" value="xen" id="xen"/>
	<label for="xen">Install and boot into XEN</label>
  </div>
