<?php
    /**
     * Contents of the <tt>jobruns</tt> page  
     */
    if (!defined('HAMSTA_FRONTEND')) {
        $go = 'jobruns';
        return require("index.php");
    }
?>

<table class="list text-main">
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

