<?php
/*****************************************************************************
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

/* Used by fronted AJAX (JavaScript) code. Returns JSON representation
 * of different data to be fetched from the server.
 */

require ("../globals.php");
require ("../lib/request.php");
require ("../include/json.php");

/* This is path to the variable to fetch from config in the same
 * format as in frontend INI configuration file.
 *
 * Expected value is e.g. 'gnome-default-patterns' which returns value
 * of the '$config->lists->gnome->default' variable. For expected
 * values see the switch structure below.
 */
$getval = request_str ('getval');
$return = null;

switch ($getval) {
case 'gnome-default-patterns':
	$return = split (' ', $config->lists->gnome->default);
	break;
case 'kde-default-patterns':
	$return = split (' ', $config->lists->kde->default);
	break;
case 'virt-disk-types':
	$return = $virtdisktypes;
	break;
default:
	// Do nothing.
}

print (json_encode ($return));

?>
