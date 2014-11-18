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
        <th colspan="<?php echo $roleNumber?>">Value</th>
    </tr>
    <tr>
        <td>ID</td>
        <td colspan="<?php echo $roleNumber?>"><?php echo($job->get_id()); ?></td>
    </tr>
    <tr>
        <td>Status</td>
        <td colspan="<?php echo $roleNumber?>">
	  <span class="<?php echo($job->get_status_string()); ?>">
	  <?php echo($job->get_status_string()); ?>
	  </span>
	</td>
    </tr>
    <tr>
        <td>Name</td>
        <td colspan="<?php echo $roleNumber?>"><?php echo($job->get_name()); ?></td>
    </tr>
	<tr>
		<td>Description</td>
		<td colspan="<?php echo $roleNumber?>"><?php echo(htmlspecialchars($job->get_description())); ?></td>
	</tr>
    <tr>
        <td></td>
<?php
foreach ($job_roles as $id => $name) {
    echo "<th>".strtoupper($name)."</th>";
}
?>
    </tr>

<?php
$i=1;
foreach ($job_part as $part_id) {
    $machines = $job->get_machines_by_part_id($part_id);
?>
    <tr>
      <th rowspan="<?php echo $maxSuts?>" class="vtop">
        <input type="checkbox" name="part_log" id="part_<?php echo $i ?>" onChange="logToggle(this)">
        <label id="part_<?php echo $i ?>_lbl" for="part_<?php echo $i ?>">Part:<?php echo $i;?></label>
      </th>
<?php
for($m=0;$m<$maxSuts;$m++) {
foreach ($job_roles as $id => $name) {
    $role_suts = $roleMachines[$id];
    if(isset($role_suts[$m])) {
        $mid = $role_suts[$m];
        if(isset($machines[$mid])) {
            $sut = $machines[$mid];
	    $sid = $sut['job_status_id'];
            $status = $job->get_status_string($sid);
	    $hostname = Machine::get_by_id($mid)->get_hostname();
?>
      <td>
      <table id="log_tbl" class="list text-main">
      <tr>
        <th>
          <span class="<?php echo $status; ?>"><?php echo $status; ?></span>
        </th>
        <th width="100%">
         <a href="index.php?go=machine_details&amp;id=<?php echo $mid?>">
         <?php echo $hostname ?>
	 </a>
        </th>
      </tr>
    <tbody id="part_<?php echo $i ?>_log">
    <tr>
        <td>Started</td>
        <td><?php echo($job->get_started($part_id,$mid)); ?></td>
    </tr>
    <tr>
        <td>Stopped</td>
        <td><?php echo($job->get_stopped($part_id,$mid)); ?></td>
    </tr>
    <tr>
	<td>QADB Results</td>
	<td>
<?php
	if( $qadb_link[$part_id][$mid] != "" ) {
		foreach($qadb_sm[$part_id][$mid] as $sm) {
			$smn=preg_replace('/.*=/','',$sm);
			echo "<a href=\"$sm\">Submission #$smn</a> &nbsp; ";
		}
	} else {
		echo "Not available";
	}
?>
       </td>
    </tr>
    <tr>
        <td>Last output</td>
	<td>
<?php
	if( count($log_table[$part_id][$mid]) > 0 ) {
		echo "<div id=\"log_filter$id$part_id$mid\" class=\"logs\"></div>\n";
		echo "<div id=\"logtextarea\" style=\"height:20em; overflow:auto;\">\n";
		echo "<table id=\"job_log$id$part_id$mid\" class=\"logs\" width=\"100%\">\n";
		echo "<thead><tr><th>Date/Time</th><th>Type</th><th>Process</th><th>Message</th></tr></thead>\n";
		foreach( $log_table[$part_id][$mid] as $row )	{
			$cls = sprintf("class=\"%s\"",$row->get_log_type());
			printf("<tr $cls><td><nobr>%s</nobr></td><td>%s</td><td>%s</td><td>%s</td></tr>\n", $row->get_log_time_string(), $row->get_log_type(), $row->get_log_what(), $row->get_log_text());
		}
		echo "</table></div>\n";
		echo "<script>scrollLog('logtextarea');filter_init('job_log$id$part_id$mid','log_filter$id$part_id$mid',1);</script>\n";
	}?>
	</td>
    </tr>
    <tr>
        <td>Job Part XML</td>
        <td>
          - <input id="xml<?php echo $part_id.$mid ?>" type="checkbox" name="xmls" class="partxml">
          <label class="pointer" for="xml<?php echo $part_id.$mid ?>"><u>Show/Hide XML</u></label>
          <textarea class="job_xml" rows="20" cols="90" readonly="readonly" id="xml<?php echo $part_id.$mid ?>">
          <?php echo(file_get_contents($sut['xml_file'])); ?>
          </textarea>
        </td>
    </tr>
    </tbody>
    </table>
    </td>
<script>
var TSort_Data = new Array ('job_log<?php echo $id.$part_id.$mid; ?>','d');
var TSort_Icons = new Array ('<span class="text-blue sorting-arrow">&uArr;</span>', '<span class="text-blue sorting-arrow">&dArr;</span>');
tsRegister();
</script>
<?php } else { ?>
    <td></td>        
<?php } ?>
<?php } else { ?>
    <td></td>
<?php } ?>
<?php } ?>
</tr>
<?php } ?>
<?php $i++; } ?>
</table>
<br />
<?php if ($d_job): ?>
<a href="index.php?go=job_details&amp;id=<?php echo($job->get_id()); ?>&amp;d_job=0&amp;d_return=<?php echo($d_return); ?><?php echo($refresh_interval.$xml_norefresh); ?>" class="text-main">Don't show XML job description</a>
<?php else: ?>
<a href="index.php?go=job_details&amp;id=<?php echo($job->get_id()); ?>&amp;d_job=1&amp;d_return=<?php echo($d_return); ?><?php echo($refresh_interval.$xml_norefresh); ?>" class="text-main">Show XML job description</a>
<?php endif; ?>
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

<br>
<br>
<?php
if(! isset($html_refresh_interval)){$html_refresh_interval = 0;};
echo showRefresh("index.php?go=job_details&amp;id=" . $job->get_id() . "&amp;d_return=" . $d_return . "&amp;d_job=" . $d_job, $html_refresh_interval);
?>
