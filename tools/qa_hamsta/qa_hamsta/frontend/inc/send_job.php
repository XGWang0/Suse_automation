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
     * Logic of the send_job page 
     */
    if (!defined('HAMSTA_FRONTEND')) {
        $go = 'send_job';
        return require("index.php");
    }

    # for delete custom file
    $option = request_str("opt");
    $machine_list = request_str("machine_list");
    $custom_file = request_str("file");
    
    if($option == "delete") # only custom defined file can be deleted
    {
    	$custom_file = XML_DIR . "/" . $custom_file;

	if(file_exists($custom_file))
            unlink($custom_file);
    }

    $search = new MachineSearch();
    if($machine_list != "")
    	$machines_id_array = explode(",", $machine_list);
    else
	$machines_id_array = request_array("a_machines");

        // print_r($_REQUEST);
        #$search->filter_in_array(request_array("a_machines"));
        $search->filter_in_array($machines_id_array);
        $machines = $search->query();

	# Verify user has rights to modify the machine
	if ($openid_auth && array_key_exists('OPENID_AUTH', $_SESSION) && $user = User::get_by_openid($_SESSION['OPENID_AUTH'])) {
		foreach ($machines as $machine) {
			$used_by = User::get_by_openid($machine->get_used_by());
			if ($used_by && $used_by->get_openid() != $user->get_openid()) {
				$_SESSION['mtype'] = "fail";
				$_SESSION['message'] = "You cannot send jobs to a reserved machine.";
				header('Location: index.php?go=machines');
				exit();
			}
		}
	}

        $resend_job=request_str("xml_file_name");
        $filenames =request_array("filename");

	if (request_str("submit")) {

		$email = request_str("mailto");
		$jobfilenames = array();

		foreach ($filenames as $jobfile) {

			$jobbasename = basename($jobfile);
			system("cp $jobfile /tmp/");
			system("sed -i '/<mail notify=/c\\\t<mail notify=\"1\">$email<\/mail>' /tmp/$jobbasename");
				
			$filebasename = substr($jobbasename, 0, -4);
			$xml = simplexml_load_file( "/tmp/$jobbasename" );

			if(substr(dirname($jobfile), -6) == "custom")
				parameters_assign($xml, $filebasename . "_custom_" );
			else
				parameters_assign($xml, $filebasename . "_" );

			$path = "/tmp/" . $filebasename . "_" . genRandomString(10) . ".xml";
			$xml->asXML($path);

			if(file_exists("/tmp/$jobbasename"))
				unlink("/tmp/$jobbasename");

			array_push ($jobfilenames, $path);
		}

		foreach ($machines as $machine) {
			foreach ($jobfilenames as $filename) {
				if ($machine->send_job($filename)) {
				    Log::create($machine->get_id(), $machine->get_used_by(), 'JOB_START', "has sent a \"pre-defined\" job to this machine (Job name: \"" . htmlspecialchars(basename($filename)) . "\")");
				} else {
					$error = (empty($error) ? "" : $error) . "<p>".$machine->get_hostname().": ".$machine->errmsg."</p>";
				}
			}
		}
		if (empty($error)) {
			header("Location: index.php");
		}
	}
    $html_title = "Send job";

?>
