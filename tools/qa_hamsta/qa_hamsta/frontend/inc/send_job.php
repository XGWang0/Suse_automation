<?php
    /**
     * Logic of the send_job page 
     */
    if (!defined('HAMSTA_FRONTEND')) {
        $go = 'send_job';
        return require("index.php");
    }
	// print_r($_REQUEST);
    $search = new MachineSearch();
    $search->filter_in_array(request_array("a_machines"));
    $machines = $search->query();

    $resend_job=request_str("xml_file_name");
    $filenames =request_array("filename");

	if (request_str("submit")) {

		$email = request_str("mailto");
		$jobfilenames = array();

		foreach ($filenames as $jobfile) {
			$jobbasename = basename($jobfile);
			system("cp $jobfile /tmp/");
			system("sed -i '/<mail notify=/c\\\t<mail notify=\"1\">$email<\/mail>' /tmp/$jobbasename");
			array_push ($jobfilenames, "/tmp/$jobbasename");
		}

		foreach ($machines as $machine) {
			foreach ($jobfilenames as $filename) {
				if ($machine->send_job($filename)) {
				    Log::create($machine->get_id(), $machine->get_used_by(), 'JOB_START', "has sent a \"pre-defined\" job to this machine (Job name: \"" . htmlspecialchars(basename($filename)) . "\")");
				} else {
					$error = (empty($error) ? "" : $error) . "<p>".$machine->get_hostname().": ".$machine->errmsg."</p>";
				}
			}
		}
		if (empty($error)) {
			header("Location: index.php");
		}
	}
    $html_title = "Send job";
?>
