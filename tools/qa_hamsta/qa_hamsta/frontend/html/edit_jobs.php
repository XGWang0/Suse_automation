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
<form name='edit_jobs' action="index.php?go=edit_jobs" method="post" onsubmit="return (this.submited == 'Cancel' ? true : checkcontents(this));" />
<table name='table_jobs' class="text-main" width="900px">
<p><b>Please edit the job XML file in the form below.</b></p>

<?php require("edit_job.php"); ?>

</table>
<input type="hidden" name="file" value="<?php echo $file; ?>"/>
<input type="hidden" name="machine_list" value="<?php echo $machine_list; ?>"/>
<input type="hidden" name="opt" value="<?php echo $opt; ?>"/>
<input type="submit" name="submit" value="Save" onclick="this.form.submited=this.value;"/>
<input type="submit" name="cancel" value="Cancel" onclick="this.form.submited=this.value;" />
</form>
<p class="text-small"><strong>*</strong> The new name of job XML file, need NOT the suffix(.xml). Please note that if you do not edit the name, the new file will override the old one after you save the new job XML file.</p>