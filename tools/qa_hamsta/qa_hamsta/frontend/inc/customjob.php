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
	$jobType=$_POST['jobType'];
	$roleNumber=($jobType == 1)?1:$_POST['rolenumber'];
	if($roleNumber == 1)
		$commandsArray[] = request_str("commands_content_single");
	else
		$commandsArray = request_array("commands_content_multiple");

	# get custom parameters, put into an array
	$paramFlag = request_str("param_flag");
	
	if($paramFlag == "paramFlag")
	{
		$paramNameArray = request_array("param_name");
		$paramTypeArray = request_array("param_type");
		$paramLabelArray = request_array("param_label");
		$paramDefaultArray = request_array("param_default");
		$paramSortArray = request_array("param_sort");

	
		$param_map = array();
		$paramValueArray = array();
	
		for($i=0; $i<count($paramNameArray); $i++)
		{
			$optlist = array();
			$optionLabelList = array();
			$optionValueList = array();

			# get the options of enumertion parameter
			if($paramTypeArray[$i] == "enum")
			{
				$optName = "option_" . $paramSortArray[$i] . "_label";
				$optionLabelList = request_array($optName);
				$optName = "option_" . $paramSortArray[$i] . "_value";
				$optionValueList = request_array($optName);

				# Not define options? sure, you can define a enumertion parameter without any options

				for($j=0; $j<count($optionLabelList); $j++)
					$optlist[$j] = array('label'=>$optionLabelList[$j], 'value'=>$optionValueList[$j]);

			}

			$paramTextSpit = explode("\n", $paramDefaultArray[$i]);
			foreach($paramTextSpit as $singleText)
				$paramValueArray[$i] .= rtrim($singleText) . "\n";

			$param_map[$i] = array( 'name'=>$paramNameArray[$i],     'type'=>$paramTypeArray[$i],
					'default'=>$paramValueArray[$i], 'label'=>$paramLabelArray[$i],
					'options'=>$optlist );
		}
	}

	# get all command lines and put into an array
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

	# get other input data
	$addtoCustomJob = $_POST['addtoCustomJob'];
	$roleName = request_array("rolename");
	$minNumber = request_array("minnumber");
	$maxNumber = request_array("maxnumber");

	# OK, so far we have gotten all of the data we need, let's generate the job XML file now

	# generate tmp custom file name
	$rand = rand();
	$filename = "/tmp/customjob_$rand.xml";

	# define all of the XML template

	# define role XML template
	$roleString = "        <role id=\"ROLE_ID\" name=\"ROLE_NAME\" num_min=\"ROLE_MIN\" num_max=\"ROLE_MAX\"/>\n";

	# define command XML template
	if($roleNumber > 1)
		$commandString = "<command execution=\"forked\" role_id=\"ROLE_ID\">\nCOMMANDS            </command>\n";
	else
		$commandString = "<command execution=\"forked\">\nCOMMANDS            </command>\n";

	# deinfe paramter XML template
	$paramString = "        <parameter type=\"PARAM_TYPE\" name=\"PARAM_NAME\" default=\"PARAM_DEFAULT\" label=\"PARAM_LABEL\">\nPARAM_VALUE\n        </parameter>\n";
	# define the XML template for parameters of enumertion
	$paramOptString = "            <option value=\"PARAM_OPT_VALUE\">PARAM_OPT_LABEL</option>\n";

	# get the roles and commands
	$rolesCustom = "";
	$commandsCustom = "";
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
		if($i == 0)
			$commandsCustom .= str_replace("ROLE_ID", $i, str_replace("COMMANDS", $commandLines, $commandString));
		else
			$commandsCustom .= "            " . str_replace("ROLE_ID", $i, str_replace("COMMANDS", $commandLines, $commandString));
	}

	if($roleNumber > 1)
		$rolesCustom = "<roles>\n" . $rolesCustom . "\n    </roles>";	

	# get the parameters
	$parametersCustom = "";
	if( ($paramFlag == "paramFlag") && (count($param_map) > 0) ) 
	{
		$parametersCustom = "<parameters>\n";

		$parameterRandStr = genRandomString(10); # define a random string, avoid deleting the lines of user's input

		foreach($param_map as $param)
		{
			$type = trim($param['type']);
			$name = trim($param['name']);
			$label = trim($param['label']);
			$default = trim($param['default']);

			$value = $default; # for custom job, use default value as real value for this time when you push the "Send ..." button
			$default = ($type == "textarea")?"":$default; # for textarea, set the default attribute to empty
			$label = ($label == "")?$name:$label; # if not edit the label, use name instead of it

			if(($type == "string") || ($type == "textarea"))  # for string or textarea, simply only to replace some key words
			{
				$parametersCustom .= str_replace("PARAM_TYPE", $type, str_replace("PARAM_NAME", $name,
						     str_replace("PARAM_DEFAULT", $default, str_replace("PARAM_LABEL", $label,
						     str_replace("PARAM_VALUE", $value, $paramString)))));
			}
			elseif($type == "enum") # for enumertion parameter, need set all of the options
			{
				$optlist = $param['options'];
				$optionLines = "";
				$optionFlag = 0;  # flag for identify whether user defined some options
				foreach($optlist as $option)
				{
					$optlabel = trim($option['label']);
					$optvalue = trim($option['value']);
					$optionLines .= str_replace("PARAM_OPT_VALUE", $optvalue, str_replace("PARAM_OPT_LABEL", $optlabel, $paramOptString));
					if($optvalue == $default)  # for enumertion, the attribute "defalut" is one of the option lables
					{
						$default = $optlabel;
						$optionFlag = 1;
					}
				}
				if($optionFlag == 0) # if not define option, or the input value is not any option value in options
				{
					$optlabel = "default option";
					$default = "default option";
					$optionLines .= str_replace("PARAM_OPT_VALUE", $value, str_replace("PARAM_OPT_LABEL", $optlabel, $paramOptString));
				}

				# at here, for enumertion parameter, keep the key word of "PARAM_VALUE_<Random String>:" and it's value, 
				# then put option lines below it. When send the job, will delete all of the option lines and 
				# the key word of "PARAM_VALUE_<Rand String>:", just keep the value; When save the job, will delete
				# the line including "PARAM_VALUE_<Rand String>:$value"
				$parametersCustom .= str_replace("PARAM_TYPE", $type, str_replace("PARAM_NAME", $name,
						     str_replace("PARAM_DEFAULT", $default, str_replace("PARAM_LABEL", $label,
						     str_replace("PARAM_VALUE", "PARAM_VALUE_" . $parameterRandStr .":$value\n" . $optionLines, $paramString)))));
			}
			else    # Maybe we will defined other type parameters in future
				continue;
		}
		$parametersCustom .= "    </parameters>\n";
	}

	$fileTemplateName = "/usr/share/hamsta/xml_files/templates/customjob-template-new.xml";
	$fileTemplate = fopen($fileTemplateName, "r");
	if($fileTemplate == NULL)
		$errors[] = "Can not open template file";
	$fileCustom = fread($fileTemplate, filesize($fileTemplateName));
	fclose($fileTemplateName);

	$fileCustom = str_replace("ROLES_AREA", $rolesCustom, str_replace("PARAMETERS_AREA", $parametersCustom,
		      str_replace("COMMANDS_AREA", $commandsCustom, $fileCustom)));

	$fileJob = fopen($filename, "w");
	if($fileJob == NULL)
		$errors[] = "Can not open job file to write";
	fwrite($fileJob, $fileCustom);
	fclose($fileJob);
	system("sed -i -e \"s/JOBNAME/$jobname/g\" -e \"s/DEBUGLEVEL/$debuglevel/g\" -e \"s/MAILTO/$mailto/g\" -e \"s/RPMLIST/$rpmlist/g\" -e \"s/DESCRIPTION/$description/g\" -e \"s/MOTDMSG/$motdmsg/g\" -e \"/^\s*$/d\" $filename");

	# save the custom job
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
		system("sed -i -e \"/PARAM_VALUE_$parameterRandStr:/d\" $fileDir/$jobname.xml"); # delete the value
		
	}

	if($roleNumber > 1) # for multi-machine job, the <option> tag will be used in "multi-machine job detail" page
		system("sed -i -e \"/PARAM_VALUE_$parameterRandStr:/d\" $filename");
	else                # for single-machine job, delete the <option> tags which are no use any more
		system("sed -i -e \"s/PARAM_VALUE_$parameterRandStr://g\" -e\"/<option value=.*>.*<\/option>/d\" $filename");

	if (request_str("submit"))
	{
		if($roleNumber == 1)  # for Single-machine job, send it directly
		{
			foreach ($machines as $machine){
				if ($machine->send_job($filename)) {
					Log::create($machine->get_id(), $machine->get_used_by(), 'JOB_START', "has sent a \"custom\" job to this machine (Job name: \"" . htmlspecialchars($_POST['jobname']) . "\")");
				} else {
					$errors[] = $machine->get_hostname().": ".$machine->errmsg;
					//echo $machine->get_hostname().": ".$machine->errmsg; var_dump("abc"); exit ();
				}
			}
		}
		else    # for multi-machine job, redirect to "multi-machine job detail" page
		{
			$go = "mm_job";
			return require("inc/mm_job.php");
		}
	}
	$html_title="Send custom job";

	if (count($errors) != 0) {
        	$_SESSION['message'] = implode("\n", $errors);
        	$_SESSION['mtype'] = "fail";
	} else {
		header("Location: index.php");
	}
?>
