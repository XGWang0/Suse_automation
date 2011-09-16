<?php

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

	# Make sure each job gets sent correctly
	if( request_str("submit") )
	{
		foreach( $machines as $machine )
		{
			if( $machine->send_job($qapackagejobfile) )	{
				Log::create($machine->get_id(), $machine->get_used_by(), 'JOB_START', "has sent a \"qa-package\" job to this machine (Job name: \"" . htmlspecialchars($jobname) . "\")");
			} else {
				$error = (empty($error) ? "" : $error) . "<p>" . $machine->get_hostname() . ": " . $machine->errmsg . "</p>";
			}
		}
	}
	if (empty($error)) {
		header("Location: index.php");
	}
	$html_title="Send qapackage job";

?>
