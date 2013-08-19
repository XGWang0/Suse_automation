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
		'hostname'=>'Hostname',
		'status_string'=>'Status',
		'used_by'=>'Reservations',
		'usage'=>'Usage',
		'job_overview'=>'Job Overview',
		'group'=>'Group',
		'product'=>'Product',
		'architecture'=>'Installed Arch',
		'architecture_capable'=>'CPU Arch',
		'kernel'=>'Kernel',
		'cpu_numbers'=>'CPUs',
		'memory_size'=>'Memory',
		'disk_size'=>'Disks',
		'cpu_vendor'=>'CPU vendor',
		'affiliation'=>'Affiliation',
		'ip_address'=>'IP Address',
		'maintainer_string'=>'Maintainer',
		'notes'=>'Notes',
		'unique_id'=>'Unique ID',
		'serialconsole'=>'Serial Console',
		'consolesetdefault'=>'Console Enabled',
		'consolespeed'=>'Console Speed',
		'consoledevice'=>'Console Device',
		'powerswitch'=>'Power Switch',
		'powertype'=>'Power Switch Type',
		'powerslot'=>'Power Switch Slot',
		'def_inst_opt'=>'Default Install Options',
		'perm'=>'Machine Permissions',
		'role'=>'Role',
		'type'=>'Type',
		'vh'=>'Virtual Host'
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

$hamstaVersion = htmlspecialchars(`rpm -q qa_hamsta-frontend`);

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
 * same configuration.
 *
 * This configuration is accesible in the default namespace. If you
 * need to create it somewhere else, just call
 * `ConfigFactory::build()' without parameters.
 *
 * This works from anywhere provided this file stays in the same
 * directory as config.ini file.
 */
$config = ConfigFactory::build ("Ini", dirname(__FILE__) . '/config.ini',
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

?>
