<?php
    /**
     * Logic of the job details page 
     *
     * Gets the information about the job from the database
     */
    if (!defined('HAMSTA_FRONTEND')) {
        $go = 'job_details';
        return require("index.php");
    }

    $job = JobRun::get_by_id(request_int("id"));

    $d_return = request_int("d_return");
    $d_job= request_int("d_job");
    $delete_job= request_int("finished_job");
	if ($delete_job) {
		$job->set_status(4);	
		$job->set_stopped();	

	}
    
    $html_title = "Job ".$job->get_id();

	# Figure out if there are any links to qadb inside the log output (supports multiple submission links from any host, qadb, elzar, etc.)
	$html_log = $job->get_last_log();
	$log_table = $job->get_job_log_entries();
	
	# concat the new log entries to the old $html_log, to make the old code working
	# TODO: fix (there might be a separate DB field for QADB link)
	foreach( $log_table as $row )
		$html_log .= $row->get_log_text() . "\n";
		
	preg_match_all("/http:[^ ]+.php\?submissionID=(\d+)/", $html_log, $logMatches);
	if( empty($logMatches[0]) ) {
		$qadb_link="";
	} else {
		$qadb_link="has";
		$qadb_sm=$logMatches[0];
	}

	genRefresh("job_details");

?>

