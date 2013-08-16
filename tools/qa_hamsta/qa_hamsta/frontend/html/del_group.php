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
