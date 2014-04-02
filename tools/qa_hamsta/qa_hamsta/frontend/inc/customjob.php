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
	 * Logic of the custom job page 
	 */
	if (!defined('HAMSTA_FRONTEND')) {
		$go = 'customjob';
		return require("../index.php");
	}
	$search = new MachineSearch();
	$a_machines = request_array("a_machines");
	$search->filter_in_array(request_array("a_machines"));
	$machines = $search->query();
	
	$errors = array();

	machine_permission_or_disabled($machines,$perm_send_job);
	if (request_str("submit"))
	{
		machine_permission_or_redirect($machines,$perm_send_job);
		require("inc/job_create.php");

		if(count($errors) == 0)
		{
			if($roleNumber == 1)  # for Single-machine job, send it directly
			{
				foreach ($machines as $machine){
					if ($machine->send_job($filename)) {
						Log::create($machine->get_id(), $user->getLogin (), 'JOB_START', "has sent a \"custom\" job to this machine (Job name: \"" . htmlspecialchars($_POST['jobname']) . "\")");
					} else {
						$errors[] = $machine->get_hostname().": ".$machine->errmsg;
					}
				}
			}
			else    # for multi-machine job, redirect to "multi-machine job detail" page
			{
				$go = "mm_job";
				return require("inc/mm_job.php");
			}
		}
	}
	
	$html_title="Send custom job";

	if (count($errors) != 0) {
        	$_SESSION['message'] = implode("\n", $errors);
        	$_SESSION['mtype'] = "fail";
	} else {
		redirect (array('succmsg' => "The job[s] has/have been successfully sent."));
	}
?>
