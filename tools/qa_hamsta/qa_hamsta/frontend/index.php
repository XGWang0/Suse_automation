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
 * This is the main file of the HAMSTA Web Frontend.
 *
 * <ol>
 *  <li>Loads all include files from lib/</li>
 *  <li>Includes the logic of the requested page from inc/</li>
 *  <li>Prints the page header, body (from html/) and footer</li>
 * </ol>
 */

error_reporting(E_ALL | E_STRICT);

/* Now starts with authentication. */
//session_start();

define('HAMSTA_FRONTEND', 1);

require("globals.php");

require_once ('lib/Notificator.php');
require_once ('lib/UserRole.php');
require_once ('lib/User.php');

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
require("lib/parameters.php");
require("lib/powerswitch.php");

require_once("../tblib/tblib.php");

User::authenticate();

$go = request_str("go");

$pages = array(
    "machines",
    "edit_machines",
    "del_machines",
    "install_client",
    "machine_details",
    "machine_purge",
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
    "del_group_machines",

    "jobruns",
    "job_details",
    "send_job",
    "mm_job",
    "reinstall",
    "autopxe",
    "vhreinstall",
    "newvm",
    "newvm-win",
    "del_virtual_machines",
    "upgrade",
    "merge_machines",
    "edit_jobs",
    "register",
    "user",
    "login",
    "addsut",
    "adminusers",
    "qa_netconf",
    "usedby",
);

if (!in_array($go, $pages)) {
    $go = $pages[0];
}

require("inc/$go.php");
require("html/header.php");

if ( Notificator::hasMessage () )
{
  Notificator::printAndUnset ();
} else {
  Notificator::delete ();
}

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
