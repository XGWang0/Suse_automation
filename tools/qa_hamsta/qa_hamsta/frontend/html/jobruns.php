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
        <th colspan="3">last</th>
    </tr>
<?php 
$i=1000;
$ii=0;
foreach ($jobs as $job):
	$job_link='index.php?go=job_details&amp;id='.$job->get_id();
	$i++;
?>        <tr data-tt-id="<?php echo $i; ?>" >
	    <td><a href="<?php echo $job_link; ?>"><?php echo($job->get_id()); ?></a></td>
		<td><span class="<?php echo($job->get_status_string()); ?>">
            	    <?php echo($job->get_status_string()); ?></span>
		</td>
<?php
$mach = $job->get_machine();
$cls = '';
$hostname = '';
if (isset ($mach)) {
	$hostname = '<a href="index.php?go=machine_details&amp;id='.$mach->get_id().'">'
		. $mach->get_hostname() . '</a>';
	$cls = ' class="' . get_machine_status_class ($mach->get_status_id ()) . '"';
}
print "            <td$cls>$hostname</td>";
print "            <td><a href=\"$job_link\">".$job->get_name()."</a></td>\n";
?>
            <td><?php echo($job->get_started()); ?></td>
            <td><?php echo($job->get_stopped()); ?></td>
            <td align="center">
<?php

if (isset ($user) && $job->can_cancel()
    && ($rh->hasReservation ($mach, $user)
	|| $user->isAdmin())) {
	echo "<a href=\"index.php?go=jobruns&amp;action=cancel&amp;id=" . $job->get_id() . "\">Cancel</a>";
}
else
{
	echo "-";
}

?>
            </td>
	    <td colspan="2">last</td>
        </tr>


<?php
    $sub_machines = $job->get_machines(); 
    foreach($sub_machines as $sub_machine):
    $ii++;
?>
    <tr data-tt-id="<?php echo $ii; ?>"   data-tt-parent-id="<?php echo $i; ?>" >
    <td><a href="#"> <?php echo "sub_job_id"; ?></a> </td>
    <td><span class="<?php echo($job->get_status_string()); ?>">
       <?php echo($job->get_status_string()); ?></span>
    </td>
<?php
    $submachine=Machine::get_by_id($sub_machine['machine_id']);
    $subhostname = '<a href="index.php?go=machine_details&amp;id='.$sub_machine['machine_id'].'">'
    . $submachine->get_hostname() . '</a>';
    print "<td>$subhostname</td>";
?>
    <td> <?php echo $sub_machine['short_name'] ?> </td>
    <td> <?php echo $sub_machine['start'] ?> </td>
    <td> <?php echo $sub_machine['stop'] ?> </td>
    <td> <?php echo "not reserve for some" ?> </td>
    <td> <?php echo "machine id is".$sub_machine['machine_id'] ?> </td>
    </tr>
<?php endforeach; ?>
<?php endforeach; ?>
</table>
<div id="aaaa" class="float">ex_all</div>
<div id="bbbb" class="float">col_all</div>
<br>

<script>
$("#machinealljobs").treetable( { expandable: true } );
document.getElementById("aaaa").onclick = function() {  $("#machinealljobs").treetable("expandAll"); };
document.getElementById("bbbb").onclick = function() {  $("#machinealljobs").treetable("collapseAll"); };
</script>

<?php
if(! isset($html_refresh_interval)){$html_refresh_interval = 0;};
echo showRefresh("index.php?go=jobruns" .$refresh_page.$refresh_machine  , $html_refresh_interval);
?>
