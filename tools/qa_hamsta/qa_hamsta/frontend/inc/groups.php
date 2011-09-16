<?php
    /**
     * Logic of the groups page 
     *
     * Gets all groups
     */
    if (!defined('HAMSTA_FRONTEND')) {
        $go = 'groups';
        return require("index.php");
    }

    $groups = Group::get_all();
    
    $html_title = "Groups";
?>
