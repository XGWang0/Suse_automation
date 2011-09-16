<?php
    /**
     * Logic of the jobs page 
     *
     * Gets all jobs either of one machine or at all, as specified in the HTTP
     * request.
     */
    
    /**
     *  Maximum number of jobs to display on one page
     */
    define("JOBS_PER_PAGE", 20);

    if (!defined('HAMSTA_FRONTEND')) {
        $go = 'jobruns';
        return require("index.php");
    }

    $page = request_int("page");

    if (request_str("action") == "cancel") {
        $job = JobRun::get_by_id(request_int("id"));
        $job->cancel();
    }

    if ($machine = request_int("machine")) {
        $jobs = Machine::get_by_id($machine)->get_all_jobs(JOBS_PER_PAGE, JOBS_PER_PAGE*$page);
        $pages_count = ceil(Machine::get_by_id($machine)->count_all_jobs() / JOBS_PER_PAGE);
        $page_params = "machine=".$machine;
    } else {
        $jobs = JobRun::find_all(JOBS_PER_PAGE, JOBS_PER_PAGE*$page);
        $pages_count = ceil(JobRun::count_all() / JOBS_PER_PAGE);
    }
    
    $html_title = "Jobs";

    genRefresh("jobruns");
?>
