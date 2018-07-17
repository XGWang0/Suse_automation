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
     * Logic of the machine_send_job page 
     */
if (!defined('HAMSTA_FRONTEND')) {
        $go = 'machine_send_job';
        return require("index.php");
}

# for delete custom file
$option = request_str("opt");
$machine_list = request_str("machine_list");
$custom_file = request_str("file");
  
$search = new MachineSearch();
$job = new Job();
if($machine_list != "")
    	$machines_id_array = explode(",", $machine_list);
else
	$machines_id_array = request_array("a_machines");

foreach ($machines_id_array as $mid) {
	$job->add_machine_id($mid);
}
$search->filter_in_array ($machines_id_array);
$machines = $search->query ();

/* Only custom defined file can be deleted. */
if ($option == "delete") {
	/* Check for permissions or redirect from the page. */
	machine_permission_or_redirect ($machines, $perm_send_job);

	$custom_file = $config->xml->dir->default . "/" . $custom_file;

	if (file_exists($custom_file))
		unlink ($custom_file);
}
 
$job_editing_allowed = capable ('job_edit');
machine_permission_or_disabled ($machines, $perm_send_job);

$resend_job=request_str("xml_file_name");
$filenames =request_array("filename");

if (request_str("submit")) {
	machine_permission_or_redirect($machines_id_array,$perm_send_job);

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
		$job->addfile($path);
	}

	if (!$job->send_job()){
		$error = $job->errmsg;
	}

	if (empty($error)) {
		redirect (array (
				  'succmsg' => "The job[s] has/have been successfully sent.")
				);
	}
}

    $html_title = "Send job";

?>
