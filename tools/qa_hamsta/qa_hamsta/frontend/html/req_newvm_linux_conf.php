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
  <div class='row'>
    <label for='virttype'>Virtualization type </label>
    <select name="virttype" id='virttype'>
        <option <?php if(count($paravirtnotsupported)>0){echo "selected=\"1\"";} ?> value="fv">Full</option>
        <option <?php if(count($paravirtnotsupported)>0){echo "disabled=\"1\"";} else {echo "selected=\"`\"";} ?> value="pv">Para</option>
    </select>
  </div>
  <div class='row'>
    <label for="graphicmode">Graphics mode: (default is gnome for SLED)</label>
    <select name="graphicmode" id="graphicmode">
        <option <?php if(isset($_POST["graphicmode"]) and $_POST["graphicmode"] == "nographic"){echo "selected";} ?> value="nographic">No graphical desktop</option>
        <option <?php if(isset($_POST["graphicmode"]) and $_POST["graphicmode"] == "gnome"){echo "selected";} ?> value="gnome">Gnome desktop</option>
        <option <?php if(isset($_POST["graphicmode"]) and $_POST["graphicmode"] == "kde"){echo "selected";} ?> value="kde">KDE desktop</option>
    </select> (No graphical desktop means xorg desktop for SLED)
  </div>
 
  <div class='row'>
    <label for='repartitiondisk'>Repartition the entire disk?</label>
    <input type="text" size="5" name="repartitiondisk" id="repartitiondisk" value=""/>% of free disk for root partition (e.g.80%; 100%)
  </div>

