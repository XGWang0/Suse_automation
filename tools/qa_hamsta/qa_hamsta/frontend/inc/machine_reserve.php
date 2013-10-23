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
	return require("index.php");
}

$config = ConfigFactory::build();

/* If authentication is not used, it is not possible to get the
 * user. */
if ($config->authentication->use) {
	$user = User::getCurrent ();
	// TODO check if user has privileges to reserve machines
	if (! isset ($user)) {
		Notificator::setErrorMessage ('You have to be logged in'
					      . ' to be able to reserve machines.');
		header ('Location: index.php');
		exit ();
	}

	$search = new MachineSearch ();
	$search->filter_in_array (request_array("a_machines"));
	$machines = $search->query ();

	$usage = request_str ('usage');
	$names = array ();
	$rh = new ReservationsHelper ();
	foreach ($machines as $m) {
		if ($rh->hasReservation ($m)) {
			continue;
		}
		if ($rh->createReservation ($m, $user)) {
			if (! empty ($usage)) {
				$m->set_usage ($usage);
			} else {
				$m->set_usage ('Reserved to run tests');
			}
			$names[] = $m->get_hostname();
		} else {
			// TODO Add error reporting for this machine.
		}
	}

	Notificator::setSuccessMessage ("These machines were succesfully reserved: "
					. join (', ', $names));
} else {
	Notificator::setErrorMessage ('You can use this type of reservation'
				      . ' only with the user authentication.');
}

header ('Location: index.php');
exit ();

?>
