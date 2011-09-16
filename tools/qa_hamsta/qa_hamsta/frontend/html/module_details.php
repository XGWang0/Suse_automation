<?php
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
                <td><a href="index.php?go=machines&amp;s_module=<?php echo($module->get_name()); ?>&amp;s_module_element=<?php echo(urlencode($name)); ?>&amp;s_module_element_value=<?php echo(urlencode($value)); ?>">Search</a></td>
            </tr>
        <?php endforeach; ?>
    <?php endforeach; ?>
</table>
