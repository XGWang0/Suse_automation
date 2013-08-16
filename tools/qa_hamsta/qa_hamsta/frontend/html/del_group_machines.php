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
     * Content of the <tt>group_del_machines</tt> page.
     */
    if (!defined('HAMSTA_FRONTEND')) {
        $go = 'del_group_machines';
        return require("index.php");
    }
?>

<h2 class="text-medium text-blue">Delete machines from group</h2>
<form action="index.php?go=del_group_machines" method="post" onsubmit="return checkcheckbox(this);">
<table class="list text-main">
	<tr>
		<th>Group</th>
		<th>Machine(s)</th>
		<?php
			echo "<tr><td>";
			echo "$name";
			echo "</td>";
			echo "<td>";
			foreach($machines as $machine){
				$machine_id = $machine->get_id();
				$machine_name = $machine->get_hostname();
				echo "<input type=\"checkbox\" name=\"machine_list[]\" value=\"$machine_id\" title=\"check one machine at least to delete from the group below\"/>$machine_name";
			}
			echo "</td></tr>";
			echo "<input type=\"hidden\" name=\"group\" value=\"$name\" />";
		?>
	</tr>
</table>    
<br />
<input type="submit" name="submit" value="Delete from group">

</form>
