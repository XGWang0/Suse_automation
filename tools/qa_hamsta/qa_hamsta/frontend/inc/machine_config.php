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
$is_pdo = 1;

require( 'lib/qaconf_db.php' );

$conn_id=connect_to_mydb();
$step=http('step','l');
$submit=http('submit');
$id=http('id');
if( $step=='list' )	{
	header('Content-Type: text/plain');
	$ip=http('ip',$_SERVER['REMOTE_ADDR']);
	print "# IP address is $ip\n";
	$machine_id=machine_get_by_ip($ip);
	$configs=qaconfs_for_machine($machine_id);
	print "# qaconf_ids are: ".join(',',$configs)."\n";
	print qaconf_format_data(qaconf_merge($configs));
	exit;
}
else if(($submit=='sync'||$step=='sync') && $id )    {
	print do_sync( $id, null, http('verbose') );
	exit;
}
else if( $submit=='sync_all' || $step=='sync_all' )	{
	header('Content-Type: text/plain');
	$data=qaconf_list();
#	$ret=array('qaconf_id'=>'id','desc'=>'desc','sync_url'=>'sync_url','result'=>'result');
	print "ID\tdesc\tURL\tresult\n------------------------\n";
	for( $i=1; $i<count($data); $i++ )	{
		$r=$data[$i];
		if( $r['sync_url'] )	{
			print $r['qaconf_id']."\t".$r['desc']."\t".$r['sync_url']."\t";
			print do_sync($r['qaconf_id'],$r['sync_url'])."\n";
		}
	}
	exit;
}


$a_machines=http('a_machines');
$perm_machines=$user && machine_permission($a_machines,array('owner'=>'machine_config','other'=>'machine_config_reserved'));
$perm_system=capable('master_administration');
if( !$perm_machines && !$perm_system )
	disable();

function do_sync($id,$sync_url=null,$verbose=0)
{
	if( !$sync_url )
		$sync_url=qaconf_get_sync_url($id);
	if( $sync_url && $file=fopen($sync_url,'r') )	{
		$text='';
		while( !feof($file) )
			$text .= fgets( $file, 4096 );
		fclose( $file );
		qaconf_replace_body_unparsed($id,$text);
		if( $verbose )
			print "<pre>$text</pre>\n";
		return "OK";
	}
	return "ERROR: Cannot open sync URL '$sync_url'";
}

?>
