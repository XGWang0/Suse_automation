<?php
    /**
     * Logic of the del_machines page
     *
     * Deletes the selected machines.
     */
    if(!defined('HAMSTA_FRONTEND')) {
        $go = 'del_machines';
        return require("index.php");
    }

    if(request_str("submit"))
    {
        $successfulDeletions = array();
        $failedDeletions = array();
        $allmachines = request_array("a_machines");
        foreach($allmachines as $machine_id)
        {
            $machine = Machine::get_by_id($machine_id);
            $machineName = $machine->get_hostname();
            if($machine->del_machine())
            {
                $successfulDeletions[] = "$machineName";
            }
            else
            {
                $failedDeletions[] = "$machineName";
            }
        }

		# Send result to the main page
		if(count($failedDeletions) > 0)
		{
			$_SESSION['message'] = "The following machines failed to delete: " . implode(", ", $failedDeletions) . ".";
			$_SESSION['mtype'] = "error";
		}
		if(count($successfulDeletions) > 0)
		{
			$_SESSION['message'] = "The following machines were successfully deleted: " . implode(", ", $successfulDeletions) . ".";
			$_SESSION['mtype'] = "success";
		}
		
		# Redirect to the main page
		header("Location: index.php");
		exit();
    }
    else if(request_str("cancel"))
    {
		$_SESSION['message'] = "Machine deletion was canceled.";
		$_SESSION['mtype'] = "fail";
		header("Location: index.php");
		exit();
    }

    $search = new MachineSearch();
    $search->filter_in_array(request_array("a_machines"));

    $machines = $search->query();
    
    $html_title = "Delete machines";
?>
