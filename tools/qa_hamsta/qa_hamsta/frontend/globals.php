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


	$fields_list = array(
                'hostname'     =>  array('name'=>'Hostname', 'type'=>'h'),
		'status_string'=>  array('name'=>'Status', 'type'=>'h'),
		'used_by'      =>  array('name'=>'Reservations', 'type'=>'h'),
		'usage'        =>  array('name'=>'Usage', 'type'=>'h'),
		'job_overview' =>  array('name'=>'Job Overview', 'type'=>'h'),
		'group'        =>  array('name'=>'Group', 'type'=>'h'),
		'product'      =>  array('name'=>'Product', 'type'=>'h'),
		'architecture' =>  array('name'=>'Installed Arch', 'type'=>'h'),
		'architecture_capable'=>array('name'=>'CPU Arch', 'type'=>'h'),
		'kernel'       =>  array('name'=>'Kernel', 'type'=>'h'),
		'cpu_numbers'  =>  array('name'=>'CPUs', 'type'=>'i'),
		'memory_size'  =>  array('name'=>'Memory', 'type'=>'f'),
		'disk_size'    =>  array('name'=>'Disks', 'type'=>'i'),
		'cpu_vendor'   =>  array('name'=>'CPU vendor', 'type'=>'h'),
		'affiliation'  =>  array('name'=>'Affiliation', 'type'=>'h'),
		'ip_address'   =>  array('name'=>'IP Address', 'type'=>'h'),
		'maintainer_string'=>array('name'=>'Maintainer', 'type'=>'h'),
		'notes'        =>  array('name'=>'Notes', 'type'=>'h'),
		'unique_id'    =>  array('name'=>'Unique ID', 'type'=>'h'),
		'serialconsole'=>  array('name'=>'Serial Console', 'type'=>'h'),
		'consolesetdefault'=>array('name'=>'Console Enabled', 'type'=>'h'),
		'consolespeed' =>  array('name'=>'Console Speed', 'type'=>'h'),
		'consoledevice'=>  array('name'=>'Console Device', 'type'=>'h'),
		'powerswitch'  =>  array('name'=>'Power Switch', 'type'=>'h'),
		'powertype'    =>  array('name'=>'Power Switch Type', 'type'=>'h'),
		'powerslot'    =>  array('name'=>'Power Switch Slot', 'type'=>'h'),
		'def_inst_opt' =>  array('name'=>'Default Install Options', 'type'=>'h'),
		'perm'         =>  array('name'=>'Machine Permissions', 'type'=>'h'),
		'role'         =>  array('name'=>'Role', 'type'=>'h'),
		'type'         =>  array('name'=>'Type', 'type'=>'h'),
		'vh'           =>  array('name'=>'Virtual Host', 'type'=>'h'),
		'reserved_master' => array('name'=>'Reserved Hamsta', 'type'=>'h')


	);


/* These fields are displayed by default. That means the user
 * cannot hide them nor display again. */
$default_fields_list = array (
	'hostname',
	'used_by',
	'status_string'
);

/* Hidden fields
 *
 * select 0+ from:
 * 'hostname','status_string','used_by','usage','group',
 * 'product','architecture','architecture_capable','kernel',
 * 'cpu_numbers','memory_size','disk_size','cpu_vendor',
 * 'affiliation','ip_address','maintainer_string','notes',
 * 'unique_id','serialconsole','powerswitch','role','type','vh'
 */
$fields_hidden=array('unique_id');

$qadb_web = exec('/usr/share/qa/tools/get_qa_config qadb_wwwroot');

$virtdisktypes = array("def", "file", "tap:aio", "tap:qcow", "tap:qcow2");

$hamstaVersion = htmlspecialchars ("HAMSTA_VERSION");

/* Set configuration group. Should be stored somewhere (e.g. session)
 * so the command is run only once later.
 *
 * This should be one of 'cz', 'us', 'cn' or 'de' from the global
 * configuration files.
 *
 * The default should be 'production'.
 */
$configuration_group = exec ("/usr/share/qa/tools/location.pl");

/* If the location is not detected by the script, use the default one. */
if (! isset ($configuration_group) || strcmp($configuration_group, "(unknown)") == 0)
{
	$configuration_group = 'production';
}

require_once ('lib/ConfigFactory.php');
/*
 * Initialize global configuration. All subsequent calls to
 * ConfigFactory can be done without parameters and will receive the
 * same configuration: $conf = ConfigFactory::build().
 */
$hamsta_ini_file = (! empty ($_SERVER['HAMSTA_INI_FILE'])
                    ? $_SERVER['HAMSTA_INI_FILE']
                    : dirname(__FILE__) . '/config.ini');
$config = ConfigFactory::build ("Ini", $hamsta_ini_file,
				  $configuration_group);
/* header & footer links */
$naviarr = array (
	"Machines"=>"index.php?go=machines",
	"Groups"=>"index.php?go=groups",
	"Jobs"=>"index.php?go=jobruns",
	"Validation Test"=>"index.php?go=validation",
	"AutoPXE"=>"index.php?go=autopxe",
	"QA Cloud"=>"index.php?go=qacloud",
	"QADB"=>$qadb_web,
	"Documentation" =>(! empty ($config->documentation->link)
		 ? $config->documentation->link : '') ,
	"About Hamsta"=>"index.php?go=about");

$header_charset = $config->database->params->charset;
if (preg_match ('/^utf-?8$/i', $header_charset)) {
	$header_charset = 'utf-8';
}

?>
