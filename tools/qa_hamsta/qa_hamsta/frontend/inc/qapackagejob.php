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
	 * Logic of the qapackage job page
	 */

	if( !defined('HAMSTA_FRONTEND') )
	{
		$go = 'qapackagejob';
		return require("../index.php");
	}

	$search = new MachineSearch();
	$search->filter_in_array(request_array("a_machines"));
	$machines = $search->query();

	machine_permission_or_redirect($machines,$perm_send_job);

	$tslist = $_POST['testsuite'];
	$rand = rand();
	$qapackagejobfile = "/tmp/qapackagejob_$rand.xml";
	$email = $_POST['mailto'];
	system("cp /usr/share/hamsta/xml_files/templates/qapackagejob-template.xml $qapackagejobfile");
	system("sed -i '/<mail notify=/c\\\t<mail notify=\"1\">$email<\/mail>' $qapackagejobfile");

	# If the list of packages to run is three or less, we show the full list in the job name
	$numberOfTests = count($tslist);
	if( $numberOfTests <= 3 )
	{
		$jobname = implode(" ", array_slice($tslist, 0, $numberOfTests));
	}
	# Otherwise, we just show how many are being run and save the full list for the description
	else
	{
		$jobname = "$numberOfTests packages";
	}
	system("sed -i 's/TS_LIST_SHORT/$jobname/g' $qapackagejobfile");

	# Change the long definition of TS_LIST (this must go *after* the 'sed' on TS_LIST_SHORT)
	system("sed -i 's/TS_LIST/" . implode(" ", $tslist) . "/g' $qapackagejobfile");

	# Check UI test cases
	$UISetupComm = "\/usr\/share\/qa\/tools\/setupUIAutomationtest; sleep 60";
	$UIlist = $config->lists->uilist;
	$UIarr = split(" ", $UIlist);
	foreach ( $UIarr as $case ) {
		if ( in_array($case, $tslist) ) {
			system("sed -i 's/#setupUI/". $UISetupComm . "/g' $qapackagejobfile");
			break;
		}
	}

	# Make sure each job gets sent correctly
	if( request_str("submit") )
	{
		foreach( $machines as $machine )
		{
			if( $machine->send_job($qapackagejobfile) )	{
				Log::create($machine->get_id(), $user->getLogin (), 'JOB_START', "has sent a \"qa-package\" job to this machine (Job name: \"" . htmlspecialchars($jobname) . "\")");
			} else {
				$error = (empty($error) ? "" : $error) . "<p>" . $machine->get_hostname() . ": " . $machine->errmsg . "</p>";
			}
		}
	}
	if (empty($error)) {
		redirect("The job[s] has/have been successfully sent.",true);
	}
	$html_title="Send qapackage job";
?>
