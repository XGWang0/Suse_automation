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
     * Contents of the <tt>job_details</tt> page  
     */
    if (!defined('HAMSTA_FRONTEND')) {
        $go = 'job_details';
        return require("index.php");
    }
?>
<script type="text/javascript" src="js/result_output.js"></script>
<script type="text/javascript" src="js/filter_log.js"></script>
<table class="list text-main">
    <tr>
        <th>Element</th>
        <th>Value</th>
    </tr>
    <tr>
        <td>ID</td>
        <td><?php echo($job->get_id()); ?></td>
    </tr>
    <tr>
        <td>Status</td>
        <td><?php echo($job->get_status_string()); ?></td>
    </tr>
    <tr>
        <td>Hostname</td>
        <td><?php if ($job->get_machine())
		{
		  echo('<a href="index.php?go=machine_details&amp;id='
		       . $job->get_machine()->get_id() . '">'
		       . $job->get_machine()->get_hostname()
		       . '</a>');
		} ?></td>
    </tr>
    <tr>
        <td>Name</td>
        <td><?php echo($job->get_name()); ?></td>
    </tr>
	<tr>
		<td>Description</td>
		<td><?php echo(htmlspecialchars($job->get_description())); ?></td>
	</tr>
    <tr>
        <td>Started</td>
        <td><?php echo($job->get_started()); ?></td>
    </tr>
    <tr>
        <td>Stopped</td>
        <td><?php echo($job->get_stopped()); ?></td>
    </tr>
    <tr>
	<td>QADB Results</td>
<?php
	print "<td>";
	if( $qadb_link != "" ) {
		foreach($qadb_sm as $sm) {
			$smn=preg_replace('/.*=/','',$sm);
			echo "<a href=\"$sm\">Submission #$smn</a> &nbsp; ";
		}
	} else {
		echo "Not available";
	}
?>
    </tr>
    <tr>
        <td>Last output</td>
	<td>
<?php
	if( count($log_table) > 0 ) {
		echo "<div id=\"log_filter\"></div>\n";
		echo "<div id=\"logtextarea\" style=\"height:20em; overflow:auto;\">\n";
		echo "<table id=\"job_log\" class=\"logs\">\n";
		echo "<tr><th>Date/Time</th><th>Type</th><th>Process</th><th>Message</th></tr>\n";
		foreach( $log_table as $row )	{
			$cls = sprintf("class=\"%s\"",$row->get_log_type());
			printf("<tr $cls><td><nobr>%s</nobr></td><td>%s</td><td>%s</td><td>%s</td></tr>\n", $row->get_log_time_string(), $row->get_log_type(), $row->get_log_what(), $row->get_log_text());
		}
		echo "</table></div>\n";
		echo "<script>scrollLog('logtextarea');filter_init('job_log','log_filter',1);</script>\n";
	}?>
	</td>
    </tr>
    <?php if (!$d_return): ?>
    <tr>
        <td>Return code</td>
        <td><?php echo(nl2br(htmlentities($job->get_return_code()))); ?></td>
    </tr>
    <?php endif; ?>
</table>
<br />
<?php if ($d_job): ?>
<a href="index.php?go=job_details&amp;id=<?php echo($job->get_id()); ?>&amp;d_job=0&amp;d_return=<?php echo($d_return); ?><?php echo($refresh_interval.$xml_norefresh); ?>" class="text-main">Don't show XML job description</a>
<?php else: ?>
<a href="index.php?go=job_details&amp;id=<?php echo($job->get_id()); ?>&amp;d_job=1&amp;d_return=<?php echo($d_return); ?><?php echo($refresh_interval.$xml_norefresh); ?>" class="text-main">Show XML job description</a>
<?php endif; ?>
-
<?php if ($d_return): ?>
<a href="index.php?go=job_details&amp;id=<?php echo($job->get_id()); ?>&amp;d_return=0&amp;d_job=<?php echo($d_job); ?><?php echo($refresh_interval.$xml_norefresh); ?>" class="text-main">Don't show returned data</a>
<?php else: ?>
<a href="index.php?go=job_details&amp;id=<?php echo($job->get_id()); ?>&amp;d_return=1&amp;d_job=<?php echo($d_job); ?><?php echo($refresh_interval.$xml_norefresh); ?>" class="text-main">Show returned data</a>
<?php endif; ?>
<?php if(isset ($user) &&  in_array($job->get_status_string(), array('running','connecting') )) { ?>
- <a href="index.php?go=job_details&amp;id=<?php echo($job->get_id()); ?>&amp;finished_job=1" class="text-main">Set finished flag</a>
<?php } ?>
	<!--td>
-	<a href="index.php?xml_file_name=<php echo($job->get_xml_filename()); ?>&amp;go=machines&amp;action=machine_send_job&amp;machines[a_machines]=a_machines&amp;a_machines[0]=<php echo($job->get_machine()->get_id()); >" class="text-main">Resend job</a>
	</td-->
	
<?php if ($d_job): ?>

<h2 class="text-medium text-blue bold">Job description</h2>
<table class="list text-main">
    <tr>
        <td>XML job description</td>
        <td><textarea rows="20" cols="120" readonly="readonly"><?php echo($job->get_xml_job()); ?></textarea></td>
    </tr>
</table>

<?php endif; ?>


<?php if ($d_return): ?>

<h2 class="text-medium text-blue bold">Returned data</h2>
<table class="list text-main">
    <tr>
        <td>Return code</td>
        <td><?php echo(nl2br(htmlentities($job->get_return_code()))); ?></td>
    </tr>
    <tr>
        <td>Return XML</td>
        <td><textarea rows="20" cols="120" readonly="readonly"><?php echo($job->get_return_xml_content()); ?></textarea></td>
    </tr>
</table>

<?php endif; ?>
<br>
<br>
<?php
if(! isset($html_refresh_interval)){$html_refresh_interval = 0;};
echo showRefresh("index.php?go=job_details&amp;id=" . $job->get_id() . "&amp;d_return=" . $d_return . "&amp;d_job=" . $d_job, $html_refresh_interval);
?>
