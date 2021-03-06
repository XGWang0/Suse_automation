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
 * Logic of the upgrade page
 */
if (!defined('HAMSTA_FRONTEND')) {
	$go = 'upgrade';
	return require("index.php");
}

$a_machines = request_array("a_machines");
$job = new Job();

foreach( $a_machines as $machine ) {
	$job->add_machine_id($machine);
}

$search = new MachineSearch();
$search->filter_in_array($a_machines);
$machines = $search->query();
$smtserver = $config->smtserver;

/* pkacer@suse.com
 * TODO Does this loop do something useful?
 */
foreach($machines as $m) {
	$m->get_children();
}

$perm=array('owner'=>'machine_reinstall','other'=>'machine_reinstall_reserved','url'=>'index.php?go=upgrade');
machine_permission_or_disabled($machines,$perm);

# If install options are set in the DB, they will show up in upgrade page, else use what user set in upgrade page even it's empty.
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

# Procee the request
if (request_str("proceed")) {
	# Request parameters
	$installmethod = request_str("installmethod");
	$producturl_raw = request_str("repo_producturl");
	$email = request_str("mailto");
	$producturl = $producturl_raw;
	if ($installmethod == "custom") {
		$installoptions = request_str("installoptions");
		$smturl = request_str("update-smt-url");
		$addonurls = $_POST["addon_url"];
		$additionalrpms = request_str("additionalrpms");
		$pattern_list = $_POST["patterns"];
		//$validation = request_str("startvalidation");
		$update = request_str("startupdate");
		$regmail = request_str("update-reg-email");
		$regcodes = $_POST["rcode"];
		$validation = request_str("startvalidation");
		$addonurls = array_filter($addonurls, "filter");
		$regcodes = array_filter($regcodes, "filter");
	}

	# Check for errors
	$errors = array();
	system("wget -o /dev/null -O /dev/null $producturl/media.1/media", $ret);
	$ret and $errors['producturl'] = "Product URL is wrong, please make sure $producturl/media.1/media exists.";

	if ($installmethod == "custom") {
		foreach ($addonurls as $aurl) {
			if ($aurl) {
				system("wget -o /dev/null -O /dev/null $aurl/media.1/media", $ret2);
				$ret2 and $errors['addonurl'] = "Addon URL is wrong, please make sure $aurl/media.1/media exists.";
			}
		}
		if ($update == "update-smt")
			preg_match("/^http.*$/", $smturl) or $errors['startupdate'] = "You must provide the full URL of an SMT server to do an online update using SMT registration.";
		elseif ($update == "update-reg")
			preg_match("/^.*\@.*$/", $regmail) or $errors['startupdate'] = "You must provide a valid email address in order to do an online update using NCC registration credentials.";
		# Set patterns, rpms, regcodes etc.
		$gpattern = "";
		foreach ($pattern_list as $p)
			$gpattern .= " ".$p;
		$additionalrpms = str_replace(' ', ',', trim($additionalrpms));
		$additionalpatterns = str_replace(' ', ',', trim($gpattern));
		$addonurl = join(",", $addonurls);
		$regcode = join(",", TrimArray($regcodes));
	} // End of $installmethod == "custom"
	# Processing the job
	if (count($errors)==0) {
		$producturl=preg_quote($producturl, '/');
		$rand = rand();
		$autoyastfile = "/tmp/install_$rand.xml";
		system("cp /usr/share/hamsta/xml_files/templates/reinstall-template.xml $autoyastfile");
		$args = "-p $producturl -U";
		if ($installmethod == "custom") {
			$addonurl=preg_quote($addonurl,'/');
			$smturl=preg_quote($smturl,'/');
			$installoptions = preg_quote($installoptions,'/');
			if ($addonurl)
				$args .= " -s $addonurl";
			if ($installoptions)
				$args .= " -o \"$installoptions\"";
			if ($additionalrpms)
				$args .= " -r $additionalrpms";
			if ($additionalpatterns)
				$args .= " -t $additionalpatterns";
			if ($update == "update-smt" and $smturl != "")
				$args .= " -S " . $smturl;
			if ($update == "update-reg" and $regmail != "")
				$args .= " -R " . $regmail;
			if ($update == "update-reg" and $regcode != "")
				$args .= " -C " . $regcode;
			if ($update == "update-opensuse")
				$args .= " -O ";
		}
		system("sed -i '/<mail notify=/c\\\t<mail notify=\"1\">$email<\/mail>' $autoyastfile");
		system("sed -i 's/ARGS/$args/g' $autoyastfile");
		system("sed -i 's/REPOURL/$producturl/g' $autoyastfile");

		#jobxml add
		$job->addfile($autoyastfile);

		if ($validation) {
			$validationfiles = explode (" ", $config->xml->validation);
			foreach ( $validationfiles as &$validationfile ) {
				$randfile = "/tmp/validation_$rand.xml";
				system("cp $validationfile $randfile");
				$validationfile = $randfile;
				system("sed -i '/<mail notify=/c\\\t<mail notify=\"1\">$email<\/mail>' $validationfile");
				$job->addfile($validationfile);
				}
		}

		if ( $job->send_job() ){
			foreach( $a_machines as $machine ) {
				Log::create($machine, get_user_login ($user), 'REINSTALL', "has reinstalled this machine using $producturl_raw (Addon: " . ($addonurl ? "yes" : "no") . ", Updates: " . (request_str("startupdate") == "update-smt" ? "SMT" : (request_str("startupdate") == "update-reg" ? "RegCode" : "no")) . ")");
			}
		}else{
			$error = $job->errmsg;
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
$html_title = "Upgrade (only supports upgrade to SLE-11-SP2 or higher)";
?>
