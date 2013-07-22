<?php

require_once ('Database.php');
require_once ('MachineReservation.php');

class ReservationsHelper
{

	/**
	 * Array of MachineReservation objects.
	 */
	private $reservations = array ();

	public function __construct ($object = null)
	{
		if (isset ($object)) {
			$type = gettype ($object);
			if ($type == 'array') {
				$this->reservations = $object;
			} else if ($type == 'object') {
				$class = get_class ($object);
				switch ($class) {
				case 'User':
					$this->getForUser ($object);
					break;
				case 'Machine':
					$this->getForMachine ($object);
					break;
				default:
					// Nothing happens
				}
			}
		}
	}

	public function setReservations ($res)
	{
		$this->reservations = $res;
	}

	public function getReservations ()
	{
		return $this->reservations;
	}

	public function haveReservations ()
	{
		return count ($this->getReservations ());
	}

	public function addReservation ($res)
	{
		$this->reservations[] = $res;
	}

	public function removeReservation ($res)
	{
		for ($i = 0; $i < count ($this->reservations); $i++) {
			if ($res->equals ($this->reservations[$i])) {
				unset ($this->reservations[$i]);
			}
		}
	}

	private function getQuotedList ($db, $list) {
		$retlist = array ();
		foreach ($list as $val) {
			$retlist[] = $db->quote ($val);
		}
		return $retlist;
	}

	private function createInClause ($attribute_name, $ids)
	{
		$db = Database::build ();
		$inclause = '';
		if (! empty ($attribute_name) && count ($ids)) {
			$inclause = $attribute_name . ' IN ('
				. join (', ', $this->getQuotedList ($db, $ids))
				. ')';
		}
		return $inclause;
	}

	public function deleteForMachine ($machine, $users_ids)
	{
		$res = 0;
		if (! count ($users_ids)) {
			return $res;
		}

		$db = Database::build ();
		$where[] = 'machine_id = ' . $db->quote ($machine->get_id ());
		if (count ($users_ids)) {
			$where[] = $this->createInClause ('user_id', $users_ids);
		}
		try {
			$res = $db->delete ('user_machine', $where);
		} catch (Zend_Db_Exception $e) {
			error_log ($e->getMessage ());
		}
		return $res;
	}

	/**
	 * Process the select statement by conditions.
	 *
	 * @param array $conditions An associative array of conditions.
	 * @param boolean $one Return only one row if true.
	 */
	private function selectFromDb ($conditions, $one = false)
	{
		if (! isset ($conditions)) {
			return null;
		}
		$db = Database::build ();
		$this->deleteExpired ();
		$sel = $db->select ()
			->from('user_machine',
			       array ('machine_id', 'user_id',
				      'user_note', 'reserved',
				      'expires'));
		foreach ($conditions as $cond => $val) {
			$sel->where ($cond, $val);
		}
		if ($one) {
			return $db->fetchRow ($sel);
		}
		return $db->fetchAll ($sel);
	}

	/**
	 * Returns a single reservation specified by conditions.
	 *
	 * @param mixed $conditions Associative array of conditions
	 * and values to be used in the search.
	 */
	public function getSingleReservation ($conditions)
	{
		if (! isset ($conditions)) {
			return null;
		}
		$row = $this->selectFromDb ($conditions, true);
		if ($row) {
			return $this->createFromRow ($row);
		}
		return null;
	}

	public function getForMachineUser ($machine, $user)
	{
		$res = null;
		if (! (is_null ($machine) || is_null ($user))) {
			$mid = $machine->get_id ();
			$uid = $user->getId ();
			/* Search fetched reservations first. */
			foreach ($this->getReservations () as $r) {
				if ($mid == $r->getMachineId ()
				    && $uid == $r->getUserId ()) {
					$res = $r;
				}
			}
			/* Ask database if we do not have it, yet. */
			if (is_null ($res)) {
				$cond['machine_id = ?'] = $mid;
				$cond['user_id = ?'] = $uid;
				$res = $this->getSingleReservation ($cond);
			}
		}
		return $res;
	}

	/**
	 * Returns true or false if the machine or user or combination
	 * has some reservation.
	 *
	 * Any of the parameters can be 
	 */
	public function hasReservation ($machine = null, $user = null)
	{
		$res = array ();
		if (isset ($machine) && isset ($user)) {
			$res = $this->getForMachineUser ($machine, $user);
		} else if (isset ($machine)) {
			$res = $this->getForMachine ($machine);
		} else if (isset ($user)) {
			$res = $this->getForUser ($user);
		}
		return count ($res);
	}

	public function createReservation ($machine, $user,
					   $user_note = null,
					   $expires = null)
	{
		if (isset ($machine) && isset ($user)) {
			if (! empty ($expires)) {
				$date = new Zend_Date ($expires);
				$expires = $date->toString ('YYYY-MM-dd HH:mm:ss');
			} else {
				$expires = NULL;
			}

			$data = array (
				'machine_id' => $machine->get_id (),
				'user_id' => $user->getId (),
				'user_note' => $user_note,
				'expires' => $expires
				);
			$res = new MachineReservation ($data);
			return $res->persist ();
		}
		return 0;
	}

	public function delete ($machine, $user)
	{
		$result = 0;
		$cond = array ();
		$cond['machine_id = ?'] = $machine->get_id ();
		$cond['user_id = ?'] = $user->getId ();
		$reserv = $this->getSingleReservation ($cond);
		if (isset ($reserv)) {
			$result = $reserv->delete ();
		}
		return $result;
	}

	public function mergeForMachine ($new_mach_id, $old_mach_id) {
		$db = Database::build ();
		/* Remove reservations that would be duplicate.
		 * params: $old_mach_id, $new_mach_id */
		$delete_sql = 'DELETE FROM user_machine WHERE machine_id = ? AND user_id IN '
			. '(SELECT umach.user_id FROM '
			. '(SELECT user_id FROM user_machine WHERE machine_id = ?) '
			. 'AS umach )';
		$db->query ($delete_sql, array ($old_mach_id, $new_mach_id));
		$update_sql = 'UPDATE user_machine SET machine_id = ? WHERE machine_id = ?';
		return $db->query ($update_sql, array ($new_mach_id, $old_mach_id));
	}

	/**
	 * Creates a reservation from a row of database results.
	 */
	private function createFromRow ($row)
	{
		return new MachineReservation ($row);
	}

	private function createFromRows ($rows)
	{
		$res_objs = array ();
		foreach ($rows as $row) {
			$obj = $this->createFromRow ($row);
			$res_objs[] = $obj;
		}
		return $res_objs;
	}

	/**
	 * Set reservations of this object to all reservations of this
	 * user.
	 */
	public function getForUser ($user)
	{
		$db = Database::build ();
		$res = $this->selectFromDb (
			array (
				'user_id = ?' => $user->getId ()
				));
		$reserv = $this->createFromRows ($res);
		$this->reservations = $reserv;
		return $this->getReservations ();
	}

	/**
	 * Set reservations of this object to all reservations for the
	 * machine.
	 */
	public function getForMachine ($machine)
	{
		$db = Database::build ();
		$res = $this->selectFromDb (
			array (
				'machine_id = ?' => $machine->get_id ()
				));
		$this->reservations = $this->createFromRows ($res);
		return $this->getReservations ();
	}

	public function getMachines ()
	{
		$machines = array ();
		foreach ($this->reservations as $reser) {
			$machine = $reser->getMachine ();
			if (isset ($machine)) {
				$machines[] = $machine;
			}
		}
		return $machines;
	}

	public function getUsers ()
	{
		$users = array ();
		foreach ($this->reservations as $reser) {
			$user = $reser->getUser ();
			if (isset ($user)) {
				$users[] = $user;
			}
		}
		return $users;
	}

	public function getUsersId ()
	{
		$users_id = array ();
		foreach ($this->reservations as $r) {
			$users_id[] = $r->getUserId ();
		}
		return $users_id;
	}

	public function isReservator ($user)
	{
		foreach ($this->getUsers () as $usr) {
			if ($user->equals ($usr))
				return true;
		}
		return false;
	}

	public function isLastReservator ($machine, $user)
	{
		return count ($this->getForMachine ($machine)) == 1
			&& $this->isReservator ($user);
	}

	/**
	 * Returns a list of machine names of all stored reservations.
	 */
	public function getMachineNames ()
	{
		$machines = $this->getMachines ();
		$machine_names = array ();
		foreach ($machines as $machine) {
			$machine_names[] = $machine->get_hostname ();
		}
		return $machine_names;
	}

	/**
	 * Returns a list of user names of all stored reservations.
	 */
	public function getUserNames ()
	{
		$users = $this->getUsers ();
		$user_names = array ();
		foreach ($users as $user) {
			$user_names[] = $user->getNameOrLogin ();
		}
		return $user_names;
	}

	public function prettyPrintMachines ($glue = ', ')
	{
		return join ($glue, $this->getMachineNames ());
	}

	public function prettyPrintUsers ($glue = ', ', $details = false)
	{
		$retString = '';
		if ($details) {
			$lines = array ();
			foreach ($this->getReservations () as $r) {
				$user = $r->getUser ();
				$exp_date = $this->getFormattedDate (
					$r->getExpires ());
				$line = $user->getNameOrLogin ()
					. (! empty ($exp_date) ?
					   ' (Expires on ' . $exp_date . ')'
					   : '');
				$lines[] = $line;
			}
			$retString = join ($glue, $lines);
		} else {
			$retString = join ($glue, $this->getUserNames ());
		}
		return $retString;
	}

	public function printUsersToTable ()
	{
		$cols = array ('user'		=> 'User name',
			       'reserved'	=> 'Reserved',
			       'expires'	=> 'Expires',
			       'note'		=> 'Note');
		$res = '<table class="list text-main">';
		$res .= '<tr><th>' . join ('</th><th>', array_values ($cols))
			. '</th></tr>';
		foreach ($this->getReservations () as $r) {
			$user = $r->getUser ();
			$td['user'] = $user->getNameOrLogin ();
			$td['reserved'] = $this->getFormattedDate ($r->getReserved ());
			$td['expires'] = $this->getFormattedDate ($r->getExpires ());
			$td['note'] = $r->getUserNote ();
			$res .= '<tr><td><div>' . join ('</div</td><td><div>', $td)
				. '</div></td></tr>';
		}
		return $res .= '</table>';
	}

	public function __toString ()
	{
		return join (' ', $this->reservations);
	}

	public function getFormattedDate ($date)
	{
		if (isset ($date) && ! empty ($date)) {
			$zdate = new Zend_Date ($date);
			$date = $zdate->toString ('YYYY-MM-dd');
		}
		return $date;
	}

	public function deleteExpired () {
		try {
			$db = Database::build ();
			$sql = 'DELETE FROM user_machine WHERE expires < NOW()';
			return $db->query ($sql);
		} catch (Exception $e) {
			error_log ($e->getMessage ());
			return null;
		}
	}
}
?>
