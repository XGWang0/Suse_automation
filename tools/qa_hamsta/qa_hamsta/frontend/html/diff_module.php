<?php
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
