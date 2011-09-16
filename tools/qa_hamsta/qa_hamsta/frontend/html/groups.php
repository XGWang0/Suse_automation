<?php
    /**
     * Contents of the <tt>groups</tt> page 
     */
    if (!defined('HAMSTA_FRONTEND')) {
        $go = 'groups';
        return require("index.php");
    }

	if(count($groups) == 0)
	{
		echo "<p class=\"text-main\">There are no groups to list.</p>";
		echo "<p class=\"text-main\">To create a group of machines, go to the \"List Machines\" page, select the systems you want to make a group and select \"Add to group\", then click \"Go\". At that point you will be directed to create a new group.</p>";
	}
	else
	{
?>

<table class="list text-main">
    <tr>
        <th>Name</th>
        <th>Description</th>
        <th>Machines</th>
        <th colspan="3">&nbsp;</th>
    </tr>
    <?php foreach ($groups as $group): ?>
        <tr>
            <td><?php echo($group->get_name()); ?></td>
            <td><?php echo($group->get_description()); ?></td>
            <td><?php
                $machines = $group->get_machines(); 

                if (count($machines) < 8) {
                    $first = 1;
                    foreach($machines as $machine):
                        echo(($first ? '' : ', '). $machine->get_hostname());
                        $first = 0;
                    endforeach;
                } else {
                    echo(count($machines) . " machines");
                }
		//convert metadata like: "&" and space
		$group_name = $group->get_name();
		$group_name = str_replace("&","%26",$group_name);
		$group_name = str_replace(" ","%20",$group_name);
            ?></td>
            <td><a href="index.php?go=machines&amp;group=<?php echo $group_name; ?>">List Machines</a></td>
		<td><a href="index.php?go=create_group&amp;action=edit&amp;group=<?php echo $group_name; ?>">Edit</a></td>
            <td><a href="index.php?go=del_group&amp;group=<?php echo $group_name; ?>">Delete</a></td>
        </tr>
    <?php endforeach; ?>
</table>

<?php
	}
?>
<b><a href="index.php?go=create_group">Create a new empty group</a></b>
