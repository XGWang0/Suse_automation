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

### Figure out, check, and set the installation options ###
$installoptions = request_str("installoptions");
$installoptions_warning = "";

# check permissions
$perm=array('owner'=>'vm_admin','other'=>'vm_admin_reserved','url'=>'index.php?go=qacloud');
machine_permission_or_disabled($machines,$perm);

if (request_str("proceed")) {
	machine_permission_or_redirect($machines,$perm);
	$errors = array(); // Used for recording errors

	# Request all variables 
	$producturl_raw = request_str("repo_producturl");
	$producturl = $producturl_raw;
	//$sdkurl=request_str("sdk_producturl");
	$additionalrpms = request_str("additionalrpms");
	//$additionalpatterns = request_str("additionalpatterns");
	$graphicmode = request_str("graphicmode");
	$virttype = request_str("virttype");
	$virtcpu = request_str("virtcpu");
	$virtinitmem = request_str("virtinitmem");
	$virtmaxmem = request_str("virtmaxmem");
	$virtdisksizes = request_array("virtdisksizes");
	# Convert GB to MB for disk size.
	foreach (array_keys($virtdisksizes) as $i) 
		$virtdisksizes[$i] *= 1024;
	$virtdisktypes = request_array("virtdisktypes");
	$validation = request_str("validation");
	$update = request_str("startupdate");
	$smturl = request_str("update-smt-url");
	$email = request_str("mailto");
	$setupfordesktop = request_str("setupfordesktop");

	# Deal with variables
	$addonurls = $_POST["addon_url"];
	$regcodes = $_POST["rcode"];	
	$addonurls = array_filter($addonurls, "filter");
	$regcodes = array_filter($regcodes, "filter");
	$pattern_list = $_POST["patterns"];
	$additionalpatterns = "";
	foreach ($pattern_list as $p)
		$additionalpatterns .= " ".$p;
	if ($graphicmode != "nographic")
		$additionalpatterns .= " $graphicmode";
	$additionalrpms = str_replace(' ', ',', trim($additionalrpms));
	$additionalpatterns = str_replace(' ', ',', trim($additionalpatterns));
	$addonurl = join(",", $addonurls);
	$regcode = join(",", TrimArray($regcodes));
	$virtdisksizestring = join("_", TrimArray($virtdisksizes));
	$virtdisktypestring = join("_", TrimArray($virtdisktypes));


	# Check update method
	if($update == "update-smt") {
		if(!preg_match("/^http.*$/", $smturl)) {
			$errors['startupdate'] = "You must provide the full URL of an SMT server to do an online update using SMT registration.";
		}
	} elseif($update == "update-reg") {
		if(!preg_match("/^.*\@.*$/", request_str("update-reg-email")) or request_str("update-reg-code") == "") {
			$errors['startupdate'] = "You must provide a valid email address and registration code in order to do an online update using NCC registration credentials.";
		}
	}
	
	# Check $producturl and addonurl(s), addon = sdk
	system("wget -o /dev/null -O /dev/null $producturl/media.1/media", $ret);
	$ret and $errors['producturl'] = "Product URL is wrong, please make sure $producturl/media.1/media exists.";
	foreach ($addonurls as $aurl)
		if ($aurl) {
			system("wget -o /dev/null -O /dev/null $aurl/media.1/media", $ret2);
			$ret2 and $errors['addonurl'] = "Addon URL is wrong, please make sure $aurl/media.1/media exists.";
		}
	if(isset($_FILES['userfile']) and $_FILES['userfile']['error'] != UPLOAD_ERR_NO_FILE) {
		$uploadfile = 'profiles/' . basename($_FILES['userfile']['name']);
		if ($_FILES['userfile']['type'] == 'text/xml' && move_uploaded_file($_FILES['userfile']['tmp_name'], $uploadfile))
			$profileurl = str_replace("/","\\/", 'http://' . $_SERVER['SERVER_ADDR'] . '/hamsta/' . $uploadfile);
		else
			$errors['uploadprofile'] = "Custom autoyast profile upload failed.";
	}

	# Processing the job
	if (count($errors)==0) {
		$producturl=preg_quote($producturl, '/');
		$addonurl=preg_quote($addonurl,'/');
		$smturl=preg_quote($smturl,'/');
		$installoptions = preg_quote($installoptions,'/');

		# Copy the update.xml file and patch it !
		$rand = rand();
		$autoyastfile = "/tmp/newvm_$rand.xml";
		system("cp /usr/share/hamsta/xml_files/templates/newvm-template.xml $autoyastfile");
		$args = "-p $producturl -V $virttype";
		if ($addon_url)
			$args .= " -s $addon_url";
		if ($installoptions)
			$args .= " -o \"$installoptions\"";
		if ($profileurl)
			$args .= " -u $profileurl";
		if ($additionalrpms)
			$args .= " -r $additionalrpms";
		if ($additionalpatterns)
			$args .= " -t $additionalpatterns";
		if ($setupfordesktop == "yes")
			$args .= " -D";
		if ($virtcpu)
			$args .= " -c $virtcpu";
                if ($virtinitmem)
                        $args .= " -m $virtinitmem";
                if ($virtmaxmem)
                        $args .= " -M $virtmaxmem"; 
		if ($virtdisksizestring and $virtdisktypestring) {
			$virtdisktypestring = preg_replace("/def/","file",$virtdisktypestring); 
			$args .= " -d $virtdisksizestring -T $virtdisktypestring";
		}
		#To-do: add disk size/type
		if (request_str("startupdate") == "update-smt" and $smturl != "")
			$args .= " -S " . $smturl;
		if (request_str("startupdate") == "update-reg" and request_str("update-reg-email") != "")
			$args .= " -R " . request_str("update-reg-email");
		if (request_str("startupdate") == "update-reg" and request_str("update-reg-code") != "")
			$args .= " -C " . request_str("update-reg-code");
		if (request_str("startupdate") == "update-opensuse")
			$args .= " -O ";
		system("sed -i '/<mail notify=/c\\\t<mail notify=\"1\">$email<\/mail>' $autoyastfile");
		system("sed -i 's/ARGS/$args/g' $autoyastfile");
		system("sed -i 's/REPOURL/$producturl/g' $autoyastfile");

		foreach ($machines as $machine) {
			if (!$machine->send_job($autoyastfile)) {
				$error = (empty($error) ? "" : $error) . "<p>".$machine->get_hostname().": ".$machine->errmsg."</p>";
			} else {
				Log::create($machine->get_id(), $user->getLogin (), 'VMNEW', "has installed new virtual machine using \"$producturl_raw\" (SDK: " . ($addon_url ? "yes" : "no") . ", Updates: " . (request_str("startupdate") == "update-smt" ? "SMT" : (request_str("startupdate") == "update-reg" ? "RegCode" : "no")) . ")");
			}
		}
		# Check if a validation test is needed
		if ($validation) {
			$validationfiles = explode (" ", $config->xml->validation);
			foreach ( $validationfiles as &$validationfile ) {
				$randfile= "/tmp/validation_$rand.xml";
				system("cp $validationfile $randfile");
				$validationfile = $randfile;
				system("sed -i '/<mail notify=/c\\\t<mail notify=\"1\">$email<\/mail>' $validationfile");
				$machine->send_job($validationfile) or $errors['validationjob']=$machine->get_hostname().": ".$machine->errmsg;
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
$html_title = "New VM";
?>
