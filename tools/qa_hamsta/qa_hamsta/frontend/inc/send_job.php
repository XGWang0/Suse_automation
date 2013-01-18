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
    	$custom_file = $config->xml->dir->default . "/" . $custom_file;

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

	/* Check if user has privileges to send a job to machine. */
	if ( $config->authentication->use )
	  {
	    if ( User::isLogged () && User::isRegistered (User::getIdent (), $config) )
	      {
		$user = User::getById (User::getIdent (), $config);
		if ( $user->isAllowed ('machine_send_job')
		     || $user->isAllowed ('machine_send_job_reserved') )
		  {
		    foreach ($machines as $machine)
		      {
			if ( ! ( $machine->get_used_by_login () == $user->getLogin ()
				 || $user->isAllowed ('machine_send_job_reserved')) )
			  {
			    Notificator::setErrorMessage ("You cannot send a job to a machine that is not reserved"
							  . " or is reserved by other user.");
			    header ("Location: index.php?go=machines");
			    exit ();
			  }
		      }
		  }
		else
		  {
		    Notificator::setErrorMessage ("You do not have privileges to send a job to a machine.");
		    header ("Location: index.php?go=machines");
		    exit ();
		  }
	      }
	    else
	      {
		Notificator::setErrorMessage ("You have to be logged in and registered to send a job to a machine.");
		header ("Location: index.php");
		exit ();
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
				    Log::create($machine->get_id(), $machine->get_used_by_login(), 'JOB_START', "has sent a \"pre-defined\" job to this machine (Job name: \"" . htmlspecialchars(basename($filename)) . "\")");
				} else {
					$error = (empty($error) ? "" : $error) . "<p>".$machine->get_hostname().": ".$machine->errmsg."</p>";
				}
			}
		}
		if (empty($error)) {
			Notificator::setSuccessMessage ('The job[s] has/have been successfully sent.');
			header("Location: index.php");
			exit ();
		}
	}
    $html_title = "Send job";

?>
