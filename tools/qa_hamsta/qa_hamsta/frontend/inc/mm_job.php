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

if (!defined('HAMSTA_FRONTEND')) {
	$go = 'job_details';
	return require("index.php");
}

$search = new MachineSearch();
$search->filter_in_array(request_array("a_machines"));
$machines = $search->query();

$machine_names = array();

/* Check the user is logged in and has privileges to send job to
 * selected machines. */
machine_permission_or_disabled($machines,$perm_send_job);
foreach($machines as $machine)
	$machine_names[] = array( $machine->get_id(), $machine->get_hostname() );

#print "<pre>\n"; 
#print_r(request_array('a_machines')); 
#print_r($_REQUEST);
#print "</pre>\n";

$custom_flag = request_str('customflag');
if( $custom_flag != 1 ) # not custom define job
	$filename = request_str("filename");
$email = request_str('mailto');

# Generate some form contents here instead of the HTML part, 
#   otherwise the most of the code would be duplicite
# Here the form is prepared and validated.
# If everything is OK, it is sent, otherwise it is printed, 
#   so that the user can fill in data/correct them.
$formdata=''; 
$errors = array();

if( request_str('submit') && !is_readable($filename) )
	$errors[] = "Cannot read file '$filename'";
else if( request_str('submit') )
{
	machine_permission_or_redirect($machines,$perm_send_job);
	$xml = simplexml_load_file( $filename );
	$roles = roles_read($xml);
#	print "<pre>";
#	print_r($roles);
#	print "</pre>";

	$test_description = $xml->config->description;
	$test_name =$xml->config->name;

	# everything OK, send job ?
	$send=1; 

	# assigned SUTs, to prevent duplicities
	$assigned=array(); 

	# role assignment: role_id -> array(machine_id, ...)
	$role_map=array();
	
	# form HTML

	# left div
	$formdata .= "<div class=\"text-main\" style=\"float: left; width: 35%\">";
	$formdata .= "<div class=\"text-main\"> Job <spam class=\"text-medium bold\" title=\"$test_description\">$test_name</spam> will be run on below SUT.</div>";
	
	foreach( $roles as $id=>$vals )
	{
		# process the role table
		$name    = hash_get($vals,'name',$id);
		$num_min = hash_get($vals,'num_min',0);
		$num_max = hash_get($vals,'num_max',0);
		$height = max( $num_max, 15 );
		$multiple = ( !$num_max||$num_max>1 ? 'multiple="multiple"' : '' );
		$data = null;

		# try to read request data
		if( !isset($_REQUEST["$name"]) )
			$send=0;
		else
		{
			$data=$_REQUEST["$name"];
			if( !is_array($data) )
				$data = array($data);

			# validate - num_min
			$cnt = count($data);
			if( $num_min && $cnt<$num_min )
				$errors[] = "Too few machines in role $id '$name' ($cnt < $num_min)";

			# validate - num_max
			if( $num_max && $cnt>$num_max )
				$errors[] = "Too many machines in role $id '$name' ($cnt > $num_max)";

			# map machines to roles
			foreach( $data as $machine_id )
			{
				$machine = Machine::get_by_id($machine_id);
				if( !$machine )
					continue;

				$hostname=$machine->get_hostname();
				$ip  =$machine->get_ip_address();

				# validate - machine to max 1 role
				if( isset($assigned[$machine_id]) )
					$errors[] = "Machine '$hostname' assigned to multiple roles";

				# fill the mapping
				$assigned[$machine_id] = $id;
				$role_map[$id][] = array( 'name'=>$hostname, 'ip'=>$ip );
			}
		}

		# form HTML
		$formdata .= '<div class="inputblock">';
		$formdata .= "\n<h2>$name</h2>\n";
		$formdata .= base_select( $name, $machine_names, $height, $multiple, $data );
		$formdata .= "</div>\nSelect ".( $num_min ?
				( $num_max ? 
				  ( $num_min==$num_max ? "$num_min" :"$num_min to $num_max") 
				  : "at least $num_min") :
				( $num_max ? "up to $num_max" : "some" )
				)." machine(s).";
	}

	$formdata .= "<div style=\"margin-left: 20px; margin-top: 50px;\">";
	$formdata .= "<input type=\"submit\" name=\"submit\" align=\"right\" value=\"Start multi-machine job\"/>";
	$formdata .= "</div>";

	$formdata .= '</div>'; # close of left div
	
	# if it is a prametrized job
	if(isset($xml->parameters->parameter))
	{
		# right div
		$formdata .= "<div class=\"text-main\" style=\"float: left; width: 45%; margin-left: 10px; margin-top: 0px;\">";
		$formdata .= "<div class=\"text-main\">Edit <spam class=\"text-medium bold\">Additional Parameters</spam> in the form below.</div>";
		$formdata .= "<div class=inputblock>\n<h2>for all of SUT</h2>\n</div>";

		# div of table
		$formdata .= "<div style=\"margin-top: 10px; padding: 10px 10px 20px 5px; border: 1px solid #cdcdcd\">";
		
		$param_map = get_parameter_maps($xml);
	
		# get the parameter table
		$parameter_table = get_parameter_table($param_map, "");
		$formdata .= $parameter_table;

		$formdata .= '</div></div>';
		$formdata .= "<div style=\"clear: left;\">&nbsp;</div>\n";
	}

	# no submit until all OK
	if( count($errors) != 0 || !request_str('submit') )
		$send=0;
	
	if( $send )
	{
		# modify the XML
		$xml->config->mail = $email;
		roles_assign( $xml, $role_map );
		parameters_assign($xml, "" );
		
		# write the file, modify the file name, because the XML file has been modified,
		# if not, maybe it will be override by other job
		$path = '/tmp/' . basename($filename);
		$path = substr($path, 0, -4);
		$path .= "_" . genRandomString(10) . ".xml";

		$xml->asXML($path);

		# send job
		foreach( array_keys($assigned) as $machine_id )
		{
			$machine = Machine::get_by_id($machine_id);
			if( !$machine )	{
				$errors[] = "No such machine_id : $machine_id";
				continue;
			}

			if($machine->send_job($path)) {
				Log::create($machine->get_id(), $user->getLogin (), 'JOB_START', "has sent a \"multi-machine\" job including this machine (Job name: \"" . htmlspecialchars(basename($filename)) . "\")");
			} else {
				$errors[] = $machine->get_hostname() . ': ' . $machine->errmsg;
			}
		}
		if (count($errors) == 0)
			header("Location: index.php");
	}
}
$html_title = "Multi-machine job details";

if (count($errors) != 0) {
	$_SESSION['message'] = implode("\n", $errors);
	$_SESSION['mtype'] = "fail";
}

?>
