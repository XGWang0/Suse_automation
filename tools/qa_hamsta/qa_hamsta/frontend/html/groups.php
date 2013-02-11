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
		if(isset($user)){
			$user_id = $user->get_id();

		}
?>

<table class="list text-main">
    <tr>
        <th>Name</th>
        <th>Description</th>
        <th>Machines</th>
        <th colspan="6">Actions</th>
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
		$group_id = $group->get_id();
            ?></td>
	    <td<?php if($group_id==0) print ' colspan="5"' ?>><a href="index.php?go=machines&amp;group=<?php echo $group_name; ?>"><img src="images/icon-list.png" class="icon-small" alt="List machines" title="List machines of group" /></a></td>
<?php 		if( $group_id )	{ ?>
            <td><a href="index.php?go=create_group&amp;action=edit&amp;group=<?php echo $group_name; ?>"><img src="images/icon-edit.png" class="icon-small" alt="Edit group" title="Edit this group" /></a></td>
            <td><a href="index.php?go=create_group&amp;action=addmachine&amp;group=<?php echo $group_name; ?>"><img src="images/icon-add.png" class="icon-small" alt="Add machines" title="Add machines to this group" /></a></td>
            <td><a href="index.php?go=del_group_machines&amp;group=<?php echo $group_name; ?>"><img src="images/icon-remove.png" class="icon-small" alt="Delete machines" title="Delete machines from this group" /></a></td>
	    <td><a href="index.php?go=del_group&amp;group=<?php echo $group_name; ?>"><img src="images/icon-delete.png" class="icon-small" alt="Delete group" title="Delete this group" /></a></td>
<?php } ?>
	    <td><a href="index.php?go=machine_config&amp;group=<?php echo $group_name; ?>"><img src="images/icon-config.png" class="icon-small" alt="Config group" title="Config this group" /></a></td>
        </tr>
    <?php endforeach; ?>
</table>

<?php
	}
?>
<b><a href="index.php?go=create_group&amp;action=add">Create a new empty group</a></b>
