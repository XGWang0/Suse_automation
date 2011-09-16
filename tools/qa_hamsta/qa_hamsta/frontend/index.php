<?php
/**
 * This is the main file of the HAMSTA Web Frontend.
 *
 * <ol>
 *  <li>Loads all include files from lib/</li>
 *  <li>Includes the logic of the requested page from inc/</li>
 *  <li>Prints the page header, body (from html/) and footer</li>
 * </ol>
 */

error_reporting(E_ALL | E_STRICT);

session_start();

define('HAMSTA_FRONTEND', 1);

require("config.php");
require("globals.php");

require("lib/request.php");
require("lib/db.php");
require("lib/machine.php");
require("lib/log.php");
require("lib/module.php");
require("lib/jobrun.php");
require("lib/configuration.php");
require("lib/group.php");
require("lib/roles.php");
require("lib/Utilfunc.php");

require_once("../tblib/tblib.php");

$go = request_str("go");

$pages = array(
    "machines",
    "edit_machines",
    "del_machines",
    "machine_details",
    "action_history",
    "module_details",
    "validation",
    "qacloud",
    "about",
    "qapackagejob",
    "customjob",
    "autotest",
    "diff_config",
    "diff_module",
    
    "groups",
    "autobuild",
    "list_testcases",
    "create_group",
    "create_autobuild",
    "del_group",
    "group_del_machines",
    "delete_autobuild",

    "jobruns",
    "job_details",
    "send_job",
    "mm_job",
    "reinstall",
    "autopxe",
    "vhreinstall",
    "newvm",
    "del_virtual_machines",
    "upgrade"
);

if (!in_array($go, $pages)) {
    $go = $pages[0];
}

require("inc/$go.php");
require("html/header.php");

if(isset($_SESSION['message']))
{
	if(isset($_SESSION['mtype']) and $_SESSION['mtype'] == "success")
	{
		echo html_success($_SESSION['message']);
	}
	else
	{
		echo html_error($_SESSION['message']);
	}
	unset($_SESSION['message']);
}
if(isset($_SESSION['mtype']))
{
	unset($_SESSION['mtype']);
}

require("html/$go.php");
require("html/footer.php");

?>
