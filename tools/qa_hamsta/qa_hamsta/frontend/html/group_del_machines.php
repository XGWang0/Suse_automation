<?php
    /**
     * Content of the <tt>group_del_machines</tt> page.
     */
    if (!defined('HAMSTA_FRONTEND')) {
        $go = 'group_del_machines';
        return require("index.php");
    }
?>

<h2 class="text-medium text-blue">Delete machines from group</h2>
<form action="index.php?go=group_del_machines" method="post">
<table class="list text-main">
	<tr>
		<th>Machine</th>
		<th>Group(s)</th>
		<?php
			foreach ($machines as $machine) {
				$machine_id = $machine->get_id();
				echo "<tr>"; 
				echo "<td>";
				//echo ('<input type="hidden" name="a_machines[]" value="'.$machine->get_id().'">');
				echo ($machine->get_hostname());
				echo "</td>";
				echo "<td>";
				foreach (Group::get_groups_by_machine($machine) as $group_id => $group_name) {
					echo "<lable>";
					/* $machine_id_$group_id, correct if you have better methods */
					echo ('<input type="checkbox" name="a_groups[]" value="'.$machine_id.'_'.$group_id.'">');
					echo "$group_name";
					echo "</lable>";
				}
				echo "</td>";
				echo "</tr>";
			}
		?>
	</tr>
</table>    
<br />
<input type="submit" name="submit" value="Delete from group">

</form>
