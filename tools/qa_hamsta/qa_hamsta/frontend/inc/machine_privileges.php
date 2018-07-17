<?php

require_once ('globals.php');

/* Web service providing privileges for user and machines. */
$action = request_str ('action');
$machine_ids = request_array ('machine_ids');
$user_name_login = request_str ('user');

$search = new MachineSearch ();
$search->filter_in_array ($machine_ids);
$machines = $search->query ();

$names = array ();

/* Try to get user from provided data. Here we do not know if login,
 * name or external identifier is provided.
 *
 * If you want to use this for other purposes (like finding users),
 * note that the getById() method search criteria depends on
 * configuration in 'config.ini'. Either 'login' or 'external_id'
 * field is searched.*/
$user = User::getByName ($user_name_login);
if (! $user) {
	$user = User::getById ($user_name_login);
}

if ($user) {
	$allowed = 0;
	$action_reserved = $action . '_reserved';
	$alw = $user->isAllowed ($action);
	$alw_res = $user->isAllowed ($action_reserved);
	$rh = new ReservationsHelper ();

	foreach ($machines as $m) {
		$has_reservations = count ($rh->getForMachine ($m));
		$users_machine = count ($rh->getForMachineUser ($m, $user));
		if ((! $has_reservations || $users_machine) && $alw) {
			$allowed = $alw;
		} else if ($alw_res) {
			$allowed = $alw_res;
		}

		$names[] = array (
			'id'		=> $m->get_id (),
			'name'		=> $m->get_hostname (),
			'allowed'	=> $allowed);
	}
}

header ('Content-Type: application/json; charset=utf-8');
print (json_encode ($names));
exit ();

?>
