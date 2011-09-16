<?php

/**
 * Log
 *
 * Represents a single log entry
 * 
 * @author Dan Collingridge <dcollingridge@novell.com>
 */
class Log {

	/**
	 * fields 
	 * 
	 * @var array Associative array containing the values of all database 
	 *   fields of this machine
	 */
	private $fields;

	/**
	 * __construct 
	 *
	 * Creates a new instance of Log. The constructor is meant to be called
	 * only by functions that directly access the database and have to get an
	 * object from their query result.
	 * 
	 * @param array $fields Values of all database fields
	 */
	function __construct($fields) {
		$this->fields = $fields;
	}

	/**
	 * create
	 *
	 * Creates a new log.
	 *
	 * @param int $machine Database ID of the machine that is getting a new log entry
	 * @param string $user User string for the new log entry
	 * @param string $text Text for the new log entry
	 * @param array $machines Array of Machine objects which form
	 *   the new group
	 * @return void
	 */
	public static function create($machine, $user, $type, $text, $what = "", $job = NULL) {
		if (!($stmt = get_pdo()->prepare('INSERT INTO `log` (`machine_id`, `log_user`, `log_type`, `log_text`, `log_what`, `job_on_machine_id`) VALUES (:machine, :user, :type, :text, :what, :job)'))) {
			return null;
		}
		$stmt->bindParam(':machine', $machine);
		$stmt->bindParam(':user', $user);
		$stmt->bindParam(':type', $type);
		$stmt->bindParam(':text', $text);
		$stmt->bindParam(':what', $what);
		$stmt->bindParam(':job', $job);
		try {
			$stmt->execute();
		} catch(Exception $e) {
			$errorInfo = $stmt->errorInfo();

			# Some other error
			return -1;
		}
	}

	/**
	 * get_log_id
	 *
	 * @access public
	 * @return int Database ID of the machine log entry
	 */
	function get_log_id() {
		if( isset($this->fields["log_id"]) )
			return $this->fields["log_id"];
		else
			return NULL;
	}

	/**
	 * get_log_user
	 *
	 * @access public
	 * @return string Actor of the machine log entry (currently same as "usedby"
	 *    field in machine table)
	 */
	function get_log_user() {
		if( isset($this->fields["log_user"]) )
			return $this->fields["log_user"];
		else
			return NULL;
	}

	/**
	 * get_log_type
	 *
	 * @access public
	 * @return string Type of the log entry
	 */
	function get_log_type() {
		if( isset($this->fields["log_type"]) )
			return $this->fields["log_type"];
		else
			return NULL;
	}

	/**
	 * get_log_what
	 *
	 * @access public
	 * @return string What of the log entry
	 */
	function get_log_what() {
		if( isset($this->fields["log_what"]) )
			return $this->fields["log_what"];
		else
			return NULL;
	}


	/**
	 * get_log_text
	 *
	 * @access public
	 * @return string Text of the machine log entry
	 */
	function get_log_text() {
		if( isset($this->fields["log_text"]) )
			return $this->fields["log_text"];
		else
			return NULL;
	}

	/**
	 * get_log_time
	 *
	 * @access public
	 * @return string Time of the machine log entry. It is a unix timestamp
	 *    so that PHP's date function can easily manipulate the format.
	 */
	function get_log_time() {
		if( isset($this->fields["log_time"]) )
			return $this->fields["log_time"];
		else
			return NULL;
	}

	/**
	 * get_log_time_string
	 *
	 * @access public
	 * @return string Time of the machine log entry as a string
	 *    so that PHP's date function can easily manipulate the format.
	 */
	function get_log_time_string() {
		if( isset($this->fields["log_time"]) )
			return $this->fields["log_time"];
		else
			return NULL;
	}

}

?>
