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

	function genRefresh($pre_page)
	{
		$pre_value="init";
		$GLOBALS['xml_norefresh'] = "";
		if(request_int("page")){ $GLOBALS['refresh_page'] = "&amp;page=".request_int("page");}else{$GLOBALS['refresh_page']="";};
		if(request_int("machine")){ $GLOBALS['refresh_machine'] = "&amp;machine=".request_int("machine");}else{$GLOBALS['refresh_machine']="";};
		if(request_str("interval") && !preg_match("/^[0-9]+$/", request_str("interval")))
		{
			$pre_value = request_int("pre_value");
			$_SESSION['message'] = 'The refresh interval must be a positive number!';
			$_SESSION['mtype'] = "fail";
		};

		if(request_int("interval")&&(request_int("interval")>0))
		{
			$GLOBALS['refresh_interval'] = "&amp;interval=".request_int("interval");
			$GLOBALS['html_refresh_interval'] = request_int("interval");
			if($pre_page == "jobruns"){ $GLOBALS['html_refresh_uri'] = "index.php?go=jobruns".$GLOBALS['refresh_page'].$GLOBALS['refresh_machine'].$GLOBALS['refresh_interval'];};
			if($pre_page == "job_details"){$GLOBALS['html_refresh_uri'] = "index.php?go=job_details&amp;id=".$GLOBALS['job']->get_id()."&amp;d_return=".$GLOBALS['d_return']."&amp;d_job=".$GLOBALS['d_job'].$GLOBALS['refresh_interval'];};
		} else {
			$GLOBALS['html_refresh_interval'] = 30;
			$GLOBALS['refresh_interval'] = "";
			if($pre_value != "init")
			{	
				$GLOBALS['html_refresh_interval'] = $pre_value;
				$GLOBALS['refresh_interval'] = "&amp;interval=".$pre_value;
			}

			if($pre_page == "jobruns"){ $GLOBALS['html_refresh_uri'] = "index.php?go=jobruns".$GLOBALS['refresh_page'].$GLOBALS['refresh_machine'].$GLOBALS['refresh_interval'];};
			if($pre_page == "job_details"){ $GLOBALS['html_refresh_uri'] = "index.php?go=job_details&amp;id=".$GLOBALS['job']->get_id()."&amp;d_return=".$GLOBALS['d_return']."&amp;d_job=".$GLOBALS['d_job'].$GLOBALS['refresh_interval'];};
		};
		if(request_int("norefresh") || request_int("page") > 0 || ( isset($GLOBALS['job']) && $GLOBALS['job']->get_status_string() != "running" ) )
		{
			unset($GLOBALS['html_refresh_interval']);
			unset($GLOBALS['html_refresh_uri']);
			$GLOBALS['refresh_interval']="";
			$GLOBALS['xml_norefresh'] = "&amp;norefresh=1";
		}


	}

	function TrimArray($Input) {
		if (!is_array($Input))
			return trim($Input);
		return array_map('TrimArray', $Input);
	}

	function profiler_init()	{
		global $prof_begin;
		$prof_begin=microtime(true);
	}

	function profiler_print($where=null)	{
		global $prof_begin;
		$now=microtime(true);
		if( $where )
			print("$where : ");
		printf("%f us<br/>\n",1000000*($now-$prof_begin));
	}

# get random string, <len> is the length of the string
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



# solve the user input command lines
function trim_parameter($parameter)
{
	$parameterSplit = explode("\n", $parameter);
	$parameterContent = "";

	$firstline = true;

	foreach($parameterSplit as $singleParameter)
	{
		// delete the empty lines
		$lineContent = trim($singleParameter, "\r\n\t ");
		if(empty($lineContent))
			continue;

		$parameterContent .= $lineContent . ',';
	}

	substr($parameterContent, 0, -1);

	return (string)$parameterContent;
}

function get_parameter_table($hash, $prefix)
{
	$table_data = "<table class=\"sort text-main\"\">\n";

	foreach($hash as $param)
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

?>
