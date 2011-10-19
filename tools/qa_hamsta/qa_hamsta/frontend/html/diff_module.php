<?php
/* ****************************************************************************
  Copyright © 2011 Unpublished Work of SUSE. All Rights Reserved.
  
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
     * Contents of the <tt>diff_module</tt> page  
     */
    if (!defined('HAMSTA_FRONTEND')) {
        $go = 'diff_module';
        return require("index.php");
    }
?>

<table class="list">
    <tr>
        <th>Element</th>
        <th>Configuration <?php echo($configuration1->get_id()); ?></th>
        <th>Configuration <?php echo($configuration2->get_id()); ?></th>
    </tr>
    <?php foreach ($elements as $part_id => $part): ?>
        <tr>
            <td colspan="3" class="module_part_head">
                <?php 
                    echo ($module1->get_element($part_id, "Description")
                        ? $module1->get_element($part_id, "Description")
                        : $module2->get_element($part_id, "Description"));
                ?>
            </td>
        </tr>
        <?php foreach ($part as $element_name): ?>
            <tr <?php
                if ($module1->get_element($part_id, $element_name) != $module2->get_element($part_id, $element_name)) {
                    echo('class="diff"');
                }
            ?>>
                <td><?php echo($element_name); ?></td>
                <td><?php echo($module1->get_element($part_id, $element_name)); ?></td>
                <td><?php echo($module2->get_element($part_id, $element_name)); ?></td>
            </tr>
        <?php endforeach; ?>
    <?php endforeach; ?>
</table>
