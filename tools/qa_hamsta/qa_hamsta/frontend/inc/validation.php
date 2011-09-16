<?php
	/**
	 * Logic of the validation test page 
	 */

	if (!defined('HAMSTA_FRONTEND')) {
		$go = 'validation';
		return require("../index.php");
	}
	$html_title="Validation test";
	$json = file_get_contents(REPO_INDEX_URL);
	if ($json == ""){
		echo json_encode(array());
		return;
	}
	$repos = json_decode($json);
	foreach($repos as $repo) {
		$product = $repo->{"product"};
		$tmp = split($product, $repo->{"url"});
		$newdic[$product] = $tmp[0];
	}

	if (request_str("submit")) {
		$buildnr = $_POST['buildnumber'];
		$baseurl = "$newdic[$buildnr]" . "$buildnr";
		foreach( $_POST['validationmachine'] as $vm ) {
			$isxen = 0; //clean singal in each loop
			$machineIP=$vmlist["$vm"];
			$machine=Machine::get_by_ip($machineIP);
			if ($vm == "x86-xen") {
				$vm = "i386";
				$isxen = 1;
			}
			if ($vm == "x86_64-xen") {
				$vm = "x86_64";
				$isxen = 1;
			}
			$email = request_str("mailto");
			$sdkurl = request_str("sdk_producturl");
			$repourl=$baseurl."/".$vm."/DVD1";
			system("wget -o /dev/null -O /dev/null $repourl/media.1/media", $ret);
			$args = "-p $repourl";
			if ($sdkurl) {
				$sdkurl.="/".$vm."/DVD1";
				system("wget -o /dev/null -O /dev/null $sdkurl/media.1/media", $ret2);
				$ret += $ret2;
				$args .= " -s $sdkurl";
			}
			if (!$ret){
				$rand = rand();
				$autoyastfile = "/tmp/reinstall_$rand.xml";
				$validationfile = "/tmp/validation_$rand.xml";
				system("cp /usr/share/hamsta/xml_files/templates/reinstall-template.xml $autoyastfile");
				system("cp ".XML_VALIDATION." $validationfile");
				if ($machine->get_def_inst_opt() ) {
					$args .= " -o \"".$machine->get_def_inst_opt() . "\"";
				}
				if ($isxen == 1) {
					$args .= " -t xen_server -r kernel-xen";}
				$args = preg_quote($args);
				$args = str_replace("/","\\/",$args);
				$con_repourl = str_replace("/","\\/",$repourl);
				system("sed -i -e '/<mail notify=/c\\\t<mail notify=\"1\">$email<\/mail>' -e 's/ARGS/$args/g' -e 's/REPOURL/$con_repourl/g' $autoyastfile");
				system("sed -i '/<mail notify=/c\\\t<mail notify=\"1\">$email<\/mail>' $validationfile");

				if (!$machine->send_job($autoyastfile))
					$error = (empty($error) ? "" : $error) . "<p>".$machine->get_hostname().": ".$machine->errmsg."</p>";
				if ($isxen == 1) {
					if (!$machine->send_job("/usr/share/hamsta/xml_files/set_xen_default.xml"))
						$error = (empty($error) ? "" : $error) . "<p>".$machine->get_hostname().": ".$machine->errmsg."</p>";
				}
				if ($machine->send_job($validationfile)) {
					Log::create($machine->get_id(), $machine->get_used_by(), 'JOB_START', "has started the automated build validation for this machine (install + tests)");
				} else {
					$error = (empty($error) ? "" : $error) . "<p>".$machine->get_hostname().": ".$machine->errmsg."</p>";
				}
			} else {
				$_SESSION['message'] = 'Product URL or SDK URL is wrong, please make sure "'.$repourl.'/media.1/media" and "'.$sdkurl.'/media.1/media" exist.';
				$_SESSION['mtype'] = "fail";
				$ret3="fail";
			}
		}
		if ($ret3!="fail" and empty($error))
			header("Location: index.php");
	}
?>
