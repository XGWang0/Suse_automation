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


# get random string, <len> is the length of the string
/**
  * Generate random string
  * @param number $len the length of random string
  * @return random string
  **/
function genRandomString($len)
{
	$chars = array(
			"a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k",
			"l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v",
			"w", "x", "y", "z", "A", "B", "C", "D", "E", "F", "G",
			"H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R",
			"S", "T", "U", "V", "W", "X", "Y", "Z", "0", "1", "2",
			"3", "4", "5", "6", "7", "8", "9"
		      );
	$charsLen = count($chars) - 1;

	shuffle($chars);

	$output = "";
	for ($i=0; $i<$len; $i++)
	{
		$output .= $chars[mt_rand(0, $charsLen)];
	}

	return (string)$output;
}

/**
  * format parameter
  * @param string $parameter the parameter to be format
  * @return string formatted string
  **/
function trim_parameter($parameter)
{
	$parameterSplit = explode("\n", $parameter);
	$parameterContent = "";

	$firstline = true;

	foreach($parameterSplit as $singleParameter)
	{
		# delete the first empty lines
		$lineContent = rtrim($singleParameter, "\r\n\t ");
		if(empty($lineContent) && ($firstline == true))
			continue;

		$firstline = false;

		$parameterContent .= $lineContent . ',';
	}

	# omit the last comma
	substr(rtrim($parameterContent), 0, -1);

	return (string)$parameterContent;
}

/**
  * get paramter hash maps from the xml.
  * @param SimpleXMLElement $xml the of XML file
  * @return array of parameters
  **/
function get_parameter_maps($xml)
{
	# parameter hash array, use it to avoid one name being used twice or more
	$parameter_hash = array();

	$param_map = array();
	$param_id = 0;
	# get parameter map
	if(isset($xml->parameters->parameter))
	{
		foreach( $xml->parameters->parameter as $parameter )
		{
			$paramname = trim($parameter['name']);
			$paramtype = trim($parameter['type']);
			$paramdeft = trim($parameter['default']);
			$paramlabl = trim($parameter['label']);

			if($paramname == "" || $paramtype == "")
				continue;
			# parameter name must be composed by number, letter or '_'"
			if(!preg_match( "/^[0-9a-zA-Z_]+$/", $paramname))
				continue;

			# ensure one name can only be defined once
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

			# if not define the label, use name instead of it
			if($paramlabl == "")
				$paramlabl = $paramname;

			$param_map[$param_id++] = array( 'name'=>$paramname, 'type'=>$paramtype,
					'default'=>$paramdeft, 'label'=>$paramlabl, 'content'=>$paramcont,
					'option'=>$optlist );
		}
	}

	return $param_map;
}

/**
  * Get paramter table from the paramters hash table, parameter maybe named begin with '$prefix'.
  * @param SimpleXMLElement $hash the hash map of parameters
  * @param string $prefix, all of parameters will be named begin with it 
  * @return string of tables
  **/
function get_parameter_table($hash, $prefix)
{
	$table_data = "<table class=\"sort text-main\"\">\n";

	foreach( $hash as $param )
	{
		$type = trim($param['type']);
		$name = trim($param['name']);
		$label = trim($param['label']);
		$default = trim($param['default']);

		$content = $param['content'];
		$optlist = $param['option'];

		# show all of the input form
		if($type == "string") # for string parameter
		{
			$table_data .= "<tr>\n";
			$table_data .= "<th valign=\"top\">$label:</th>\n";
			$varname = "$prefix" . "$name";

			$table_data .= "<td><input type=\"text\" size=\"20\" name=\"$varname\" value=\"$default\"></td>\n";
			$table_data .= "</tr>\n";
		}
		elseif($type == "enum") # for enumation parameter
		{
			$table_data .= "<tr>\n";
			$table_data .= "<th valign=\"top\">$label: </th>\n";
			$varname = "$prefix" . "$name";
			$table_data .= "<td><select name=\"$varname\">\n";

			foreach ($optlist as $option)
			{
				$optlabel = $option['label'];
				$optvalue = $option['value'];

				if( trim($optlabel) == trim($default) )
					$table_data .= "<option value=\"$optvalue\" selected>$optlabel</option>\n";
				else
					$table_data .= "<option value=\"$optvalue\">$optlabel</option>\n";

			}

			$table_data .= "</td></tr>\n";
		}
		elseif($type == "textarea")  # for textarea parameter
		{
			$table_data .= "<tr>\n";
			$table_data .= "<th valign=\"top\">$label: </th>\n";
			$content = preg_replace('/\t/', ' ', $content);
			$content = preg_replace('/ (?= )/', '', trim($content));
			$varname = "$prefix" . "$name";
			$table_data .= "<td><textarea cols=\"20\" rows=\"5\"  name=\"$varname\">$content</textarea></td>\n";
			$table_data .= "</tr>\n";
		}
		else    # you can define other type of parameters here
			continue;

	}
	$table_data .=  "</table>\n";

	return $table_data;
}

/**
  * Process the parameter tags of XML file.
  * @param SimpleXMLElement $xml the job XML
  **/
function parameters_assign($xml, $prefix)
{
	if(isset($xml->parameters->parameter))
	{

		# get all of the parameters
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

			# remove all of the old child nodes
			$parachild = dom_import_simplexml($parameter);
			while ($parachild->firstChild)
				$parachild->removeChild($parachild->firstChild);

			# add value child node to parameter
			$paraname = trim($parameter['name']);
			$paravalue = request_str($prefix . $paraname);

			# for textarea data
			if(trim($parameter['type']) == "textarea")
				$paravalue = trim_parameter($paravalue);

			$node = $parachild->ownerDocument;
			$parachild->appendChild($node->createCDATASection($paravalue));
		}
	}
}

?>
