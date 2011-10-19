<?php
/* ****************************************************************************
  Copyright © 2011 Unpublished Work of SUSE. All Rights Reserved.
  
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
?>
