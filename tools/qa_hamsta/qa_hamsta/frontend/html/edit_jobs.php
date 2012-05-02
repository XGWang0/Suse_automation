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

	/**
	 * Contents of the <tt>edit_machines</tt> page 
	 */
	if (!defined('HAMSTA_FRONTEND')) {
		$go = 'edit_jobs';
		return require("index.php");
	}
?>
<script type="text/javascript" src="js/edit_job.js"></script>
<form name='edit_jobs' action="index.php?go=edit_jobs" method="post">
<table name='table_jobs' class="list text-main" width="800px">
<p>Please edit the job XML file in the form below.</p>
<tr>
	<th valign="top" width="20%"><b>*</b> file name </th>
	<td><input type="text\" size="20" name="new_file_name" value= "<?php echo $file_name; ?>" >New name of job XML file, if not edit, the new file will overrid the old one.</td>
</tr>
<tr>
	<th valign="top" width="20%">XML file</th>
	<td width="80%"><textarea cols="90%" rows="30" name="new_file_content"><?php echo $file_content; ?></textarea></td>
</tr>

</table>
<input type="hidden" name="file" value="<?php echo $file; ?>"/>
<input type="hidden" name="new_file_dir" value="<?php echo $new_file_dir; ?>"/>
<input type="hidden" name="machine_list" value="<?php echo $machine_list; ?>"/>
<input type="hidden" name="opt" value="<?php echo $option; ?>"/>
<input type="submit" name="submit" value="Save"/>
<br />
<p class="text-small"><strong>*</strong> The new name of job XML file, need NOT the suffix(.xml). Please note that if you do not edit the name, the new file will override the old one after you save the new job XML file.</p>
</form>
