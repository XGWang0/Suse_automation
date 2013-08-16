<?php

/**
 * Represents a single log entry.
 *
 * @package Logging
 * @author Dan Collingridge <dcollingridge@novell.com>
 * @version 1.0.0
 *
 * @copyright
 * Copyright (c) 2013 Unpublished Work of SUSE. All Rights Reserved.<br />
 * <br />
 * THIS IS AN UNPUBLISHED WORK OF SUSE.  IT CONTAINS SUSE'S
 * CONFIDENTIAL, PROPRIETARY, AND TRADE SECRET INFORMATION.  SUSE
 * RESTRICTS THIS WORK TO SUSE EMPLOYEES WHO NEED THE WORK TO PERFORM
 * THEIR ASSIGNMENTS AND TO THIRD PARTIES AUTHORIZED BY SUSE IN WRITING.
 * THIS WORK IS SUBJECT TO U.S. AND INTERNATIONAL COPYRIGHT LAWS AND
 * TREATIES. IT MAY NOT BE USED, COPIED, DISTRIBUTED, DISCLOSED, ADAPTED,
 * PERFORMED, DISPLAYED, COLLECTED, COMPILED, OR LINKED WITHOUT SUSE'S
 * PRIOR WRITTEN CONSENT. USE OR EXPLOITATION OF THIS WORK WITHOUT
 * AUTHORIZATION COULD SUBJECT THE PERPETRATOR TO CRIMINAL AND  CIVIL
 * LIABILITY.<br />
 * <br />
 * SUSE PROVIDES THE WORK 'AS IS,' WITHOUT ANY EXPRESS OR IMPLIED
 * WARRANTY, INCLUDING WITHOUT THE IMPLIED WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE, AND NON-INFRINGEMENT. SUSE, THE
 * AUTHORS OF THE WORK, AND THE OWNERS OF COPYRIGHT IN THE WORK ARE NOT
 * LIABLE FOR ANY CLAIM, DAMAGES, OR OTHER LIABILITY, WHETHER IN AN ACTION
 * OF CONTRACT, TORT, OR OTHERWISE, ARISING FROM, OUT OF, OR IN CONNECTION
 * WITH THE WORK OR THE USE OR OTHER DEALINGS IN THE WORK.
 */
class Log {

	/**
	 * @var array Associative array containing the values of all database 
	 *   fields of this machine.
	 */
	private $fields;

	/**
	 * Creates a new instance of Log.
	 *
	 * The constructor is meant to be called only by functions
	 * that directly access the database and have to get an object
	 * from their query result.
	 * 
	 * @param array $fields Values of all database fields.
	 */
	function __construct($fields) {
		$this->fields = $fields;
	}

	/**
	 * Creates a new log.
	 *
	 * @param int $machine Database ID of the machine that is getting a new log entry.
	 * @param string $user User string for the new log entry.
	 * @param string $type One of the allowed of log entry types.
	 * @param string $text Text for the new log entry.
         * @param string $what What entry value of this log.
	 * @param int $job Job on machine identifier.
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
	 * Gets id of this log.
	 *
	 * @access public
	 * @return int Database ID of the machine log entry.
	 */
	function get_log_id() {
		if( isset($this->fields["log_id"]) )
			return $this->fields["log_id"];
		else
			return NULL;
	}

	/**
	 * Getter for a user that created this entry.
	 *
	 * @return string Actor of the machine log entry (the value is
	 *    the same as "user_login" attribute in 'user' relation).
	 */
	public function get_log_user() {
		if( isset($this->fields["log_user"]) )
			return $this->fields["log_user"];
		else
			return NULL;
	}

	/**
	 * Getter for a log entry type.
	 *
	 * @access public
	 * @return string Type of the log entry.
	 */
	function get_log_type() {
		if( isset($this->fields["log_type"]) )
			return $this->fields["log_type"];
		else
			return NULL;
	}

	/**
	 * Getter for a log entry what value.
	 *
	 * @access public
	 * @return string What of the log entry.
	 */
	function get_log_what() {
		if( isset($this->fields["log_what"]) )
			return $this->fields["log_what"];
		else
			return NULL;
	}


	/**
	 * Getter for a log entry text.
	 *
	 * @access public
	 * @return string Text of the machine log entry.
	 */
	function get_log_text() {
		if( isset($this->fields["log_text"]) )
			return $this->fields["log_text"];
		else
			return NULL;
	}

	/**
	 * Getter for a log time.
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
	 * Getter for a log time.
	 *
	 * @access public
	 * @return string Time of the machine log entry as a string
	 *    so that PHP's date function can easily manipulate the format.
	 */
	function get_log_time_string() { // TODO same as get_log_time()
		if( isset($this->fields["log_time"]) )
			return $this->fields["log_time"];
		else
			return NULL;
	}

}

?>
