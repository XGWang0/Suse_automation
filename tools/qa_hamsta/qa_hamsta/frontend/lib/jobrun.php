<?php

/**
 * Represents a single run of a job
 *
 * @package Jobs
 * @author Kevin Wolf <kwolf@suse.de> 
 * @version $Rev: 1771 $
 *
 * @copyright
 * Copyright (c) 2011 Unpublished Work of SUSE. All Rights Reserved.<br />
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
class JobRun {

	/**
	 * @var array Associative array containing the values of all database 
	 *	  fields of this job.
	 */
	private $fields;

	/**
	 * Creates a new instance of JobRun.
	 *
	 * The constructor is meant to be called only by functions
	 * that directly access the database and have to get an object
	 * from their query result.
	 * 
	 * @param array $fields Values of all database fields.
	 */
	function __construct($fields) {
		$this->fields = $fields;
                $this->fields['id']=$this->fields['job_id'];
	}

	/**
	 * Updates all fields with current data from the database.
	 * 
	 * @access public
	 * @return void
	 */
	function update_from_db() {
		$sql = 'SELECT * FROM job j LEFT JOIN job_on_machine k USING(job_id) WHERE j.job_id = :id ORDER BY j.job_id DESC';
		if (!($stmt = get_pdo()->prepare($sql))) {
			return null;
		}
		$stmt->bindParam(':id', $this->fields["job_id"]);

		$stmt->execute();
		$row = $stmt->fetch(PDO::FETCH_ASSOC);

		$this->fields = $row;
	}

	/**
	 * Gets all jobs ever run, including pending jobs.
	 * 
	 * @param int $limit Optional. Maximal number of jobs to return.
	 * @param int $start Optional. Number of first row to be returned.
	 * @access public
	 * @return array Array of JobRun objects or null on error.
	 */
	static function find_all($limit = 10, $start = 0) {
		$sql = 'SELECT * FROM job j LEFT JOIN job_on_machine k USING(job_id) ORDER BY j.job_id DESC';
		if ($limit) {
			$sql .= ' LIMIT '.((int) $start).','.((int) $limit);
		}
		
		if (!($stmt = get_pdo()->prepare($sql))) {
			return null;
		}
		
		$stmt->execute();
		$result = array();
		while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
			$result[] = new JobRun($row);
		}

		return $result;
	}
	
	/**
	 * Counts all jobs ever run.
	 * 
	 * @access public
	 * @return int Number of all jobs ever run, including pengding jobs.
	 */
	static function count_all() {
		$sql = 'SELECT COUNT(*) FROM job';
		
		if (!($stmt = get_pdo()->prepare($sql))) {
			return null;
		}
		
		$stmt->execute();
		$result = $stmt->fetchColumn();
		$stmt->closeCursor();

		return $result;
	}
	
	/**
	 * Get all jobs which are in a given status.
	 * 
	 * @param mixed $status_id ID of the status to search for.
	 * @param int $limit Optional. Maximal number of rows to return.
	 * @access public
	 * @return array Array of JobRun objects.
	 */
	static function find_by_status($status_id, $limit = 0) {
		$sql = 'SELECT * FROM job j LEFT JOIN job_on_machine k USING(job_id) WHERE job_status_id = :status_id ORDER BY j.job_id DESC';
		if ($limit) {
			$sql .= ' LIMIT '.((int) $limit);
		}

		if (!($stmt = get_pdo()->prepare($sql))) {
			return null;
		}
		$stmt->bindParam(':status_id', $status_id);
		
		$stmt->execute();
		$result = array();
		while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
			$result[] = new JobRun($row);
		}

		return $result;
	}
	
	/**
	 * Gets job run instance by identifier.
	 * 
	 * @param int|string $id ID of the JobRun to get.
	 * @access public
	 * @return \JobRun JobRun with the given ID or null if no JobRun is found.
	 */
	static function get_by_id($id) {
		$sql = 'SELECT * FROM job j LEFT JOIN job_on_machine k USING(job_id) WHERE j.job_id = :id ORDER BY j.job_id DESC';
		if (!($stmt = get_pdo()->prepare($sql))) {
			return null;
		}
		$stmt->bindParam(':id', $id);

		$stmt->execute();
		$row = $stmt->fetch(PDO::FETCH_ASSOC);

		return $row ? new JobRun($row) : null;
	}

	/**
	 * Getter for identifier of this job.
	 * 
	 * @access public
	 * @return int ID of the JobRun.
	 */
	function get_id() {
		return $this->fields["job_id"];
	}
	
	/**
	 * Getter for the name of this job.
	 * 
	 * @access public
	 * @return string Name of the JobRun.
	 */
	function get_name() {
		return $this->fields["short_name"];
	}
	
	/**
	 * Getter for the description of this job.
	 * 
	 * @access public
	 * @return string Description of the JobRun.
	 */
	function get_description() {
		return $this->fields["description"];
	}
	
	/**
	 * Getter for the owner of this job.
	 * 
	 * @access public
	 * @return string Owner of the JobRun.
	 */
	function get_owner() {
		return $this->fields["job_owner"];
	}

	/**
	 * Geter for the machine of this job.
	 * 
	 * @access public
	 * @return \Machine Machine the job is run on.
	 */
	function get_machine() {
		return Machine::get_by_id($this->fields["machine_id"]);
	}
	
	/**
	 * Getter for the configuration of this job.
	 * 
	 * @access public
	 * @return \Configuration Current configuration of the machine at the 
	 *	  start of the job.
	 */
	function get_configuration() {
		return Configuration::get_by_id($this->fields["config_id"]);
	}

	/**
	 * Getter for the last few lines of the log of this job.
	 * 
	 * @access public
	 * @return string Last output lines of the job.
	 */
	function get_last_log() {
		return $this->fields["last_log"];
	}

	/**
	 * Gets file name of the xml job description.
	 * 
	 * @access public
	 * @return string File name of the XML job description.
	 */
	function get_xml_filename() {
		return $this->fields["xml_file"];
	}
	
	/**
	 * Gets xml with job description.
	 * 
	 * @access public
	 * @return string XML job description.
	 */
	function get_xml_job() {
		return file_get_contents($this->fields["xml_file"]);
	}
	
	/**
	 * Gets return code[s]? of this job.
	 * 
	 * @access public
	 * @return string Return code information (may contain more than one 
	 * return code).
	 */
	function get_return_code() {
		return $this->fields["return_status"];
	}
	
	/**
	 * Gets name of the xml file returned by slave.
	 * 
	 * @access public
	 * @return string Filename of the XML result file returned by the slave.
	 */
	function get_return_xml_filename() {
		return $this->fields["return_xml"];
	}
	
	/**
	 * Gets content of the result file returned by slave.
	 * 
	 * @access public
	 * @return string XML result file returned by the slave.
	 */
	function get_return_xml_content() {
		if( $this->fields["return_xml"] )
			return file_get_contents($this->fields["return_xml"]);
		else
			return null;
	}

	/**
	 * Gets start time of this job.
	 * 
	 * @access public
	 * @return string Date and time of the start of the job.
	 */
	function get_started() {
		return $this->fields["start"];
	}
	
	/**
	 * Gets stop time of this job.
	 * 
	 * @access public
	 * @return string Date and time when the job was stopped.
	 */
	function get_stopped() {
		return $this->fields["stop"];
	}
	
        /**
         * Gets status id of this job.
         * 
         * @return int Id of the status of this job.
         */
	function get_status_id() {
		return $this->fields["job_status_id"];
	}

	/**
	 * Gets current status name of this job.
	 * 
	 * @access public
	 * @return string Name of the job status.
	 */
	function get_status_string() {
		$stmt = get_pdo()->prepare('SELECT job_status FROM job_status WHERE job_status_id = :status_id');
		$stmt->bindParam(':status_id', $this->fields["job_status_id"]);
		
		$stmt->execute();
		return $stmt->fetchColumn();
	}

	/**
	 * Returns true or false depending on the job finished status.
	 *
	 * @return boolean True if the job is in final state, false otherwise.
	 */
	public function is_finished () {
		$status = $this->get_status_id ();
		return in_array ($status, array (3, 4, 5));
	}

	/**
	 * Cancels a scheduled job.
	 * 
	 * @access public
	 * @return boolean true if the job could be successfully cancelled; false 
	 * if an error occured (e.g. job is already running).
	 */
	function cancel() {
		$stmt = get_pdo()->prepare('UPDATE job SET job_status_id = 5 WHERE job_id = :job_id AND job_status_id IN (0, 1)');
		$stmt->bindParam(':job_id', $this->fields["id"]);
		$stmt->execute();

		$stmt = get_pdo()->prepare('UPDATE job_on_machine SET job_status_id = 5 WHERE job_id = :job_id AND job_status_id IN (0, 1)');
		$stmt->bindParam(':job_id', $this->fields["id"]);
		$stmt->execute();
		if ($stmt->rowCount() > 0) {
			$this->set_stopped();
			$this->update_from_db();
			$this->get_machine()->update_busy();
			return true;
		}

		return false;
	}

	/**
	 * Set status of a scheduled job.
	 *
	 * @param int $status_id Status id to set this job to.
	 *
	 * @access public
	 * @return void
	*/
	function set_status($status_id) {
		$stmt = get_pdo()->prepare('UPDATE job set job_status_id=:status_id where job_id = :job_id ');
		$stmt->bindParam(':job_id', $this->fields["id"]);
		$stmt->bindParam(':status_id', $status_id);
		$stmt->execute();

		$stmt = get_pdo()->prepare('UPDATE job_on_machine set job_status_id=:status_id where job_id = :job_id ');
		$stmt->bindParam(':job_id', $this->fields["id"]);
		$stmt->bindParam(':status_id', $status_id);
		$stmt->execute();

		if ($stmt->rowCount() > 0) {
			$this->update_from_db();
			$this->get_machine()->update_busy();
			return true;
		}

		return false;
	}

	/**
	 * Set stop timestamp of a scheduled job.
	 * 
	 * @access public
	 * @return void
	*/
	function set_stopped() {
		$stmt = get_pdo()->prepare('UPDATE job_on_machine set stop=NOW() where job_id = :job_id ');
		$stmt->bindParam(':job_id', $this->fields["id"]);
		$stmt->execute();
		
		if ($stmt->rowCount() > 0) {
			$this->update_from_db();
			$this->get_machine()->update_busy();
			return true;
		}

		return false;
	}

	/**
	 * Checks if the job can be cancelled.
	 * 
	 * @access public
	 * @return boolean true if the job can be cancelled, false otherwise.
	 */
	function can_cancel() {
		$stmt = get_pdo()->prepare('SELECT COUNT(*) FROM job_on_machine WHERE job_id = :job_id AND job_status_id IN (0, 1)');
		$stmt->bindParam(':job_id', $this->fields["id"]);

		$stmt->execute();
		return ($stmt->fetchColumn() > 0);
	}

        /**
	 * Gets log entries of this job.
	 *
	 * @access public
	 * @return array Log array.
	 */
	function get_job_log_entries() {

		$result = array();

		if (!($stmt = get_pdo()->prepare('SELECT * FROM log WHERE machine_id = :machine_id AND job_on_machine_id = :job_on_machine_id ORDER BY log_id ASC'))) {
			return null;
		}

		$stmt->bindParam(':machine_id', $this->fields["machine_id"]);
		$stmt->bindParam(':job_on_machine_id', $this->fields["job_on_machine_id"]);
		$stmt->execute();

		while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
			$result[] = new Log($row);
		}

		return $result;
	}


	
}
?>
