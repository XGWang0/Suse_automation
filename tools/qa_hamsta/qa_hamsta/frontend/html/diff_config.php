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
     * Contents of the <tt>diff_config</tt> page  
     */
    if (!defined('HAMSTA_FRONTEND')) {
        $go = 'diff_config';
        return require("index.php");
    }
?>


<h2>Difference of configurations</h2>
<table class="list">
    <tr>
        <th>Module</th>
        <th colspan="2">Configuration <?php echo($configuration1->get_id()); ?></th>
        <th colspan="2">Configuration <?php echo($configuration2->get_id()); ?></th>
    </tr>
    <?php foreach ($modules as $module_name): ?>
        <tr <?php
            if (is_null($configuration1->get_module($module_name)) || is_null($configuration2->get_module($module_name))
                || ($configuration1->get_module($module_name)->get_version() != $configuration2->get_module($module_name)->get_version())) {
                echo('class="diff"');
            }
        ?>>
            <td><a href="index.php?go=diff_module&amp;name=<?php echo($module_name); ?>&amp;config1=<?php echo($configuration1->get_id()); ?>&amp;config2=<?php echo($configuration2->get_id()); ?>"><?php echo($module_name); ?></a></td>
            
            <td>
                <?php if(!is_null($configuration1->get_module($module_name))):
                    echo($configuration1->get_module($module_name)->__toString()); 
                endif; ?>
            </td>
            <td>
                <?php if(!is_null($configuration1->get_module($module_name))): ?>
                    <a href="index.php?go=module_details&amp;module=<?php echo($module_name); ?>&amp;id=<?php echo($configuration1->get_module($module_name)->get_version()); ?>">Show</a>
                <?php endif; ?>
            </td>
            
            <td>
                <?php if(!is_null($configuration2->get_module($module_name))):
                    echo($configuration2->get_module($module_name)->__toString()); 
                endif; ?>
            </td>
            <td>
                <?php if(!is_null($configuration2->get_module($module_name))): ?>
                    <a href="index.php?go=module_details&amp;module=<?php echo($module_name); ?>&amp;id=<?php echo($configuration2->get_module($module_name)->get_version()); ?>">Show</a>
                <?php endif; ?>
            </td>
        </tr>
    <?php endforeach; ?>
</table>
