<?php

require_once ('Zend/Db.php');
require_once ('ConfigFactory.php');
require_once ('Database.php');
require_once ('User.php');

class MachineReservation
{

	/**
	 * 'machine_id'
	 * 'user_id'
	 * 'expires'
	 * ''
	 */
	private $data;

	/**
	 * Creates an instance only in memory.
	 *
	 * Use persist() function to save in the database.
	 */
	public function __construct ($data)
	{
		$this->data = $data;
	}

	/**
	 * Deletes this reservation from the database.
	 *
	 * When the reservation is deleted it should not be used
	 * anymore unless you need to write it back again. Then it is
	 * better to just change some parameters.
	 */
	public function delete ()
	{
		$result = 0;
		try {
			$db = Database::build ();
			$conds = array (
				'machine_id = ' . $db->quote ($this->getMachineId ()),
				'user_id = ' . $db->quote ($this->getUserId ()));
			$result= $db->delete ('user_machine', $conds);
		} catch (Zend_Db_Exception $e) {
			error_log ($e->getMessage ());
		}
		return $result;
	}

	/**
	 * Write a this new reservation in the database.
	 *
	 * @return integer Number of inserted rows.
	 */
	public function persist ()
	{
		try {
			$db = Database::build ();
			$data = array (
				'machine_id'	=> $this->getMachineId (),
				'user_id'	=> $this->getUserId (),
				'user_note'	=> $this->getUserNote (),
				'expires'	=> $this->getExpires ()
				);
			return $db->insert ('user_machine', $data);
		} catch (Zend_Db_Exception $e) {
			error_log ($e->getMessage ());
			return 0;
		}
	}

	/**
	 * Updates value[s]? in the database.
	 *
	 * @param array $bind An associative array of database
	 * attributes and values.
	 *
	 * @param array $where An array of WHERE bindings and
	 * values. Defaults to this reservation user and machine id.
	 *
	 * @return integer Number of updated rows.
	 */
	private function updateValue ($bind, $where = null)
	{
		$updated = 0;
		if (! isset ($where)) {
			$where['user_id = ?'] = $this->getUserId ();
			$where['machine_id = ?'] = $this->getMachineId ();
		}

		try {
			$db = Database::build ();
			$updated = $db->update ('user_machine', $bind,
						$where);
		} catch (Zend_Db_Exception $e) {
			error_log ($e->getMessage ());
		}
		return $updated;
	}

	/**
	 * Set specific attribute to the object. Expected types are
	 * 'user' or 'machine'. This function sets an attribute of an
	 * existing reservation in the database. If such reservation
	 * does not exist, it is created.
	 */
	private function setAttribute ($object_type, $identifier)
	{
		$bind = array (
			"{$object_type}_id" => $identifier
			);

		switch ($obj_type) {
		case 'user':
			$where['user_id = ?'] = $this->getUserId ();
			$where['machine_id = ?'] = $this->getMachineId ();
			$this->data['user_id'] = $identifier;
			break;
		case 'machine':
			$where['user_id = ?'] = $this->getUserId ();
			$where['machine_id = ?'] = $this->getMachineId ();
			$this->data['machine_id'] = $identifier;
			break;
		default:
			error_log ("The object type '" . $obj_type
				   . "' is not supported.");
			return 0;
		}
		return $this->updateValue ($bind, $where);
	}

	/**
	 * Set user of this reservation. Also in the database.
	 */
	public function setUser ($user)
	{
		return $this->setAttribute ('user', $user->getId ());
	}

	/**
	 * Set machine of this reservation. Also in the database.
	 */
	public function setMachine ($machine)
	{
		return $this->setAttribute ('machine', $machine->get_id ());
	}

	/**
	 * Set user note for this reservation.
	 */
	public function setNote ($note)
	{
		$bind = array ('user_note' => $note);
		$this->data['user_note'] = $note;
		return $this->updateValue ($bind);
	}

	/**
	 * Set expiration date for this reservation.
	 */
	public function setExpires ($value)
	{
		$date_value = NULL;
		if (! empty ($value)) {
			$date = new Zend_Date ($value);
			$date_value = $date->toString ('YYYY-MM-dd HH:mm:ss');
		}
		$bind = array ('expires' => $date_value);
		$this->data['expires'] = $date_value;
		return $this->updateValue ($bind);
	}

	public function getMachine ()
	{
		return Machine::get_by_id ($this->data['machine_id']);
	}

	public function getUserId ()
	{
		return $this->data['user_id'];
	}

	public function getMachineId ()
	{
		return $this->data['machine_id'];
	}

	public function getUser ()
	{
		return User::getById ($this->getUserId (),
				      ConfigFactory::build ());
	}

	public function getReserved ()
	{
		return $this->data['reserved'];
	}

	public function getUserNote ()
	{
		return $this->data['user_note'];
	}

	public function getExpires ()
	{
		return $this->data['expires'];
	}

	public function __get ($attr)
	{
		return $this->data[$attr];
	}

	public function __set ($attr, $value)
	{
		$this->data[$attr] = $value;
	}

	public function __isset ($attr)
	{
		return isset ($this->data[$attr]);
	}

	/**
	 * Convert this object to string.
	 *
	 * @return string String representation of the reservation.
	 */
	public function __toString ()
	{
		$conf = ConfigFactory::build ();
		$user = User::getById ($this->getUserId (), $conf);
		$machine = Machine::get_by_id ($this->getMachineId ());
		return $user . ' has reserved ' . $machine;
	}

	public function equals ($res)
	{
		return $this->getUserId () == $res->getUserId ()
			&& $this->getMachineId () == $res->getMachineId ();
	}

}

?>
