<?php
    /**
     * Contents of the <tt>del_group</tt> page 
     */
    if (!defined('HAMSTA_FRONTEND')) {
        $go = 'del_group';
        return require("index.php");
    }
?>

<table class="text-main">
    <tr>
        <th>Name:</th>
        <td><?php echo($group->get_name()); ?></td>
    </tr>
    <tr>
        <th>Description:</th>
        <td><?php echo($group->get_description()); ?></td>
    </tr>
    <tr>
        <th>Machines:</th>
        <td><?php
            $machines = $group->get_machines(); 

            if (count($machines) < 5) {
                $first = 1;
                foreach($machines as $machine):
                    echo(($first ? '' : ', '). $machine->get_hostname());
                    $first = 0;
                endforeach;
            } else {
                echo(count($machines) . " machines");
            }
        ?></td>
    </tr>
</table>
<br />
<a href="index.php?go=del_group&amp;group=<?php echo($group->get_name()); ?>&amp;confirmed=1">Confirm delete</a>
