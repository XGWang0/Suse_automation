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

	/* power_s390 currently accepts userid (ie LINUX152 and action (startm, stop etc ..).
	* for more details see http://s390zvi33.suse.de/zvm/index.php
	* 
	*/
   
function power_s390($powerslot, $action) {
	/* 
	 * Actuall command that we send to the interface wia http post method.
	 * Notoce that for some array variables we have to use [0] since interface
	 * accepts and actually expects the input to be complex array/
	 * zVM version seems to be allways 54, IPL device seems to be allways 0150, for some
	 * reason count has to be set, althouhg there are more variables that can be (and in
	 * this case were) ommited.
	 */
	$userid = $powerslot;
	function s390_interface($userid, $action) {
		$s390_action = 'start';
		/*
	 	* URL of web interface for controlling s390 VM's
	 	*/
		$s390_controller = 'http://s390zvi33.suse.de/zvm/formaction.php';
		$command = array(
			'count' => urlencode('0'),
			'ipl_device[0]' => urlencode('0150'),
			'zvm_version[0]' => urlencode('54'),
			'userid[0]' => urlencode("$userid"),
			'action' => urlencode("$action"),
		);
		/* 
		 *We transform array to http request string
		 */

		$command_string = http_build_query($command);
		/* 
		 *And here we execute everything using php_curl
		 */

		$address = curl_init($s390_controller);

		curl_setopt($address, CURLOPT_URL, $s390_controller);
		curl_setopt($address, CURLOPT_POST, count($command));
		curl_setopt($address, CURLOPT_POSTFIELDS,$command_string);

		curl_exec($address);
		curl_close($address);
		}
	if ($action == "start") {
		s390_interface($userid, 'start');
		}
	else if ($action == "stop") {
		s390_interface($userid, 'stop');
		}
	else if ($action == "restart") {
		s390_interface($userid, 'stop');
		sleep(5);
		s390_interface($userid, 'start');
		}
	}

	/*
	 * function power_apc is used to start/stop power on apc 
	 * power switches, we hawe to set community to qanet, and grant
	 * this community write+ privileges.
	 *
	 */

function power_apc($powerswitch, $powerslot, $action) {
	$apc_host = $powerswitch;
	$acp_port = $powerslot;
	$apc_snmp_community = 'qanet';
	$apc_snmp_mib_generic = '1.3.6.1.4.1.318.1.1.12.3.3.1.1.4.';
	$apc_snmp_mib_port = $apc_snmp_mib_generic.$apc_port;

	if ($action == "start")
		$apc_action = '1';
	else if ($action == "stop")
		$apc_action = '2';
	else if ($action == "restart")
		$apc_action = '3';
	/*
	 * This is eqal to issuing 'snmpset -c qanet -v 1 apc2.qa.suse.cz 1.3.6.1.4.1.318.1.1.12.3.3.1.1.4.7 i 2'
	 * (example will casuse apc2.qa.suse.cz port 7 using community qanet to stop
	 *
	 */
	snmpset($apc_host, $apc_snmp_community, $apc_snmp_mib_port, 'i', $apc_action);
	}
?>
