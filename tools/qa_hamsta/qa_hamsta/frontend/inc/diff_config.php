<?php
    /**
     * Logic of the diff_config page 
     */
    if (!defined('HAMSTA_FRONTEND')) {
        $go = 'diff_config';
        return require("index.php");
    }

    $configuration1 = Configuration::get_by_id(request_int("config1"));
    $configuration2 = Configuration::get_by_id(request_int("config2"));
    
    $modules = array();
    foreach($configuration1->get_modules() as $module) {
        $modules[] = $module->get_name();
    }
    foreach($configuration2->get_modules() as $module) {
        if (!in_array($module->get_name(), $modules))
            $modules[] = $module->get_name();
    }

    $html_title = "Difference: Config ".$configuration1->get_id()."/".$configuration2->get_id();

?>
