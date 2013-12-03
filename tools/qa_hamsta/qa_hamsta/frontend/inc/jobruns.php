<?php
/* ****************************************************************************
  Copyright (c) 2013 Unpublished Work of SUSE. All Rights Reserved.
  
  THIS IS AN UNPUBLISHED WORK OF SUSE.  IT CONTAINS SUSE'S
  CONFIDENTIAL, PROPRIETARY, AND TRADE SECRET INFORMATION.  SUSE
  RESTRICTS THIS WORK TO SUSE EMPLOYEES WHO NEED THE WORK TO PERFORM
  THEIR ASSIGNMENTS AND TO THIRD PARTIES AUTHORIZED BY SUSE IN WRITING.
  THIS WORK IS SUBJECT TO U.S. AND INTERNATIONAL COPYRIGHT LAWS AND
  TREATIES. IT MAY NOT BE USED, COPIED, DISTRIBUTED, DISCLOSED, ADAPTED,
  PERFORMED, DISPLAYED, COLLECTED, COMPILED, OR LINKED WITHOUT SUSE'S
  PRIOR WRITTEN CONSENT. USE OR EXPLOITATION OF THIS WORK WITHOUT
  AUTHORIZATION COULD SUBJECT THE PERPETRATOR TO CRIMINAL AND  CIVIL
  LIABILITY.
  
  SUSE PROVIDES THE WORK 'AS IS,' WITHOUT ANY EXPRESS OR IMPLIED
  WARRANTY, INCLUDING WITHOUT THE IMPLIED WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE, AND NON-INFRINGEMENT. SUSE, THE
  AUTHORS OF THE WORK, AND THE OWNERS OF COPYRIGHT IN THE WORK ARE NOT
  LIABLE FOR ANY CLAIM, DAMAGES, OR OTHER LIABILITY, WHETHER IN AN ACTION
  OF CONTRACT, TORT, OR OTHERWISE, ARISING FROM, OUT OF, OR IN CONNECTION
  WITH THE WORK OR THE USE OR OTHER DEALINGS IN THE WORK.
  ****************************************************************************
 */

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
    /* Used also in the ../html/ part. */
    $rh = new ReservationsHelper ();

    if (isset ($user) && request_str("action") == "cancel"
	&& $id = request_int("id")) {
	    $job = JobRun::get_by_id($id);
	    if ($job && $machine = $job->get_machine ()) {
		    if ($rh->hasReservation ($machine, $user)
			|| $user->isAdmin()) {
			    $job->cancel();
		    }
	    }
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
