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
 * Logic of the newvm-win page 
 */
if (!defined('HAMSTA_FRONTEND')) {
	$go = 'newvm';
	return require("index.php");
}

function filter($var) {
	if($var == '')
		return false;
	return true;
}

$search = new MachineSearch();
$search->filter_in_array(request_array("a_machines"));
$machines = $search->query();
$perm=array('owner'=>'vm_admin','other'=>'vm_admin_reserved','url'=>'index.php?go=newvm');
machine_permission_or_disabled($machines,$perm);

if (request_str("proceed")) {
	$errors = array(); // Used for recording errors
	machine_permission_or_redirect($machines,$perm);

	# Request all variables 
	$producturl = request_str("win_products");
	$virttype = request_str("virttype");
	$virtcpu = request_str("virtcpu");
	$virtinitmem = request_str("virtinitmem");
	$virtmaxmem = request_str("virtmaxmem");
	$virtdisksizes = request_array("virtdisksizes");
	$virtdisktypes = request_array("virtdisktypes");
	$email = request_str("mailto");

	# Deal with variables
	$virtdisksizestring = join("_", TrimArray($virtdisksizes));
	$virtdisktypestring = join("_", TrimArray($virtdisktypes));

	# Processing the job
	if (count($errors)==0) {
		# Copy the update.xml file and patch it !
		$rand = rand();
		$autoyastfile = "/tmp/newvm_$rand.xml";
		system("cp /usr/share/hamsta/xml_files/templates/winvm-template.xml $autoyastfile");
		$args = "-W $producturl";
		// Virtual Machine options
		if ($virtcpu)
			$args .= " -c $virtcpu";
		if ($virtdisksizestring and $virtdisktypestring)
			$args .= " -d $virtdisksizestring -T $virtdisktypestring";
		if ($virtinitmem)
			$args .= " -e $virtinitmem";
		if ($virtmaxmem)
			$args .= " -x $virtmaxmem";
		#To-do: add disk size/type
		system("sed -i '/<mail notify=/c\\\t<mail notify=\"1\">$email<\/mail>' $autoyastfile");
		system("sed -i 's/ARGS/$args/g' $autoyastfile");

		foreach ($machines as $machine) {
			if (!$machine->send_job($autoyastfile)) {
				$error = (empty($error) ? "" : $error) . "<p>".$machine->get_hostname().": ".$machine->errmsg."</p>";
			} else {
				Log::create($machine->get_id(), $machine->get_used_by_login(), 'VMNEW', "has installed new Windows virtual machine using \"$producturl_raw\"");
			}
		}

		if (empty($error)) {
			header("Location: index.php?go=qacloud");
		}
	} else {
		echo "<div class=\"failmessage\" style=\"text-align: left;\">The following errors were returned:";
		echo "<ul>";
		echo "<li>" . implode("</li><li>", $errors) . "</li>";
		echo "</ul>";
		echo "</div>";
	} # End of if (count($errors)==0)
}
$html_title = "New Windows VM";
?>
