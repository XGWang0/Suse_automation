<?php
/* ****************************************************************************
  Copyright (c) 2011 Unpublished Work of SUSE. All Rights Reserved.
  
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
	$jobname=str_replace(' ', "\ ", str_replace('"', '\"', str_replace("/", "\/", $_POST['jobname'])));
	$debuglevel=$_POST['debuglevel'];
	$description=str_replace('"', '\"', str_replace("/", "\/", $_POST['description']));
	$motdmsg=str_replace('"', '\"', str_replace("/", "\/", $_POST['motdmsg']));
	$mailto=$_POST['mailto'];
	$rpmlist=$_POST['rpmlist'];
	#$commands=$_POST['commands'];
	$jobType=$_POST['jobType'];
	$roleNumber=($jobType == 1)?1:$_POST['rolenumber'];
	if($roleNumber == 1)
		$commandsArray[] = request_str("commands_content_single");
	else
		$commandsArray = request_array("commands_content_multiple");

	$commandArray = array();
	$errors[] = array();

	for($i=0; $i<$roleNumber; $i++)
	{
		$commandsSplit = explode("\n", $commandsArray[$i]);

		foreach($commandsSplit as $singleCommand)
		{
			$singleCommandTrimmed = trim($singleCommand);
			if($singleCommandTrimmed != "")
			{
				$commandArray[$i][] = $singleCommandTrimmed;
			}
		}
	}

	$addtoCustomJob = $_POST['addtoCustomJob'];

	$rand = rand();
	$filename = "/tmp/customjob_$rand.xml";
	
	#system("cat /usr/share/hamsta/xml_files/templates/customjob-template-1.xml > $filename");
	#system("sed -i -e \"s/JOBNAME/$jobname/g\" -e \"s/DEBUGLEVEL/$debuglevel/g\" -e \"s/MAILTO/$mailto/g\" -e \"s/RPMLIST/$rpmlist/g\" -e \"s/DESCRIPTION/$description/g\" -e \"s/MOTDMSG/$motdmsg/g\" $filename");

	# Read the template file
	$fileTemplateName = "/usr/share/hamsta/xml_files/templates/customjob-template-role.xml";
	$fileTemplate = fopen($fileTemplateName, "r");
	$roleString = fread($fileTemplate, filesize($fileTemplateName));
	fclose($fileTemplate);

	if($roleNumber > 1)
		$fileTemplateName = "/usr/share/hamsta/xml_files/templates/customjob-template-command-role.xml";
	else
		$fileTemplateName = "/usr/share/hamsta/xml_files/templates/customjob-template-command.xml";
	$fileTemplate = fopen($fileTemplateName, "r");
	if($fileTemplate == null)
		$errors[] = "Can not open command file";
	$commandString = fread($fileTemplate, filesize($fileTemplateName));
	fclose($fileTemplate);
	
	$commandsCustom = "";
	$rolesCustom = "";

	$roleName = request_array("rolename");
	$minNumber = request_array("minnumber");
	$maxNumber = request_array("maxnumber");
	for( $i=0; $i<$roleNumber; $i++ )
	{
		$commandLines = "";
		if($roleNumber > 1)
		{
			$rolesCustom .= str_replace("ROLE_ID", $i, str_replace("ROLE_NAME", $roleName[$i], 
					str_replace("ROLE_MIN", $minNumber[$i], str_replace("ROLE_MAX", $maxNumber[$i], $roleString))));
		}
		foreach($commandArray[$i] as $commandLine)
			$commandLines .= $commandLine . "\n";
		$commandsCustom .= str_replace("ROLE_ID", $i, str_replace("COMMANDS", $commandLines, $commandString));
	}

	if($roleNumber > 1)
		$rolesCustom = "<roles>\n" . $rolesCustom . "\n    </roles>";

	$fileTemplateName = "/usr/share/hamsta/xml_files/templates/customjob-template.xml";
	$fileTemplate = fopen($fileTemplateName, "r");
	if($fileTemplate == NULL)
		$errors[] = "Can not open template file";
	$fileCustom = fread($fileTemplate, filesize($fileTemplateName));
	fclose($fileTemplateName);

	$fileCustom = str_replace("ROLES_AREA", $rolesCustom, str_replace("COMMANDS_AREA", $commandsCustom, $fileCustom));

	$fileJob = fopen($filename, "w");
	if($fileJob == NULL)
		$errors[] = "Can not open job file to write";
	fwrite($fileJob, $fileCustom);
	fclose($fileJob);
	system("sed -i -e \"s/JOBNAME/$jobname/g\" -e \"s/DEBUGLEVEL/$debuglevel/g\" -e \"s/MAILTO/$mailto/g\" -e \"s/RPMLIST/$rpmlist/g\" -e \"s/DESCRIPTION/$description/g\" -e \"s/MOTDMSG/$motdmsg/g\" -e \"/^\s*$/d\" $filename");

	#$fh = fopen($filename, 'a');
	#fwrite($fh, implode("\n", $commandArray) . "\n");
	#fclose($fh);
	#system("cat /usr/share/hamsta/xml_files/templates/customjob-template2.xml >> $filename");
	if ($addtoCustomJob == "addtoCustomJob")
	{
		if($roleNumber > 1)
			$fileDir = "/usr/share/hamsta/xml_files/multimachine/custom";
		else
			$fileDir = "/usr/share/hamsta/xml_files/custom";

		if(!is_dir($fileDir))
		{
			if(mkdir($fileDir) == false )
				$errors[] = "Can not create directory: $fileDir";
		}
		system("cp $filename $fileDir/$jobname.xml");
	}	

	if (request_str("submit"))
	{
		if($roleNumber == 1)
		{
			foreach ($machines as $machine){
				if ($machine->send_job($filename)) {
					Log::create($machine->get_id(), $machine->get_used_by(), 'JOB_START', "has sent a \"custom\" job to this machine (Job name: \"" . htmlspecialchars($_POST['jobname']) . "\")");
				} else {
					$errors[] = $machine->get_hostname().": ".$machine->errmsg;
				}
			}
			header("Location: index.php");
			
		}
		else
		{
			$go = "mm_job";
			return require("inc/mm_job.php");
		}
	}
	
	$html_title="Send custom job";

	if (count($errors) != 0) {
        	$_SESSION['message'] = implode("\n", $errors);
        	$_SESSION['mtype'] = "fail";
	}
?>
