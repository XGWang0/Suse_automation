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
  <tr>
        <td>Load installation by Kexec?</td>
        <td><label><input type="checkbox" name="kexecboot" value="yes">Yes, load by Kexec.</label></td>
  </tr>

