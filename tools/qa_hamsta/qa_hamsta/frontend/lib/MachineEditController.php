<?php

require_once ('Zend/Validate.php');
require_once ('Zend/Validate/Date.php');

require_once ('ReservationsHelper.php');
require_once ('Notificator.php');
require_once ('log.php');

class MachineEditController
{

	private $machine_list = array ();
	private $error_list = array ();
	private $edit_fields = array ();

	public function __construct ($machines, $edit_fields = array ())
	{
		$this->machine_list = $machines;
		$this->edit_fields = $edit_fields;
	}

	public function setEditFields ($fields_array)
	{
		$this->edit_fields = $fields_array;
	}

	public function getEditFields ()
	{
		return $this->edit_fields;
	}

	private function processClear ()
	{
		$user = User::getCurrent ();
		$rh = new ReservationsHelper ();
		if (! isset ($user)) {
			$this->addError ('You have to be logged and '
					 . ' have privileges to clear this machine.');
			return;
		}

		foreach ($this->machine_list as $machine) {
			if ($rh->hasReservation ($machine, $user)) {
				if ($rh->isLastReservator ($machine, $user)) {
					$machine->set_usage('');
				}
				$rh->delete ($machine, $user);
				Log::create($machine->get_id(), $user->getLogin (),
					    'RELEASE', "has unreserved this machine");
			} else {
				$this->addMachineError ($machine, 'Can not unreserve.'
							.' You do not have reservation.');
			}
		}
	}

	private function wasError ()
	{
		return count ($this->error_list);
	}

	private function addError ($error_string)
	{
		if (! empty ($error_string)) {
			array_push ($this->error_list, $error_string);
		}
	}

	private function addMachineError ($machine, $error_string)
	{
		if (isset ($machine)) {
			$this->addError ($machine->get_hostname ()
					 . ': ' . $error_string);
		}
	}

	private function formatPermissions ($perms)
	{
		$perm_str="";
		if (count ($perms)) {
			$perm_str = join (",", $perms);
		}
		return $perm_str;
	}

	public function getErrors ()
	{
		return $this->error_list;
	}

	private function getErrorsString ()
	{
		$err_str = '';
		if ($this->wasError ()) {
			$err_str = join (", ", $this->getErrors ());
		}
		return $err_str;
	}

	private function validateInput ()
	{
		$machines_ids = request_array ("a_machines");
		$usage_all = array_combine($machines_ids, request_array('usage'));

		foreach ($this->machine_list as $machine)
		{
			$machine_id = $machine->get_id ();
			$machine_usage = $usage_all[$machine_id];
			$machine_users = request_array ('used_by_' . $machine_id);
			$machine_expires = request_array ('expires_' . $machine_id);
			$machine_user_notes = request_array ('user_note_' . $machine_id);
			$used_by_array =  request_array ('used_by_' . $machine_id);
			$machine_expires = request_array ('expires_' . $machine_id);

			foreach ($machine_users as $uid) {
				$expires = $machine_expires[$uid];

				if (! empty ($expires)) {
					$validator = new Zend_Validate_Date();
					if (! $validator->isValid($expires)) {
						foreach ($validator->getMessages () as $m)
							$this->addMachineError ($machine, $m);
					}
				}
			}

			if (! empty ($machine_usage) && count ($used_by_array) < 1) {
				$this->addMachineError ($machine,
							'Usage cannot be set without a reservation.');
			}

		}
                return (! $this->wasError ());
	}

	private function processSubmit ()
	{
		if (! $this->validateInput ()) {
			Notificator::setErrorMessage ($this->getErrorsString ());
			return;
		}

		$machines_ids = request_array ('a_machines');
		$usage_all = array_combine($machines_ids, request_array('usage'));
		$current_user = User::getCurrent ();

		foreach ($this->machine_list as $machine) {
			$machine_id = $machine->get_id ();
			/* Get reservators data from request */
			$machine_reservators = request_array ('used_by_' . $machine_id);
			$machine_expires = request_array ('expires_' . $machine_id);
			$machine_user_notes = request_array ('user_note_' . $machine_id);
			$machine_usage = $usage_all[$machine_id];

			/* Handle reservations. */
			$rh = new ReservationsHelper ();
			$rh->getForMachine ($machine);
			$old_users = $rh->getUsersId ();
			$users_to_delete = array ();

			/* Get reservators to delete or update. */
			foreach ($rh->getReservations () as $res) {
				$uid = $res->getUserId ();
				if (! in_array ($uid, $machine_reservators)) {
					$users_to_delete[] = $uid;
				} else {
					Log::create($machine_id, $current_user->getLogin (),
						    'CONFIG', 'has updated reservation values');
					/* Update reservation values. */
					$res->setNote ($machine_user_notes[$uid]);
					$res->setExpires ((empty ($machine_expires[$uid]) ? NULL :
							   $machine_expires[$uid]));
				}
			}

			/* Delete not wanted reservations. */
			$rh->deleteForMachine ($machine, $users_to_delete);

			/* Create new reservations. */
			foreach ($machine_reservators as $uid) {
				if (! in_array ($uid, $old_users)) {
					$machine_user = User::getById ($uid);
					$machine_expire = $machine_expires[$uid];
					$user_note = request_str ($machine_user_notes[$uid]);
					$rh->createReservation ($machine, $machine_user,
								$machine_user_notes[$uid],
								$machine_expire);
					Log::create($machine_id, $current_user->getLogin (),
						    'CONFIG', "has created a reservation for "
						    . $machine_user->getLogin ());
				}
			}

			/* Update the rest of the machine fields. */
			$machine->set_usage ($machine_usage);
			$machine->set_consolesetdefault(0);
			$machine->set_perm ($this->formatPermissions (
						    request_array("perm_".$machine_id)));
			$this->processFields ($machine, $current_user);
			$default_options = request_array("default_options");
			$machine_option = isset ($default_options[$machine_id])
						 ? $default_options[$machine_id] : '';

			if ($machine->get_def_inst_opt() != trim ($machine_option)) {
				$machine->set_def_inst_opt (trim ($machine_option));
				Log::create($machine->get_id (), $current_user->getLogin (),
					    'CONFIG', "has set the 'Default Install Options' to "
					    . "'$machine_option'");
			}
		}
	}

	private function processFields ($machine, $current_user)
	{
		$machine_id = $machine->get_id ();

		/* Process the rest of the edit fields. */
		foreach ($this->edit_fields as $field => $label) {
			$input = request_array ($field);
			$r_value = isset ($input[$machine_id]) ?
				$input[$machine_id] : '';
			$gfunc = "get_" . $field;
			$sfunc = "set_" . $field;

			if (method_exists ($machine, $gfunc)
			    && method_exists ($machine, $sfunc)) {
				$old_value = $machine->$gfunc ();
				$retval = $machine->$sfunc ($r_value);
				/* pkacer@suse.com: Most set functions
				 * in Machine class unfortunately do
				 * not have a return statement. I put
				 * this exception here for the
				 * powertype because if the powertype
				 * function is not available, then the
				 * value is silently ignored (not set). */
				if ($field == 'powertype' && is_null ($retval)) {
					$this->addMachineError ($machine, 'The requested powertype function "'
								. $r_value
								. '" is not available. Value was not set.'
								. ' Please check for supported types.');
				}

				if (is_string ($old_value) && strcmp ($old_value, $r_value)) {
					$machine_id = $machine->get_id ();
					$user_login = $current_user->getLogin ();
					if (empty ($r_value)) {
						Log::create ($machine_id, $user_login,
							     'RELEASE', "has cleared the '$label' field");
					} else {
						Log::create ($machine_id, $user_login,
							     'CONFIG', "has set the value of '$label' to '$r_value'");
					}
				}
			}
		}
	}

	private function doDefault ()
	{
		// The default action to do.
	}

	public function processRequest ($request_type)
	{
		switch ($request_type) {
		case "clear":
			$this->processClear ();
			break;
		case "submit":
			$this->processSubmit ();
			break;
		default:
			$this->doDefault ();
		}

		/* TODO Maybe this should be done by caller? */
		if ($this->wasError ()) {
			Notificator::setErrorMessage ($this->getErrorsString ());
		} else {
			Notificator::setSuccessMessage ('The requested actions were successfully completed.');
		}
	}
}

?>
