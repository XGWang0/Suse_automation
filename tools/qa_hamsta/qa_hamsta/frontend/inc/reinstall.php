<?php
/**
 * Logic of the reinstall page 
 */
if (!defined('HAMSTA_FRONTEND')) {
	$go = 'reinstall';
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

foreach($machines as $m) {
	$m->get_children();
}

# If the install options are empty, we use the ones from the DB, else we see if options are different between machines. If different, don't use them
$installoptions_warning="";
if (!isset($installoptions) or $installoptions=="") {
	$firstoptions = $machines[0]->get_def_inst_opt();
	$installoptions = $firstoptions;
	foreach($machines as $machine)
		if($machine->get_def_inst_opt() != $firstoptions) {
			$installoptions = "";
			$installoptions_warning = "Warning: Default installation options cannot be displayed since you selected multiple machines with different default options";
			break;
		}
}

# Get partition info from database
$root_partitions="";
foreach ($machines as $machine){
	$partitions=($machine->get_partition_bycid($machine->get_current_configuration_id()));
	$swap=($machine->get_swap_bycid($machine->get_current_configuration_id()));
	$swap=trim($swap);
	if ($partitions != "")
		foreach($partitions as $subpts){
			$subpts_n=preg_replace("/\(.*/","",$subpts);
			if("$swap"!="$subpts_n")
				$root_partitions=$root_partitions . ",$subpts";
		}
	$root_partitions = preg_replace("/^./","",$root_partitions);
}
$ptargs="";
if(request_str("subpartition")){
	$ptargs= request_str("subpartition");
	$ptargs = preg_replace("/\(.*/","",$ptargs);
	$ptargs = str_replace("/", "\\/", $ptargs);
}

# Procee the request
if (request_str("proceed")) {
	# Request parameters
	$installoptions = request_str("installoptions");
	$smturl = request_str("update-smt-url");
	$producturl_raw = request_str("repo_producturl");
	$producturl = $producturl_raw;
	$addonurls = $_POST["addon_url"];
	$additionalrpms = request_str("additionalrpms");
	$pattern_list = $_POST["patterns"];
	$rootfstype = request_str("rootfstype");
	$defaultboot = request_str("defaultboot");
	$setxen = request_str("xen");
	$validation = request_str("startvalidation");
	$email = request_str("mailto");
	$update = request_str("startupdate");
	$regmail = request_str("update-reg-email");
	$regcodes = $_POST["rcode"];
	$validation = request_str("startvalidation");
	$addonurls = array_filter($addonurls, "filter");
	$regcodes = array_filter($regcodes, "filter");
	$installmethod = request_str("installmethod");
	$setupfordesktop = request_str("setupfordesktop");

	# Check for errors
	$errors = array();
	if ($update == "update-smt")
		preg_match("/^http.*$/", $smturl) or $errors['startupdate'] = "You must provide the full URL of an SMT server to do an online update using SMT registration.";
	elseif ($update == "update-reg")
		preg_match("/^.*\@.*$/", $regmail) or $errors['startupdate'] = "You must provide a valid email address in order to do an online update using NCC registration credentials.";
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

	# Set patterns, rpms, regcodes etc.
	$gpattern = "";
	foreach ($pattern_list as $p)
		$gpattern .= " ".$p;
	if ($setxen) {
		$gpattern .= " xen_server";
		if (preg_match('/[SsLlEe]{3}.-10/',$producturl))
			$additionalrpms .= " kernel-xen";
	}
	$additionalrpms = str_replace(' ', ',', trim($additionalrpms));
	$additionalpatterns = str_replace(' ', ',', trim($gpattern));
	$addonurl = join(",", $addonurls);
	$regcode = join(",", TrimArray($regcodes));

	# Processing the job
	if (count($errors)==0) {
		$producturl=preg_quote($producturl, '/');
		$addonurl=preg_quote($addonurl,'/');
		$smturl=preg_quote($smturl,'/');
		$installoptions = preg_quote($installoptions,'/');
		$rand = rand();
		$autoyastfile = "/tmp/reinstall_$rand.xml";
		system("cp /usr/share/hamsta/xml_files/templates/reinstall-template.xml $autoyastfile");
		$args = "-p $producturl -f $rootfstype";
		if ($addonurl)
			$args .= " -s $addonurl";
		if ($installoptions)
			$args .= " -o \"$installoptions\"";
		if (isset($profileurl))
			$args .= " -u $profileurl";
		if ($additionalrpms)
			$args .= " -r $additionalrpms";
		if ($additionalpatterns)
			$args .= " -t $additionalpatterns";
		if ($defaultboot)
			$args .= " -b $defaultboot";
		if ($ptargs)
			$args .= " -z $ptargs";
		if ($update == "update-smt" and $smturl != "")
			$args .= " -S " . $smturl;
		if ($update == "update-reg" and $regmail != "")
			$args .= " -R " . $regmail;
		if ($update == "update-reg" and $regcode != "")
			$args .= " -C " . $regcode;
		if ($update == "update-opensuse")
			$args .= " -O " . $update;
		if ($installmethod == "Upgrade")
			$args .= " -U";
		if ($setupfordesktop == "yes")
			$args .= " -D";
		system("sed -i '/<mail notify=/c\\\t<mail notify=\"1\">$email<\/mail>' $autoyastfile");
		system("sed -i 's/ARGS/$args/g' $autoyastfile");
		system("sed -i 's/REPOURL/$producturl/g' $autoyastfile");
		foreach ($machines as $machine) {
			if ($machine->send_job($autoyastfile)) {
				Log::create($machine->get_id(), $machine->get_used_by(), 'REINSTALL', "has reinstalled this machine using $producturl_raw (Addon: " . ($addonurl ? "yes" : "no") . ", Updates: " . (request_str("startupdate") == "update-smt" ? "SMT" : (request_str("startupdate") == "update-reg" ? "RegCode" : "no")) . ")");
			} else {
				$errors['autoyastjob']=$machine->get_hostname().": ".$machine->errmsg;
			}
			if ($setxen)
				$machine->send_job("/usr/share/hamsta/xml_files/set_xen_default.xml") or $errors['setxenjob']=$machine->get_hostname().": ".$machine->errmsg;
			if ($setupfordesktop == "yes")  # Needs reboot so accesible technologies starts correctly (bnc#710624)
				$machine->send_job("/usr/share/hamsta/xml_files/reboot.xml") or $errors['setxenjob']=$machine->get_hostname().": ".$machine->errmsg;
			if ($validation) {
				$validationfile = "/tmp/validation_$rand.xml";
				system("cp ".XML_VALIDATION." $validationfile");
				system("sed -i '/<mail notify=/c\\\t<mail notify=\"1\">$email<\/mail>' $validationfile");
				$machine->send_job($validationfile) or $errors['validationjob']=$machine->get_hostname().": ".$machine->errmsg;
			}
		}
		if (count($errors)==0)
			header("Location: index.php");
	}
	echo "<div class=\"failmessage\" style=\"text-align: left;\">The following errors were returned:";
	echo "<ul>";
	echo "<li>" . implode("</li><li>", $errors) . "</li>";
	echo "</ul>";
	echo "</div>";
}
$html_title = "Reinstall";
?>
