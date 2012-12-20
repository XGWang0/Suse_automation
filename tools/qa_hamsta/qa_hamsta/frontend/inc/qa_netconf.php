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
  $go = 'about';
  return require("index.php");
}

$html_title = "QA network configuration";

if (User::isLogged ())	{
    /* Name of this variable is differend due to included TBLib
     * dependand library (frontenduser). */
    $logged_user = User::getById (User::getIdent (), $config);
}
/* Yet another library using DB connection. This should be unified
 * some time. I propose some library which we do not have to
 * maintain. */
$mysqlhost = $config->database->params->host;
$mysqldb = $config->database->params->dbname;
$mysqluser = $config->database->params->username;
$mysqlpasswd = $config->database->params->password;

require( 'lib/qaconf_db.php' );

$conn_id=connect_to_mydb();
$step=http('step','l');
if( $step=='list' )	{
	header('Content-Type: text/plain');
	$ip=http('ip',$_SERVER['REMOTE_ADDR']);
	print "# IP address is $ip\n";
	$configs=array(); # TODO: global, site
	$machine=Machine::get_by_ip($ip);
	if( $machine )	{
		$groups=Group::get_groups_by_machine($machine);
		foreach( array_keys($groups) as $group_id )	{
			$group=Group::get_by_id($group_id);
			$qaconf_id=$group->get_qaconf_id();
			if( $qaconf_id )
				$configs[]=$qaconf_id;
		}
		$qaconf_id=$machine->get('qaconf_id');
		if( $qaconf_id )
			$configs[]=$qaconf_id;
	}
	print "# qaconf_ids are: ".join(',',$configs)."\n";
	print qaconf_format_data(qaconf_merge($configs));
	exit;
}
?>
