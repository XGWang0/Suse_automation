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
 * Logic of the newvm page 
 */
if (!defined('HAMSTA_FRONTEND')) {
	$go = 'vm-migrate';
	return require("index.php");
}

$search = new MachineSearch();
$search->filter_in_array(request_array("a_machines"));
$machines = $search->query();

# check permissions
$perm=array('owner'=>'vm_admin','other'=>'vm_admin_reserved','url'=>'index.php?go=qacloud');
machine_permission_or_disabled($machines,$perm);

if (request_str("proceed")) {
	machine_permission_or_redirect($machines,$perm);
	$errors = array(); // Used for recording errors

	# Request all variables 
	$host_name = request_str("host_name");
	$migrateeIP = request_str("migrateeIP");
	$livemigration = request_str("livemigration");
	$migratetimes = request_str("migratetimes");
        $email = request_str("mailto");

	#Check input errors
	if(!$host_name) {
		$errors['vm_host_name'] = "Host name of the virtual machine to migrate can not be null.";
	}else{
		preg_match_all("/^\s*([^\s]+)\s*$/",$host_name,$useful_part);
		$host_name = $useful_part[1][0];
		if (!$host_name){
			$errors['vm_host_name'] = "Host name of the virtual machine to migrate is not valid.";
		}else{
			#Translate hostname to mac
			$migrate_machine = Machine::get_by_hostname($host_name);
			if (!$migrate_machine){
				$errors['vm_host_name'] = "There is no machine with the given hostname: $host_name.";
			}else{
				$migrate_mac = $migrate_machine->get_unique_id();
			}
		}
	}
	if(!$migrateeIP){
                $errors['migrateeIP'] = "The remote host IP can not be null.";
	}else if(!preg_match("/^\s*\d{1,3}(\.\d{1,3}){3}\s*$/", $migrateeIP)) {
                $errors['migrateeIP'] = "The remote host IP is wrongly formatted.";
	}	
	if (!$migratetimes) {
		$migratetimes = 1;
	}elseif (!preg_match("/^\s*\d+\s*$/",$migratetimes)){
		$errors['migratetimes'] = "Migrate times must be a number";
	}elseif ((int) $migratetimes <= 0){
		$errors['migratetimes'] = "Migrate times can not be less than or equal 0";
	}
	# Processing the job
	if (count($errors)==0) {
		# Make the job file!
		$rand = rand();
		$migratejobfile = "/tmp/vm_migrate_$rand.xml";
		system("cp /usr/share/hamsta/xml_files/templates/vm-migration-template.xml $migratejobfile");
		$args = "";
		if ($migrate_mac){
			$args .= " -m $migrate_mac";
		}
		if ($migrateeIP)
			$args .= " -p $migrateeIP";
		if ($livemigration == "yes")
			$args .= " -l";
		if ($migratetimes)
			$args .= " -t $migratetimes";

		system("sed -i '/<mail notify=/c\\\t<mail notify=\"1\">$email<\/mail>' $migratejobfile");
		system("sed -i 's/ARGS/$args/g' $migratejobfile");

		foreach ($machines as $machine) {
			if (!$machine->send_job($migratejobfile)) {
				$error = (empty($error) ? "" : $error) . "<p>".$machine->get_hostname().": ".$machine->errmsg."</p>";
			} else {
				Log::create($machine->get_id(), get_user_login ($user), 'VM-MIGRATION', "of host $host_name to remote host with IP $migrateeIP and live migration option as " . ($livemigration ? "yes" : "no") . " has been processed.");
			}
		}

		if (empty($error)) {
                        $_SESSION['message'] = "Virtual machine migration job has been successfully sent.";
                        $_SESSION['mtype'] = "success";
			header("Location: index.php?go=qacloud");
		}
	} else {
                $_SESSION['message'] = implode("\n", $errors);
                $_SESSION['mtype'] = "fail";
	} # End of if (count($errors)==0)
}
$html_title = "VM Migration";
?>

