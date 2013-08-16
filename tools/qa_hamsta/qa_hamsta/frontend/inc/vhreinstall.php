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

$perm=array('owner'=>'vh_admin','other'=>'vh_admin_reserved','url'=>'index.php?go=vhreinstall');
machine_permission_or_disabled($machines,$perm);

foreach($machines as $m) {
	$m->get_children();
}

$installoptions_warning = "";

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

$resend_job=request_str("xml_file_name");
if (request_str("proceed")) {
    machine_permission_or_redirect($machines,$perm);
    $installoptions = request_str("installoptions"); # use options listed in webpage
    $smturl = request_str("update-smt-url");
    $regcodes = $_POST["rcode"];
    $regcodes = array_filter($regcodes,"filter");
    $regcode = join(",", TrimArray($regcodes));

    # Check for errors
    $errors = array();
    if(request_str("startupdate") == "update-smt") {
        if(!preg_match("/^http.*$/", $smturl)) {
            $errors['startupdate'] = "You must provide the full URL of an SMT server to do an online update using SMT registration.";
        }
    } elseif(request_str("startupdate") == "update-reg") {
        if(!preg_match("/^.*\@.*$/", request_str("update-reg-email")) and $regcode == "") {
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
        $additionalpatterns .= "xen_server";
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
	           $args .= " -O ";
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
			Log::create($machine->get_id(), $user->getLogin (), 'REINSTALL', "has reinstalled this machine as virtualization host using \"$producturl_raw\", Updates: " . (request_str("startupdate") == "update-smt" ? "SMT" : (request_str("startupdate") == "update-reg" ? "RegCode" : "no")) . ")");
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
