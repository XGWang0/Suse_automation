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

	/*
	 * Logic of the autotest job page
	 */

	if( !defined('HAMSTA_FRONTEND') )
	{
		$go = 'autotest';
		return require("../index.php");
	}

	$a_machines = request_array("a_machines");

	if (! isset ($a_machines) || count ($a_machines) < 1)	{
		header ('Location: index.php');
		exit ();
	}

	$job = new Job();

	foreach( $a_machines as $machine ) {
		$job->add_machine_id($machine);
	}

	machine_permission_or_redirect($a_machines,$perm_send_job);

	$atlist = $_POST['testsuite'];
	$rand = rand();
	$autotestjobfile = "/tmp/autotestjob_$rand.xml";
	$email = $_POST['mailto'];
	system("cp /usr/share/hamsta/xml_files/templates/autotest-template.xml $autotestjobfile");
	system("sed -i '/<mail notify=/c\\\t<mail notify=\"1\">$email<\/mail>' $autotestjobfile");

	# If the list of packages to run is three or less, we show the full list in the job name
	# Otherwise, we just show how many are being run and save the full list for the description
	$numberOfTests = count($atlist);
	if( $numberOfTests <= 3 )
		$jobname = implode(" ", array_slice($atlist, 0, $numberOfTests));
	else
		$jobname = "$numberOfTests packages";
	system("sed -i 's/AT_LIST_SHORT/$jobname/g' $autotestjobfile");

	# Change the long definition of AT_LIST (this must go *after* the 'sed' on AT_LIST_SHORT)
	system("sed -i 's/AT_LIST/" . implode(" ", $atlist) . "/g' $autotestjobfile");

  $job->addfile($autotestjobfile);
	# Make sure each job gets sent correctly
	$error='';
	if( request_str("submit") )	{
		if ( $job->send_job() ){
			foreach( $a_machines as $machine ) {
				Log::create($machine, $user->getLogin (), 'JOB_START', "has sent an \"autotest\" job to this machine (Job name: \"" . htmlspecialchars($jobname) . "\")");
			}
		}else{
			$error = $job->errmsg;
		}
	}
	if (empty($error))
	redirect(array('succmsg'=>"The job[s] has/have been successfully sent."));
	$html_title="Send autotest job";
?>
