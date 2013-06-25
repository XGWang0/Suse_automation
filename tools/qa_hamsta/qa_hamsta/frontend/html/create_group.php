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
     * Content of the <tt>create_group</tt> page.
     */
    if (!defined('HAMSTA_FRONTEND')) {
        $go = 'create_group';
        return require("index.php");
    }

?>

<h2 class="text-medium text-blue"><?php echo ($action == "edit" ? "Edit group" : "Select machines to add them to group"); ?></h2>

<?php
	if($action == "add" || $action=='edit' )
		echo "<form action=\"index.php?go=create_group\" method=\"post\">";
	else
		echo "<form action=\"index.php?go=create_group\" method=\"post\" onSubmit=\"return checkcheckbox(this)\">";

	if($id)
		echo "<input type=\"hidden\" name=\"id\" value=\"$id\" />\n";

	echo "<table class=\"text-main\">";

	if(($action == "addmachine") || ($action == "create_group")) {
		$i = 0;

		echo "<tr><td colspan=\"2\"><table class=\"text-main\">";

		foreach($machines as $machine) {
			if ($i%6==0) {
				echo "<tr>";
			}
			$machine_id = $machine->get_id();
			$machine_name = $machine->get_hostname();
			$machine_enable_add = 0;
			if(isset($group) && $group != NULL)
			{
				if($group->check_machine_in_group($machine))
					continue;
				$machine_enable_add++;
				echo "<td style=\"padding: 5px;\">" .
				"<input name=a_machines[] type=checkbox value=$machine_id title=\"check one machine at least to add the group below\"/>" .
					"$machine_name " .
				"</td>";
				
			}
			else if($action == "create_group"){
				$machine_enable_add = count($machines);
				echo "<td style=\"padding: 5px;\">" .
                                "<input name=a_machines[] type=checkbox value=$machine_id title=\"check one machine at least to add the group below\" checked=\"checked\"/>" .
                                        "$machine_name " .
                                "</td>";	

			}
			
			if ($i%6==5) {echo "</tr>";}
			if ($i==count($machines)) {echo "end</tr>";}
			$i++;
		}

		if($machine_enable_add == 0){
			echo "<td style=\"padding: 5px;\">" .
                             "<b>There is no more machine could be added to the group, please return the previous page.</b>" .
                             "</td>";
		}

		echo "</table></td></tr>";
	}


	echo "<tr>";

	if(($action == "add") || ($action == "create_group"))
	{
		echo "<td colspan=\"2\" style=\"padding-top: 5px;\"><label><input type=\"radio\" name=\"action\" value=\"$action\" checked>Create new group</label></td>";
	}
	else if($action == "edit")
	{
		echo "<td colspan=\"2\" style=\"padding-top: 5px;\"><label><input type=\"radio\" name=\"action\" value=\"edit\" checked>Edit group details</label></td>";
	}

	if(($action == "add") || ($action == "create_group") || ($action == "edit"))
	{
?>

    </tr>
    <tr>
        <td>Name: </td>
	<td><input name="name" onFocus="document.getElementsByName('action')[0].checked=true"<?php echo ($action == "edit" ? " value=\"$name\"" : ""); ?> /></td>
    </tr>
    <tr>
        <td>Description: </td>
        <td><input name="desc" onFocus="document.getElementsByName('action')[0].checked=true"<?php echo ($action == "edit" ? " value=\"$desc\"" : ""); ?> /></td>
    </tr>
<?php
	}

	if($action == "addmachine" or $action == "create_group")
	{
		$groups = Group::get_all();
		if($groups != NULL) {
?>

    <tr>
    <td colspan="2" style="padding-top:15px"><label><input type="radio" name="action" value="<?php echo ($action=='create_group' ? 'addmachine' : $action); ?>" checked>Add to existing group</label></td>
    </tr>
    <tr>
        <td>Group name: </td>
        <td><select name="id" size="1" onFocus="document.getElementsByName('action')[1].checked=true">
	<?php foreach(Group::get_all() as $group)	{
		$group_id = $group->get_id();
		$group_name=$group->get_name();
		if( $group_id==0 )
			continue;
		if($group_name == $name)
			echo "<option value=\"$group_id\" selected=\"selected\"> $group_name</option>";
		else
			echo "<option value=\"$group_id\" > $group_name</option>";
	} 
            ?>
        </select></td>
    </tr>

<?php
		}
	}

?>

</table>    
<br />
<?php
	switch($action) {
		case "add":
			$button_title = "Create group";
			break;
		case "addmachine":
		case "create_group":
			$button_title = "Add machine";
			break;
		case "edit":
			$button_title = "Edit group";
			break;
	}
?>	

<input type="submit" name="submit" value="<?php echo $button_title;?>">

</form>
