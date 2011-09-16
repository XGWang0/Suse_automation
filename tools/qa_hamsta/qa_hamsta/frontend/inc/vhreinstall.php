<?php
/**
 * Logic of the vhreinstall page 
 */
if (!defined('HAMSTA_FRONTEND')) {
    $go = 'vhreinstall';
    return require("index.php");
}

function filter($var) {
    if($var == '')
        return false;
    return true;
}

$err = 0;
$search = new MachineSearch();
$search->filter_in_array(request_array("a_machines"));
$machines = $search->query();

foreach($machines as $m) {
	$m->get_children();
}

### Figure out, check, and set the installation options ###
$installoptions = request_str("installoptions");
$installoptions_warning = "";

# If the install options are empty, we use the ones from the DB
if($installoptions == "") {
	# If we only have one machine, we just use those options
	if(count($machines) == 1) {
		$installoptions = $machines[0]->get_def_inst_opt();
	} else { # Otherwise, we see if options are different between the machines
		# Loop through all machines included in this reinstall request
		foreach($machines as $machine) {
			# Set the initial value if it hasn't been set yet
			if($installoptions == "") {
				$installoptions = $machine->get_def_inst_opt();
			}
			# If the options for this machine are different from any of the others, we can't use them
			if($machine->get_def_inst_opt() != $installoptions) {
				$installoptions_warning = "Warning: Default installation options cannot be displayed since you selected multiple machines with different default options";
				$installoptions = "";
				break;
			}
		}
	}
}

$resend_job=request_str("xml_file_name");
if (request_str("proceed")) {
    $smturl = request_str("update-smt-url");
    # Check for errors
    $errors = array();
    if(request_str("startupdate") == "update-smt") {
        if(!preg_match("/^http.*$/", $smturl)) {
            $errors['startupdate'] = "You must provide the full URL of an SMT server to do an online update using SMT registration.";
        }
    } elseif(request_str("startupdate") == "update-reg") {
        if(!preg_match("/^.*\@.*$/", request_str("update-reg-email")) or request_str("update-reg-code") == "") {
            $errors['startupdate'] = "You must provide a valid email address and registration code in order to do an online update using NCC registration credentials.";
        }
    }

    $producturl_raw = request_str("repo_producturl");
    $producturl = $producturl_raw;
    $additionalrpms = request_str("additionalrpms");
    $virtualization_method = request_str("virtualization_method");
    $installmethod = request_str("installmethod");
    $addonurls = $_POST["addon_url"];
    $addonurls = array_filter($addonurls, "filter");
    $pattern_list = $_POST["patterns"];
    $additionalpatterns = "";
    foreach ($pattern_list as $p)
        $additionalpatterns .= " ".$p;

    if ($virtualization_method == "xen") {
        $additionalpatterns .= " xen_server";
        if (preg_match('/[SsLlEe]{3}.-10/',$producturl)) {
            $additionalrpms .= " kernel-xen";
        }
    } elseif ($virtualization_method == "kvm") {
        if (preg_match('/[SsLlEe]{3}.-11-[SsPp]{2}[234]/',$producturl)) {
            $additionalrpms .= "kvm";
        }
    } else {
	# Report error.
	$errors['virtualization_method'] = "Unknown virtualization method $virtualization_method.";
    }

    $additionalrpms = str_replace(' ', ',', trim($additionalrpms));
    $additionalpatterns = str_replace(' ', ',', trim($additionalpatterns));
    $addonurl = join(",", $addonurls);

    if(count($errors) == 0) {
        system("wget -o /dev/null -O /dev/null $producturl/media.1/media", $ret);
        foreach ($addonurls as $aurl) {
            if ($aurl) {
                system("wget -o /dev/null -O /dev/null $aurl/media.1/media", $ret);
                $ret and $errors['addonurl'] = "Addon URL is wrong, please make sure $aurl/media.1/media exists.";
            }
        }

        if (!$ret){
            if (!$err){
                $producturl=preg_quote($producturl, '/');
                $smturl=preg_quote($smturl,'/');
                $installoptions = preg_quote($installoptions,'/');
                $addonurl = preg_quote($addonurl,'/');
	    
	       // now copy the update.xml file and patch it !
               $rand = rand();
               $autoyastfile = "/tmp/vhreinstall_$rand.xml";
               system("cp /usr/share/hamsta/xml_files/templates/vhreinstall-template.xml $autoyastfile");
               $args = "-p $producturl";
               if ($addonurl)
                   $args .= " -s $addonurl";
               if ($installoptions)
                   $args .= " -o \"$installoptions\"";
               if ($additionalrpms)
                   $args .= " -r $additionalrpms";
               if ($additionalpatterns)
                   $args .= " -t $additionalpatterns";
               if (request_str("startupdate") == "update-smt" and $smturl != "")
                   $args .= " -S " . $smturl;
               if (request_str("startupdate") == "update-reg" and request_str("update-reg-email") != "")
                   $args .= " -R " . request_str("update-reg-email");
               if (request_str("startupdate") == "update-reg" and request_str("update-reg-code") != "")
                   $args .= " -C " . request_str("update-reg-code");
               if (request_str("startupdate") == "update-opensuse")
	           $args .= " -O " . request_str("startupdate");
               if ($installmethod == "Upgrade")
                   $args .= " -U";
	       $args .= " -V " .$virtualization_method;
               $email = request_str("mailto");
               system("sed -i '/<mail notify=/c\\\t<mail notify=\"1\">$email<\/mail>' $autoyastfile");
               system("sed -i 's/ARGS/$args/g' $autoyastfile");
               system("sed -i 's/REPOURL/$producturl/g' $autoyastfile");
               foreach ($machines as $machine) {
                   if (!$machine->send_job($autoyastfile)) {
                       $error = (empty($error) ? "" : $error) . "<p>".$machine->get_hostname().": ".$machine->errmsg."</p>";
                   } else {
                       Log::create($machine->get_id(), $machine->get_used_by(), 'REINSTALL', "has reinstalled this machine as virtualization host using \"$producturl_raw\", Updates: " . (request_str("startupdate") == "update-smt" ? "SMT" : (request_str("startupdate") == "update-reg" ? "RegCode" : "no")) . ")");
                   }
                   if ($virtualization_method == "xen") {
                       if(!$machine->send_job("/usr/share/hamsta/xml_files/set_xen_default.xml"))
                           $error = (empty($error) ? "" : $error) . "<p>".$machine->get_hostname().": ".$machine->errmsg."</p>";
                    }                
               }    
		    if (empty($error)) {
				header("Location: index.php");
			}
            }
        } else { echo "<div class=\"failmessage\">Product URL is wrong, please make sure $producturl/media.1/media exists</div>";}
    } else {
        echo "<div class=\"failmessage\" style=\"text-align: left;\">The following errors were returned:";
        echo "<ul>";
        echo "<li>" . implode("</li><li>", $errors) . "</li>";
        echo "</ul>";
        echo "</div>";
    }
}
$html_title = "Reinstall as VH";
?>
