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

if (!defined('HAMSTA_FRONTEND')) {
	$go = 'job_details';
	return require("index.php");
}

$search = new MachineSearch();
$search->filter_in_array(request_array("a_machines"));
$machines = $search->query();

$machine_names = array();
foreach($machines as $machine)
	$machine_names[] = array( $machine->get_id(), $machine->get_hostname() );

#print "<pre>\n"; 
#print_r(request_array('a_machines')); 
#print_r($_REQUEST);
#print "</pre>\n";

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
		$name    = get_val($vals,'name',$id);
		$num_min = get_val($vals,'num_min',0);
		$num_max = get_val($vals,'num_max',0);
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

	if(isset($xml->parameters->parameter)){

		$parameter_hash = array();

		# right div
		$formdata .= "<div class=\"text-main\" style=\"float: left; width: 45%; margin-left: 10px; margin-top: 0px;\">";
		$formdata .= "<div class=\"text-main\">Edit <spam class=\"text-medium bold\">Additial Parameters</spam> in the below form.</div>";
		$formdata .= "<div class=inputblock>\n<h2>for all of SUT</h2>\n</div>";

		# div of table
		$formdata .= "<div style=\"margin-top: 10px; padding: 10px 10px 20px 5px; border: 1px solid #cdcdcd\">";
		//$formdata .= "<table class=\"sort text-main\"\">";

		$param_map = array();
		$param_id = 0;
		foreach( $xml->parameters->parameter as $parameter )
		{
			$paramname = trim($parameter['name']);
			$paramtype = trim($parameter['type']);
			$paramdeft = trim($parameter['default']);
			$paramlabl = trim($parameter['label']);

			//print "name ==>> $paramname type ==>> $paramtype default ==>> $paramdeft label ==>> $paramlabl <br />";

			if($paramname == "" || $paramtype == "")
				continue;
			// parameter name must be composed by number, letter or '_'"
			if(!preg_match( "/^[0-9a-zA-Z_]+$/", $paramname))
				continue;

			// ensure one name can only be defined once
			if(isset($parameter_hash[$paramname]))
				continue;
			else
				$parameter_hash[$paramname] = "";

			$optlist = array();
			$opt_id = 0;
			$count = count($parameter->option);
			$options = $parameter->option;
			for($i=0; $i<$count; $i++)
			{
				$opt = $options[$i];
				$optvalue = trim($opt['value']);

				$optlist[$opt_id++] = array('value'=>$optvalue, 'label'=>$opt);
			}

			if($opt_id == 0)
				$paramcont = $parameter;

			if($paramlabl == "")
				$paramlabl = $paramname;

			$param_map[$param_id++] = array( 'name'=>$paramname, 'type'=>$paramtype,
					'default'=>$paramdeft, 'label'=>$paramlabl, 'content'=>$paramcont,
					'option'=>$optlist );
		}

		// get the parameter table
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
		
		if(isset($xml->parameters->parameter))
		{
			$paracount =  count($xml->parameters->parameter);
			// get all of the parameters
			foreach( $xml->parameters->parameter as $parameter )
			{
				/* old code for deleting no need attribute, but I don't wanna delete it now, just keep them
				$i = 0;
				foreach($parameter->attributes() as $key=>$val)
					$atthash[$i++] = $key;
				
				foreach($atthash as $att)
				{
					if($att == "name")
						continue;
					unset($parameter[$att]);
				}
				*/

				// remove all of the old child nodes
				$parachild = dom_import_simplexml($parameter);
				while ($parachild->firstChild) {
					$parachild->removeChild($parachild->firstChild);
				}				 
				
				// add value child node to parameter
				$paraname = trim($parameter['name']);
				$paravalue = $_POST[$paraname];
				if(trim($parameter['type']) == "textarea")
				{
					$paravalue = trim_parameter($paravalue);

				}

				$node = $parachild->ownerDocument;
				$parachild->appendChild($node->createCDATASection($paravalue));
			}
		}

		# write the file, modify the file name, because the XML is modified, if not, maybe it will be override by other job
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
				Log::create($machine->get_id(), $machine->get_used_by(), 'JOB_START', "has sent a \"multi-machine\" job including this machine (Job name: \"" . htmlspecialchars(basename($filename)) . "\")");
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

# replace with tblib/tblib_common.php/hash_get()
function get_val($hash,$key,$default)
{
	if( isset($hash[$key]) )
		return $hash[$key];
	return $default;
}

?>
