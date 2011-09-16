<?php
    /**
     * Logic of the machine details page 
     */
    if (!defined('HAMSTA_FRONTEND')) {
        $go = 'machine_details';
        return require("index.php");
    }

    $highlight = request_str("highlight");

    $machine = Machine::get_by_id(request_int("id"));

    $machine_logs = $machine->get_log_entries($machine->get_id(), 20);
    $machine_logs_number = count($machine_logs);

    if ($cid = request_int("config")) {
        $configuration = Configuration::get_by_id($cid);
    } else {
        $configuration = $machine->get_current_configuration();

    }

    $html_title = $machine->get_hostname();

?>
