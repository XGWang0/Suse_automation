<?php
    /**
     * Logic of the diff_module page 
     */
    if (!defined('HAMSTA_FRONTEND')) {
        $go = 'module_details';
        return require("index.php");
    }

    $module_name = request_str("name");

    $configuration1 = Configuration::get_by_id(request_int("config1"));
    $configuration2 = Configuration::get_by_id(request_int("config2"));

    $module1 = $configuration1->get_module($module_name);
    $module2 = $configuration2->get_module($module_name);

    $elements = array();
    foreach($module1->get_parts() as $part_id => $part) {
        foreach($part as $element => $value) {
            if (empty($elements[$part_id]) || !in_array($element, $elements[$part_id]))
                $elements[$part_id][] = $element;
        }
    }
    foreach($module2->get_parts() as $part_id => $part) {
        foreach($part as $element => $value) {
            if (empty($elements[$part_id]) || !in_array($element, $elements[$part_id]))
                $elements[$part_id][] = $element;
        }
    }

    $html_title = "Differences in ". $module_name;

?>
