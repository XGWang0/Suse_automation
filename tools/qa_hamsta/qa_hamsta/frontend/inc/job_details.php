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
     * Logic of the job details page 
     *
     * Gets the information about the job from the database
     */
    if (!defined('HAMSTA_FRONTEND')) {
        $go = 'job_details';
        return require("index.php");
    }

    global $config;
    $job = JobRun::get_by_id(request_int("id"));
	$a_machines = $job->get_machine_ids();
    $job_part = $job->get_part_id();
    $job_roles = $job->get_roles();
    $roleNumber = count($job_roles);
    $roleMachines = $job->get_role_machines();
    $d_return = request_int("d_return");
    $d_job= request_int("d_job");
    $delete_job= request_int("finished_job");
# FIXME: if( machine_permission($a_machines,$perm_send_job) ) should be enough
	if (((isset ($user) && machine_permission($a_machines,$perm_send_job)) || !$config->authentication->use ) &&
	$delete_job) {
		$job->set_failed();
	}

    $html_title = "Job ".$job->get_id();
    #find max number of machines in all roles
    $maxSuts = 0;
    foreach ($roleMachines as $id => $data) {
        $maxSuts = (count($data)>$maxSuts)?count($data):$maxSuts;
    }

	# Figure out if there are any links to qadb inside the log output (supports multiple submission links from any host, qadb, elzar, etc.)
	//$html_log = $job->get_last_log();
        $log_table = array();
	$qadb_link = array();
	$qadb_sm = array();
	$partSpan = array();
	foreach ($job_part as $id) {
	    $suts = $job->get_machines_by_part_id($id);
            $part_log = $job->get_job_log_entries($id);

            foreach ($suts as $sut) {
		$mid = $sut['machine_id'];
	        if( !isset($part_log[$mid]) )
		    $part_log[$mid] = array();
                $log_table[$id][$mid] = $part_log[$mid];
		# concat the new log entries to the old $html_log, to make the old code working
		# TODO: fix (there might be a separate DB field for QADB link)
	        $html_log = "";
		foreach( $part_log[$mid] as $row )
			$html_log .= $row->get_log_text() . "\n";
			
		preg_match_all("/http:[^ ]+.php\?submission_id=(\d+)/", $html_log, $logMatches);
		if( empty($logMatches[0]) ) {
			$qadb_link[$id][$mid]="";
		} else {
			$qadb_link[$id][$mid]="has";
			$qadb_sm[$id][$mid]=$logMatches[0];
		}
	    }
	}
	genRefresh("job_details");

?>

