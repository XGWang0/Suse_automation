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
     * Contents of the <tt>module_details</tt> page  
     */
    if (!defined('HAMSTA_FRONTEND')) {
        $go = 'module_details';
        return require("index.php");
    }
?>

<table class="list">
    <tr>
        <th>Element</th>
        <th>Description</th>
        <th>&nbsp;</th>
    </tr>
    <?php foreach ($module->get_parts() as $part_id => $part): ?>
        <tr>
            <td colspan="3" class="module_part_head"><?php echo($part["Description"]); ?></td>
        </tr>
        <?php foreach($part as $name => $value): ?>
            <tr
                <?php if($module->element_contains_text($part_id, $name, $highlight)): ?>
                class="search_result"
                <?php endif; ?>
            >
                <td><?php echo($name); ?></td>
                <td><?php echo(str_replace(',', ',<wbr/>', nl2br(htmlentities($value)))); ?></td>
                <td><a href="index.php?go=machines&set=Search&show_advanced=on&amp;s_module=<?php echo($module->get_name()); ?>&amp;s_module_element=<?php echo(urlencode($name)); ?>&amp;s_module_element_value=<?php echo(urlencode($value)); ?>">Search</a></td>
            </tr>
        <?php endforeach; ?>
    <?php endforeach; ?>
</table>
