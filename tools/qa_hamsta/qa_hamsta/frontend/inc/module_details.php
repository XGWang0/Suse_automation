<?php
    /**
     * Logic of the module page 
     */
    if (!defined('HAMSTA_FRONTEND')) {
        $go = 'module_details';
        return require("index.php");
    }

    $module = Module::get_by_name_version(request_str("module"), request_int("id"));
    
    $highlight = request_str("highlight");

    $html_title = $module->get_name() .": ". $module->__toString();

?>
