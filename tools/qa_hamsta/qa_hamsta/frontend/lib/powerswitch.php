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

	/* power_s390 currently accepts userid (ie LINUX152 and action (startm, stop etc ..).
	 * for more details see http://s390zvi33.suse.de/zvm/index.php
	 * 
	 */
   
function power_s390($powerswitch, $powerslot, $action) {
	/* 
	 * Actuall command that we send to the interface via http post method.
	 * Notoce that for some array variables we have to use [0] since interface
	 * accepts and actually expects the input to be complex array/
	 * zVM version seems to be allways 54, IPL device seems to be allways 0150, for some
	 * reason count has to be set, althouhg there are more variables that can be (and in
	 * this case were) ommited.
	 */
	$userid = $powerslot;
	function s390_interface($userid, $action) {
		$s390_action = 'start';
		/*
	 	* URL of web interface for controlling s390 VM's
	 	*/
		$s390_controller = 'http://s390icv033.suse.de/zvm/formaction.php';
		$command = array(
			'count' => urlencode('0'),
			'ipl_device[0]' => urlencode('0150'),
			'zvm_version[0]' => urlencode('54'),
			'userid[0]' => urlencode("$userid"),
			'action' => urlencode("$action"),
		);
		/* 
		 *We transform array to http request string
		 */

		$command_string = http_build_query($command);
		/* 
		 *And here we execute everything using php_curl
		 */

		$address = curl_init($s390_controller);

		curl_setopt($address, CURLOPT_URL, $s390_controller);
		curl_setopt($address, CURLOPT_POST, count($command));
		curl_setopt($address, CURLOPT_POSTFIELDS,$command_string);
		
		/*
		 * Here we execute command itself, while using output buffering to
		 * supress unwanted output
		 *
		 */
		ob_start();
		curl_exec($address);
		ob_end_clean();
		curl_close($address);
		}
	if ($action == "start") {
		s390_interface($userid, 'start');
		}
	else if ($action == "stop") {
		s390_interface($userid, 'stop');
		}
	else if ($action == "restart") {
		s390_interface($userid, 'stop');
		/*
		 * This is equal to reseting machine, also we wait for 5 seconds
		 * because the poweroff commang takes few seconds to complete
		 *
		 */
		sleep(5);
		s390_interface($userid, 'start');
		}
}

	/*
	 * function power_apc is used to start/stop power on apc 
	 * power switches, we specify community by entering community@powerswitch, and grant
	 * this community write+ privileges.
	 *
	 */

function power_apc($powerswitch, $powerslot, $action) {
	$apc_url_string = preg_split("/@/", $powerswitch);

	if (sizeof($apc_url_string) == "2") {
		$apc_snmp_community = $apc_url_string[0];;
		$apc_host = $apc_url_string[1];
	}

	else
		return "powerswitch_description_error";

	$apc_port = $powerslot;
	$apc_snmp_mib_generic = '1.3.6.1.4.1.318.1.1.12.3.3.1.1.4.';
	$apc_snmp_mib_port = $apc_snmp_mib_generic.$apc_port;

	if ($action == "status") {
		$snmp_status = snmpget($apc_host, $apc_snmp_community, $apc_snmp_mib_port, 20000);
		if ($snmp_status == "INTEGER: 1")
			$status = "on";
		else if ($snmp_status == "INTEGER: 2")
			$status = "off";
		else if ($snmp_status == "INTEGER: 3")
			$status = "restarting";
		else
			$status = "unknown";
		return($status);
	}
	else if ($action == "start")
		$apc_action = '1';
	else if ($action == "stop")
		$apc_action = '2';
	else if ($action == "restart")
		$apc_action = '3';
	/*
	 * This is eqal to issuing 'snmpset -c qanet -v 1 apc2.qa.suse.cz 1.3.6.1.4.1.318.1.1.12.3.3.1.1.4.7 i 2'
	 * (example will casuse apc2.qa.suse.cz port 7 using community qanet to stop
	 *
	 */

	snmpset($apc_host, $apc_snmp_community, $apc_snmp_mib_port, 'i', $apc_action);

}

	/*
	 * Support for powercycling using ipmi (requires ipmitool)
	 * 
	 * We specify user:password@host of ipmi inteface
	 *
	 */

function power_ipmi($powerswitch, $powerslot, $action) {
	$ipmi_url_array = preg_split("/[:@]/", $powerswitch);

	if(sizeof($ipmi_url_array) == "3") {
		$ipmi_user = $ipmi_url_array[0];
		$ipmi_password = $ipmi_url_array[1];
		$ipmi_host = $ipmi_url_array[2];
	}

	else {
		return "powerswitch_description_error";
	}

	function ipmi_command($ipmi_user, $ipmi_password, $ipmi_host, $command) {
		$ipmitool_command = "ipmitool -I lan -H $ipmi_host -U $ipmi_user -P $ipmi_password chassis power $command";
		$result = exec($ipmitool_command);
		return($result);
	}


	if ($action == "status") {
        		$ipmi_status = ipmi_command($ipmi_user, $ipmi_password, $ipmi_host, 'status');
	        if ($ipmi_status == "Chassis Power is on")
        	        $status = "on";
	        else if ($ipmi_status == "Chassis Power is off")
        	        $status = "off";
	        else
                	$status = "unknown";
        	return($status);
	}
	else if ($action == "start")
        	ipmi_command($ipmi_user, $ipmi_password, $ipmi_host, 'on');
	else if ($action == "stop")
        	ipmi_command($ipmi_user, $ipmi_password, $ipmi_host, 'off');
	else if ($action == "restart") {
		/*
		 * We are using this, since 'cycle' and 'reset' fail when machine 
		 * is already powered off, also we have to wait for ipmi to shut down machine
		 * before starting it agait (there is usually few seconds delay).
		 *
		 */
		ipmi_command($ipmi_user, $ipmi_password, $ipmi_host, 'off');
		sleep(5);
		ipmi_command($ipmi_user, $ipmi_password, $ipmi_host, 'on');
		}
}

	/*
	 * Support for powercycling of ibm iseries ppc machines that are managed by
	 * by hmc
	 *
	 * We are using ssh to execute commands on hmc console
	 * powerswitch = user:pass@hmc 
	 * powesrlot = machine-machine id (ie steel-2 means that machine is steel and id is 2)
	 */

function power_hmc($powerswitch, $powerslot, $action) {
	$hmc_url_array = preg_split("/[:@]/", $powerswitch);

	if (sizeof($hmc_url_array) == "2") {
		$hmc_user = $hmc_url_array[0];
		$hmc_pass = NULL;
		$hmc_host = $hmc_url_array[1];
	}

	else if (sizeof($hmc_url_array) == "3") {
		$hmc_user = $hmc_url_array[0];
		$hmc_pass = $hmc_url_array[1];
		$hmc_host = $hmc_url_array[2];
	}

	else
		return "powerswitch_description_error";

	$machine_id_array = preg_split("/-/", $powerslot);

	if (sizeof($machine_id_array) == "2") {
		$machine_name = $machine_id_array[0];
		$lpar_id = $machine_id_array[1];
	}

	else
		return "powerslot_description_error";

	function hmc_lssyscfg($hmc_user, $hmc_pass, $hmc_host, $machine_name, $lpar_id) {
		$lssyscfg_command = "lssyscfg -m $machine_name -r lpar --filter \"\"lpar_ids=$lpar_id\"\" -F name:state";
		
		if ($hmc_pass == NULL)
			$lssyscfg_command_ssh = "ssh -o StrictHostKeyChecking=no --user $hmc_user"."@"."$hmc_host \"$lssyscfg_command\" ";
		else
			$lssyscfg_command_ssh = "sshpass -p $hmc_pass ssh -o StrictHostKeyChecking=no --user $hmc_user"."@"."$hmc_host \"$lssyscfg_command\" ";

		$result = exec($lssyscfg_command_ssh);
		return $result;
	}

	function hmc_chsysstate($hmc_user, $hmc_pass, $hmc_host, $machine_name, $lpar_id, $action) {
		$chsysstate_command = "chsysstate -m $machine_name -r lpar --id $lpar_id -o $action";
		
		if ($hmc_pass == NULL)
			$chsysstate_command_ssh = "ssh -o StrictHostKeyChecking=no --user $hmc_user"."@"."$hmc_host \"$chsysstate_command\" ";
		else
			$chsysstate_command_ssh = "sshpass -p $hmc_pass ssh -o StrictHostKeyChecking=no --user $hmc_user"."@"."$hmc_host \"$chsysstate_command\" ";

		exec ($chsysstate_command_ssh);
	}

	if ($action == "status") {
		$hmc_status = hmc_lssyscfg($hmc_user, $hmc_pass, $hmc_host, $machine_name, $lpar_id);
		if (preg_match("/Running/", $hmc_status))
			$status = "on";
		else if (preg_match("/Not Activated/", $hmc_status))
			$status = "off";
		else
			$status = "unknown";
		return($status);
	}
	else if ($action == "start")
		hmc_chsysstate($hmc_user, $hmc_pass, $hmc_host, $machine_name, $lpar_id, 'on');
	else if ($action == "stop")
		hmc_chsysstate($hmc_user, $hmc_pass, $hmc_host, $machine_name, $lpar_id, 'shutdown --immed');
	else if ($action == "restart") 
		hmc_chsysstate($hmc_user, $hmc_pass, $hmc_host, $machine_name, $lpar_id, 'shutdown --immed --restart');
	}

	/*
	 * Support for powercycling of machines with intel AMT
	 * see http://en.wikipedia.org/wiki/Intel_Active_Management_Technology
	 * using amttool (part of amtterm package)
	 * example usage: 'AMT_PASSWORD=pass amttool localhost powerup'
	 *
	 */

function power_amt($powerswitch, $powerslot, $action) {
	$amt_url_array = preg_split('/@/', $powerswitch);

	if(sizeof($amt_url_array) == "2") {
		$amt_password = $amt_url_array[0];
		$amt_host = $amt_url_array[1];
	}

	else
		return "powerswitch_description_error";

	function amt_command($amt_password, $amt_host, $command) {
		$amttool_command = "AMT_PASSWORD=$amt_password amttool $amt_host $action";
		$result = exec($amttool_command);
		return($result);
	}
	
	if ($action == "status") {
		$amt_status = amt_command($amt_password, $amt_host, 'info');
		if (preg_match("/S0/", $amt_status))
			$status = "on";
		else if (preg_match("/S5/", $amt_status))
			$status = "off";
		else
			$status = "unknown";
		return($status);
	}
	else if ($action == "start")
		amt_command($amt_password, $amt_host, 'powerup');
	else if ($action == "stop")
		amt_command($amt_password, $amt_host, 'powerdown');
	else if ($action == "restart") {
		amt_command($amt_password, $amt_host, 'powercycle');
		}
}   

	/*
	 * Support for powecycling of virtual machines using virsh (libvirt-client)
	 * 
	 * command syntax is:
	 * sshpass -p pass virsh -c qemu+ssh://root@shoggoth.qa.suse.cz/system dominfo sles
	 * where powerslot containst qamu-sles for qemu and domain sles or xen-sles for sles
	 * running using xen
	 * 
	 */

function power_virsh($powerswitch, $powerslot, $action) {
	$virsh_url_array =  preg_split('/[:@]/', $powerswitch);

	if(sizeof($virsh_url_array) == "2") {
		$virsh_user = $virsh_url_array[0];
		$virsh_password = NULL;
		$virsh_host = $virsh_url_array[1];
	}

	else if(sizeof($virsh_url_array) == "3") {
		$virsh_user = $virsh_url_array[0];
		$virsh_password = $virsh_url_array[1];
		$virsh_host = $virsh_url_array[2];
	}
	
	else
		return "powerswitch_description_error";

	$virsh_domain_array = preg_split('/-/', $powerslot, '2');

	if(sizeof($virsh_domain_array) >= "2") {
		$virsh_scheme = $virsh_domain_array[0];
		$virsh_domain = $virsh_domain_array[1];
	}

	else
		return "powerslot_description_error";

	function virsh_command($virsh_user, $virsh_password, $virsh_host, $virsh_scheme, $virsh_domain, $command) {

		/*
		 * If no password is provided, we do not use sshpass as wrapper, however if ssh keys are not in use we will fail.
		 *
		 */

		if ($virsh_password ==NULL)
			$sshpass = NULL;
		else
			$sshpass = "sshpass -p";

		if ($virsh_scheme == "qemu")
			
			/*
			 * For qemu, commad looks like
			 * virsh -c qemu+ssh://user@host/system dominfo virtual_machine_id
			 *
			 */

			$virsh_command = $sshpass." ".$virsh_password." virsh -c ".$virsh_scheme."+ssh://".$virsh_user."@".$virsh_host."/system ".$command." ".$virsh_domain;

		else if ($virsh_scheme == "xen")

			/*
			 * For xen, command looks like
			 * virsh -c xen+ssh://user@host dominfo virtual_machine_id
			 *
			 */

			$virsh_command = $sshpass." ".$virsh_password." virsh -c ".$virsh_scheme."+ssh://".$virsh_user."@".$virsh_host." ".$command." ".$virsh_domain;
		
		exec($virsh_command, $result );
		$result = implode($result);
		return($result);
	}

	if ($action == "status") {
		$virsh_status = virsh_command($virsh_user, $virsh_password, $virsh_host, $virsh_scheme, $virsh_domain, 'dominfo');
		if (preg_match("/running/", $virsh_status))
			$status = "on";
		else if (preg_match("/off/", $virsh_status))
			$status = "off";
		else
			$status = "unknown";
		echo("status: $status\n");
		return($status);
	}
	else if ($action == "start")
		virsh_command($virsh_user, $virsh_password, $virsh_host, $virsh_scheme, $virsh_domain, 'start');
	else if ($action == "stop")
		virsh_command($virsh_user, $virsh_password, $virsh_host, $virsh_scheme, $virsh_domain, 'destroy');
	else if ($action == "restart")
		virsh_command($virsh_user, $virsh_password, $virsh_host, $virsh_scheme, $virsh_domain, 'reboot');
}   

	/*
	 * Support for powercycling of ESX/ESXi machines
	 * 
	 * It is necessaty that ssh is enabled (esx console - troubleshooting options)
	 *
	 */

function power_esx($powerswitch, $powerslot, $action) {
	$esx_url_array = preg_split('/[:@]/', $powerswitch);

	if(sizeof($esx_url_array) == "2") {
		$esx_user = $esx_url_array[0];
		$esx_password = NULL;
		$esx_host = $esx_url_array[1];
	}

	else if(sizeof($esx_url_array) == "3") {
		$esx_user = $esx_url_array[0];
		$esx_password = $esx_url_array[1];
		$esx_host = $esx_url_array[2];
	}

	else
		return "powerswitch_description_error";

	if (is_numeric($powerslot))
		$vmid = $powerslot;

	else
		return "powerslot_description_error";

	function esx_command($esx_user, $esx_password, $esx_host, $vmid, $action) {
		if ($esx_password == NULL)
			$esx_command = "ssh -o StrictHostKeyChecking=no ".$esx_user."@".$esx_host." vim-cmd vmsvc/".$action." ".$vmid;
		else
			$esx_command = "sshpass -p ".$esx_password." ssh -o StrictHostKeyChecking=no ".$esx_user."@".$esx_host." vim-cmd vmsvc/".$action." ".$vmid;

		exec($esx_command, $result);
		return($result);
	}
	
	if ($action == "status") {
		$esx_status = esx_command($esx_user, $esx_password, $esx_host, $vmid, 'power.getstate');
		
		# Here we need to convert array (multiline result) to string
		$esx_status = implode($esx_status);

		if (preg_match("/on/", $esx_status))
			$status = "on";
		else if (preg_match("/off/", $esx_status))
			$status = "off";
		else
			$status = "unknown";
		echo("status: $status\n");
		return($status);
	}
	else if ($action == "start")
		esx_command($esx_user, $esx_password, $esx_host, $vmid, 'power.on');
	else if ($action == "stop")
		esx_command($esx_user, $esx_password, $esx_host, $vmid, 'power.off');
	else if ($action == "restart") {
		esx_command($esx_user, $esx_password, $esx_host, $vmid, 'power.off');
		sleep(5);
		esx_command($esx_user, $esx_password, $esx_host, $vmid, 'power.on');
	}
}

?>
