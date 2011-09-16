<?php
    /**
     * Logic of the delete_groups page
     *
     * Deletes the group if the form has been confirmed.
     */
    if (!defined('HAMSTA_FRONTEND')) {
        $go = 'delete_groups';
        return require("index.php");
    }

    $group = Group::get_by_name(request_str("group"));
    
    if (request_int("confirmed")) {
        $group->delete();
        
        $go = "groups";
        return require('inc/groups.php');
    }
    
    $html_title = "Delete Group ".$group->get_name();
?>
