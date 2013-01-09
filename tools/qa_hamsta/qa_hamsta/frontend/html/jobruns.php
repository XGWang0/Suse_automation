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
     * Contents of the <tt>jobruns</tt> page  
     */
    if (!defined('HAMSTA_FRONTEND')) {
        $go = 'jobruns';
        return require("index.php");
    }
?>

<table class="list text-main" id="machinealljobs">
    <tr>
        <th>ID</th>
        <th>Status</th>
        <th>Hostname</th>
        <th>Name</th>
        <th>Started</th>
        <th>Stopped</th>
        <th>Actions</th>
    </tr>
    <?php foreach ($jobs as $job): ?>
        <tr>
            <td><a href="index.php?go=job_details&amp;id=<?php echo($job->get_id()); ?>"><?php echo($job->get_id()); ?></a></td>
		<td><span class="<?php echo($job->get_status_string()); ?>">
            	    <?php echo($job->get_status_string()); ?></span>
		</td>
            <td><?php if ($job->get_machine()):
                echo('<a href="index.php?go=machine_details&amp;id='.$job->get_machine()->get_id().'">');
                echo($job->get_machine()->get_hostname());
                echo('</a>');
            endif; ?></td>
            <td><?php echo($job->get_name()); ?></td>
            <td><?php echo($job->get_started()); ?></td>
            <td><?php echo($job->get_stopped()); ?></td>
            <td align="center">
<?php

if($job->can_cancel())
{
	echo "<a href=\"index.php?go=jobruns&amp;action=cancel&amp;id=" . $job->get_id() . "\">Cancel</a>";
}
else
{
	echo "-";
}

?>
            </td>
        </tr>
    <?php endforeach; ?>
</table>
<br>
<?php
if(! isset($html_refresh_interval)){$html_refresh_interval = 0;};
echo showRefresh("index.php?go=jobruns" .$refresh_page.$refresh_machine  , $html_refresh_interval);
?>
