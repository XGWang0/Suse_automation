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

  /* This page uses TBLib heavily which is quite unusual to see in
   * Hamsta code. We have decided to use TBLib for this page because
   * of the maintenance relief for the page having the same
   * functionality in Hamsta and QADB.
   *
   * Unfortunatelly this brings also all backsides of the mutual code
   * like model dependency issues, need for more careful edits and
   * many custom changes to the TBLib. If ever moving to more flexible
   * Zend framework and MVC architecture these dependecies should be
   * dropped completely.
   */

/* Set some values controlling behavior of the page. */
$header_args = array (
		   'session' => false,
		   'connect' => true,
		   'icon' => null
		   );

/* We do not want to print header because we would have two headers on
 * the page. */
$print_header = false;

/* Print fancy footer (only some statistics displayed). */
$print_footer = false;

/* Do not print primary keys in tables. */
$no_table_id = true;

/* Name of the page to redirect to. */
$page = 'index.php';

$page_name = 'adminusers';

/* Introduced to controll the behavior of the TBLib functions for
 * Hamsta. */
$page_url_extension = "?go=$page_name";

/* Yet another library using DB connection. This should be unified
 * some time. I propose some library which we do not have to
 * maintain. */
$mysqlhost = $config->database->params->host;
$mysqldb = $config->database->params->dbname;
$mysqluser = $config->database->params->username;
$mysqlpasswd = $config->database->params->password;

require ('../frontenduser/useradmin.php');

?>
