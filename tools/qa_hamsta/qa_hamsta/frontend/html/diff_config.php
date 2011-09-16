<?php
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
