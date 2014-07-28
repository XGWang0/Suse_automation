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

  <div class="row">
    <label for="virtcpu">Virtualized CPU count (optional) </label>
    <select id="virtcpu" name="virtcpu"><option value="0">default</option>
          <?php 
			for($i=1;$i<=8;$i++) {
				echo "<option value=\"$i\">$i</option>";
			}
		  ?>
		</select>
  </div>

  <div class='row'>
    <label for="virtinitmem">Virtualized memory size (optional)</label>
    Initial memory <input type="text" id="virtinitmem" name="virtinitmem" size="4"> MB
  </div>

  <div class='row'>
    <label for="virtmaxmem">Available memory <?php echo "$virtavaimem"; ?> MB</label>
    Maximum memory <input type="text" id="virtmaxmem" name="virtmaxmem" size="4"> MB
  </div>

  <div class='row'>
    <label for="virtdiskdef">Virtual disks (optional)<br/>
			Available disk space <b><?php echo "$virtavaidisk"; ?>B</b></label>
    <input type="checkbox" id="virtdiskdef" name="virtdiskdef" onclick="showvirtdisk()">use one disk with default type and size
  </div>

  <div id="virtdisk">   
      <div id="additional_disk" class='row'>
        <label for="virdisktypes"> </label> 
        <span id="additional_disk">
          <label/>Virtual disk type </label> 
          <select id="virtdisktypes" name="virtdisktypes[]"><?php foreach ($virtdisktypes as $type) { echo "<option value=\"$type\">$type</option>"; } ?>
          </select>, disk size
            <input type="text" id="virtdisksizes" title="Insert a dot for default size" name="virtdisksizes[]" size="4" value=".">&nbsp;GB&nbsp;(insert a dot "." for default size)&nbsp;<input type="button" size="5" onclick="anotherdisk()" value="+">
        </span>
      </div>
  </div>
