<?php
    /**
     * Content of the <tt>create_group</tt> page.
     */
    if (!defined('HAMSTA_FRONTEND')) {
        $go = 'create_group';
        return require("index.php");
    }

?>

<h2 class="text-medium text-blue"><?php echo ($action == "edit" ? "Edit group" : "Add machines to group"); ?></h2>
<form action="index.php?go=create_group" method="post">
<?php

	if($action == "edit")
	{
		echo "<input type=\"hidden\" name=\"id\" value=\"$id\" />";
	}

?>
<table class="text-main">

<?php

	if($action == "add")
	{

?>

		<tr>
			<th>Machines</td>
			<td><?php
				foreach ($machines as $machine):
					echo('<input type="hidden" name="a_machines[]" value="'.$machine->get_id().'">');
					echo($machine->get_hostname() . "<br>\n");
				endforeach;
			?></td>
		</tr>

<?php

	}

?>

    <tr>

<?php

	if($action == "add")
	{
		echo "<td colspan=\"2\" style=\"padding-top: 5px;\"><label><input type=\"radio\" name=\"action\" value=\"create\" checked>Create new group</label></td>";
	}
	else
	{
		echo "<td colspan=\"2\" style=\"padding-top: 5px;\"><label><input type=\"radio\" name=\"action\" value=\"edit\" checked>Edit group details</label></td>";
	}

?>

    </tr>
    <tr>
        <td>Name</td>
        <td><input name="name" onFocus="document.getElementsByName('action')[0].checked=true"<?php echo ($action == "edit" ? " value=\"$name\"" : ""); ?> /></td>
    </tr>
    <tr>
        <td>Description</td>
        <td><input name="description" onFocus="document.getElementsByName('action')[0].checked=true"<?php echo ($action == "edit" ? " value=\"$description\"" : ""); ?> /></td>
    </tr>

<?php

	if($action == "add" and count($machines) != 0)
	{

?>

    <tr>
        <td colspan="2" style="padding-top:15px"><label><input type="radio" name="action" value="add">Add to existing group</label></td>
    </tr>
    <tr>
        <td>Name</td>
        <td><select name="add_group" size="1" onFocus="document.getElementsByName('action')[1].checked=true">
            <?php foreach(Group::get_all() as $group): ?>
                <option value="<?php echo($group->get_name()); ?>"><?php echo($group->get_name()); ?></option>
            <?php endforeach; ?>
        </select></td>
    </tr>

<?php

	}

?>

</table>    
<br />
<input type="submit" name="submit" value="<?php echo ($action == "edit" ? "Edit" : "Add to"); ?> group">

</form>
