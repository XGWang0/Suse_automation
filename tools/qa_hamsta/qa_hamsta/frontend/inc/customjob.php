<?php
	/**
	 * Logic of the custom job page 
	 */
	if (!defined('HAMSTA_FRONTEND')) {
		$go = 'customjob';
		return require("../index.php");
	}
	$search = new MachineSearch();
	$search->filter_in_array(request_array("a_machines"));
	$machines = $search->query();
	$jobname=str_replace(' ', "\ ", str_replace('"', '\"', str_replace("/", "\/", $_POST['jobname'])));
	$debuglevel=$_POST['debuglevel'];
	$description=str_replace('"', '\"', str_replace("/", "\/", $_POST['description']));
	$motdmsg=str_replace('"', '\"', str_replace("/", "\/", $_POST['motdmsg']));
	$mailto=$_POST['mailto'];
	$rpmlist=$_POST['rpmlist'];
	$commands=$_POST['commands'];
	$commandsSplit = explode("\n", $commands);
	$commandArray = array();
	foreach($commandsSplit as $singleCommand)
	{
		$singleCommandTrimmed = trim($singleCommand);
		if($singleCommandTrimmed != "")
		{
			$commandArray[] = $singleCommandTrimmed;
		}
	}
	$addtopredefine=$_POST['addtopredefine'];

	$rand = rand();
	$customjobfile = "/tmp/customjob_$rand.xml";
	system("cat /usr/share/hamsta/xml_files/templates/customjob-template1.xml > $customjobfile");
	system("sed -i -e \"s/JOBNAME/$jobname/g\" -e \"s/DEBUGLEVEL/$debuglevel/g\" -e \"s/MAILTO/$mailto/g\" -e \"s/RPMLIST/$rpmlist/g\" -e \"s/DESCRIPTION/$description/g\" -e \"s/MOTDMSG/$motdmsg/g\" $customjobfile");
	$fh = fopen($customjobfile, 'a');
	fwrite($fh, implode("\n", $commandArray) . "\n");
	fclose($fh);
	system("cat /usr/share/hamsta/xml_files/templates/customjob-template2.xml >> $customjobfile");
	if ($addtopredefine=="addtopredefine")
	system("cp $customjobfile /usr/share/hamsta/xml_files/$jobname.xml");

	if (request_str("submit"))
		foreach ($machines as $machine)
			if ($machine->send_job($customjobfile)) {
				Log::create($machine->get_id(), $machine->get_used_by(), 'JOB_START', "has sent a \"custom\" job to this machine (Job name: \"" . htmlspecialchars($_POST['jobname']) . "\")");
			} else {
				$error = (empty($error) ? "" : $error) . "<p>".$machine->get_hostname().": ".$machine->errmsg."</p>";
			}
	if (empty($error))
		header("Location: index.php");
	$html_title="Send custom job";
?>
