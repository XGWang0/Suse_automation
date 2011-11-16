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
 * Logic of the del_machines page
 *
 * Deletes the selected machines.
 */
if(!defined('HAMSTA_FRONTEND')) {
	$go = 'machine_purge';
	return require("index.php");
}

$msg='';
$ret=null;
$purge = request_str('purge');
$id = request_int('id');
if( $id )	{
	$machine = Machine::get_by_id($id);
}
if( $machine )	{
	if( !strcmp($purge,'log') )	{
		$msg = "log";
		$ret = $machine->purge_log();
	}
	else if( !strcmp($purge,'group') )	{
		$msg = "group membership";
		$ret = $machine->purge_group_membership();
	}
	else if( !strcmp($purge,'job') )	{
		$msg = "job history";
		$ret = $machine->purge_job_history();
	}
	else if( !strcmp($purge,'config') )	{
		$msg = "config history";
		$ret = $machine->purge_config_history();
	}

	if( $msg )	{
		if( $ret )	{
			$_SESSION['message'] = "Machine $msg purged.";
			$_SESSION['mtype'] = 'success';
		}
		else	{
			$_SESSION['message'] = "Failed to purge machine $msg.";
			$_SESSION['mtype'] = 'error';
		}
	}
}
else	{
	$_SESSION['message'] = ( $id ? "No machine with that ID : $id" : "ID not specified" );
	$_SESSION['mtype'] = 'error';
}
header("Location: index.php");
exit();
?>
