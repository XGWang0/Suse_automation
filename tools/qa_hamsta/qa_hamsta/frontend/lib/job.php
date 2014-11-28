<?php

/**
 * Represents a single machine.
 *
 * @package Job
 * @author Jerry Tang  <jtang@suse.de> 
 * @version $Rev: 1841 $
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
class Job {

	/**
	 * @var array Associative array containing the values of all database 
	 *	  fields of this machine.
	 */
	private $fields;

	/**
	 * @var resource Socket to the master command line interface.
	 */
	private static $master_socket = null;

	
	/**
	 * @var string Error message returned by the master.
	 */
	public $errmsg = "";

	/**
	 * static @var string Error message returned by the master.
	 */
	private static $readerr = "";


	/**
	 * Creates a new instance of Job.
	 *
	 * The constructor is meant to be called only by functions
	 * that directly access the database and have to get an object
	 * from their query result.
	 * 
	 * @param array $fields Values of all database fields.
	 */
	function __construct() {
		$this->fields = array();
		$this->fields['filenames'] = array();
		$this->fields['machines_ip'] = array();
		$this->fields['machines'] = array();
		$this->fields['success_job'] = array();
		$this->fields['fail_job'] = array();
	}

	/**
	 * Add file to file list.
	 *
	 * @param string $file XML file for the job
	 * @access public
	 * @return bool true if the file could be added; false on error
	 */
	function addfile($filename) {
		if (!$filename) return false;
		$this->fields['filenames'][] = $filename;
	}

	/**
	 * Add machine_id to machine list.
	 *
	 * @param string $machine_id namchine_id for the job
	 * @access public
	 * @return bool true if the file could be added; false on error
	 */
	function add_machine_id($machine_id) {
		if (!$machine_id) return false;
		if (!($stmt = get_pdo()->prepare('SELECT * FROM machine WHERE machine_id = :machine_id'))) {
			return null;
		}
		$stmt->bindParam(':machine_id', $machine_id);
		$stmt->execute();
		$row = $stmt->fetch(PDO::FETCH_ASSOC);
		if (!$row) return null;
		$this->fields['machines_ip'][] = $row['ip'];
		$this->fields['machines'][$machine_id] = $row;
	}


	/**
	 * Get hostname by machine_id 
	 * @param string $machine_id
	 * @access public
	 * @return string host name , false on error
	*/

	function get_hostname_by_id($machine_id) {
		if( isset($this->fields['machines'][$machine_id]) ) return $this->fields['machines'][$machine_id]['name'];
		return null;
	}


	/**
	 * Get hostname by machine_id 
	 * @param string $machine_id
	 * @access public
	 * @return string host name , false on error
	*/

	function has_perm($machine_id,$perm) {
		if(isset($this->fields['machines'][$machine_id])) {
			if(preg_match("/$perm/i", $this->fields['machines'][$machine_id]['perm']))
				return true;
		}
		return null;
	}


	/**
	*
	*static function set_email($email)
	*static function set_motd($motd)
	*static function set_job_type($motd)
	*
	*static function mm_set_role_number()
	*static function mm_set_role_machine('role_number','machine_id')
	*static function mm_set_role_raw('role_number','command row strem')
	*
	*
	*
	*/


	private static function get_master_socket() {
		if (is_null(Job::$master_socket)) {
			$conf = ConfigFactory::build();
			if (!(Job::$master_socket = fsockopen($conf->cmdline->host, $conf->cmdline->port))) {
				return false;
			}
			stream_set_blocking(Job::$master_socket, false);
		
			$count = 0;
			while (($s = fgets(Job::$master_socket, 4096)) != "$>") {
				if (!$s) {
					if (($count++) > 10) {
						fclose(Job::$master_socket);
						Job::$master_socket = null;
						Job::$readerr = "Could not get the master command prompt. Giving up after 10 empty reads from master.";
						return null;
					}
					sleep(1);
					continue;
				}
			}
		}

		return Job::$master_socket;
	}


	/**
	 * send_job 
	 *
	 * Sends a job to the machine by the HAMSTA master commandline interface
	 * 
	 * @param string $filename Filename of the XML job description on the 
	 *	  master. This is not a local filename!
	 *
	 * @access public
	 * @return bool true if the job could be send; false on error
	 */
	function send_job() {
		if (!($sock = Job::get_master_socket())) {
			$this->errmsg = (empty(Job::$readerr)?"cannot connect to master!":Job::$readerr);
			return false;
		}


		global $config;
		if ($config->authentication->use) {
			$user = User::getById (User::getIdent (), $config);
			fputs ($sock, "log in " . $user->getLogin() . " "
			       . $user->getPassword() . "\n");
			$response = "";
			while (($s = fgets($sock, 4096)) != "$>") {
				$response .= $s;
			}

			if (!stristr ($response, "you were authenticated")) {
				$this->errmsg = $response;
				if (stristr ($response, 'not enough parameters')) {
					$this->errmsg = 'Could not authenticate to backend.'
						. ' Check you have your Hamsta master password set.';
				}
				return false;
			}
		}


		$response = "";
		if (isset($this->fields['machines_ip']) and isset($this->fields['filenames']) ) {
			foreach ($this->fields['filenames'] as $job_xml) {
				$machine_group = implode(',',$this->fields['machines_ip']);
				fputs($sock, "send job ip $machine_group $job_xml\n");
				while (($s = fgets($sock, 4096)) != "$>") {
					$response .= $s;
				}
				if (!stristr($response, "job send to scheduler")) {
					$this->errmsg = "$machine_group was unable to send job $job_xml: $response";
					$this->fields['fail_job'][] = "$job_xml"; 
					return false;
				}
				$this->fields['success_job'][] = "$job_xml"; 
			}	
		}else {
		return false;
		}
		return true;
	}

}
