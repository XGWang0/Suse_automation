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
	// print_r($_REQUEST);
    $search = new MachineSearch();
    $search->filter_in_array(request_array("a_machines"));
    $machines = $search->query();

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

			if(isset($xml->parameters->parameter))
			{
				$paracount = count($xml->parameters->parameter);

				// get all of the parameters
				foreach( $xml->parameters->parameter as $parameter )
				{
					// remove all of the old child nodes
					$parachild = dom_import_simplexml($parameter);
					while ($parachild->firstChild) {
						$parachild->removeChild($parachild->firstChild);
					}

					// add value child node to parameter
					$paraname = trim($parameter['name']);
					$paratype = trim($parameter['type']);

					if($paraname == "" || $paratype == "")
						continue;

					$paravalue = request_str($filebasename . "_" . $paraname);
					if(trim($parameter['type']) == "textarea")
					{
						$paravalue = trim_parameter($paravalue);
					}

					$node = $parachild->ownerDocument;
					$parachild->appendChild($node->createCDATASection($paravalue));
				}
			}
			
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
