<?php
/* ****************************************************************************
  Copyright (c) 2011 Unpublished Work of SUSE. All Rights Reserved.
  
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

define ("MS_UP", 1);
define ("MS_DOWN", 2);
define ("MS_NOT_RESPONDING", 5);
define ("MS_UNKNOWN", 6);

/**
 * Machine 
 *
 * Represents a single machine
 * 
 * @version $Rev: 1841 $
 * @author Kevin Wolf <kwolf@suse.de> 
 */
class Machine {

	/**
	 * fields 
	 * 
	 * @var array Associative array containing the values of all database 
	 *	  fields of this machine
	 */
	private $fields;

	/**
	 * master_socket 
	 * 
	 * @var resource Socket to the master command line interface
	 */
	private static $master_socket = null;

	
	/**
	 * errmsg 
	 * 
	 * @var string Error message returned by the master
	 */
	public $errmsg = "";

	/**
	 * readerr 
	 * 
	 * static @var string Error message returned by the master
	 */
	private static $readerr = "";

	/**
	 * children
	 *
	 * @var array containing the machines which are running on this machine.
	 * 
	 * This is null if the machine is not Virtualization Host (role VH)
	 *
	 * If the machine is VH, this variable is filled by the first call 
	 * function get_children.
	 */
	private $children = null;

	/**
	 * __construct 
	 *
	 * Creates a new instance of Machine. The constructor is meant to be called 
	 * only by functions that directly access the database and have to get an
	 * object from their query result.
	 * 
	 * @param array $fields Values of all database fields
	 */
	function __construct($fields) {
		$this->fields = $fields;
		$this->fields['id'] = $this->fields['machine_id'];
	}

	/**
	 * get_by_hostname 
	 * 
	 * @param string $hostname Hostname of the machine to get
	 * @access public
	 * @return Machine Machine with the given hostname
	 *	  or null if no matching machine is found
	 */
	static function get_by_hostname($hostname) {
		if (!($stmt = get_pdo()->prepare('SELECT * FROM machine WHERE name = :hostname'))) {
			return null;
		}
		$stmt->bindParam(':hostname', $hostname);

		$stmt->execute();
		$row = $stmt->fetch(PDO::FETCH_ASSOC);

		return $row ? new Machine($row) : null;
	}
	
	/**
	 * get_by_id 
	 * 
	 * @param int $id Database ID of the machine
	 * @access public
	 * @return Machine Machine with the given database ID
	 *	  or null if no matching machine is found
	 */
	static function get_by_id($id) {
		if (!($stmt = get_pdo()->prepare('SELECT * FROM machine WHERE machine_id = :id'))) {
			return null;
		}
		$stmt->bindParam(':id', $id);

		$stmt->execute();
		$row = $stmt->fetch(PDO::FETCH_ASSOC);

		return $row ? new Machine($row) : null;
	}

	/**
	 * get_by_ip
	 * 
	 * @param int $ip Database IP of the machine
	 * @access public
	 * @return Machine Machine with the given database IP
	 *	  or null if no matching machine is found
	 */
	static function get_by_ip($ip) {
		if (!($stmt = get_pdo()->prepare('SELECT * FROM machine WHERE ip = :ip'))) {
			return null;
		}
		$stmt->bindParam(':ip', $ip);

		$stmt->execute();
		$row = $stmt->fetch(PDO::FETCH_ASSOC);

		return $row ? new Machine($row) : null;
	}

	/**
	 * get_id 
	 * 
	 * @access public
	 * @return int Database ID of the machine
	 */
	function get_id() {
		if( isset($this->fields["id"]) )
			return $this->fields["id"];
		else
			return NULL;
	
	}

	/**
	 * get_hostname 
	 * 
	 * @access public
	 * @return string Hostname of the machine
	 */
	function get_hostname() {
		if( isset($this->fields["name"]) )
			return $this->fields["name"];
		else
			return NULL;
	}

	/**
	 * get_ip_address 
	 * 
	 * @access public
	 * @return string IP address of the machine
	 */
	function get_ip_address() {
		if( isset($this->fields["ip"]) )
			return $this->fields["ip"];
		else
			return NULL;
	}

    /**
     * get_group 
     * 
     * @access public
     * @return string machines' group name
     */
    function get_group() {
    	if( isset($this->fields["id"]) ) {
			$stmt = get_pdo()->prepare('select .group.group from .group,group_machine where .group.group_id=group_machine.group_id and group_machine.machine_id=:machineid');
			$stmt->bindParam(':machineid', $this->fields["id"]);
			$stmt->execute();
        	return $stmt->fetchAll(); }
    	else
    		return NULL;
    }

	/**
	 * get_architecture 
	 *
	 * Note: This gets the *current* architecture of the machine (i.e. what it is currently installed to.
	 * To get the *real* (capable) architecture of a machine, use get_architecture_capable().
	 *
	 * @access public
	 * @return string Architecture of the machine, if no variable in
	 * @return ID Architecture of the machine, if $need_id variable in
	 */
	function get_architecture() {
	if( isset($this->fields["product_arch_id"]) )
	{
		$stmt = get_pdo()->prepare('SELECT arch FROM arch WHERE arch_id=:product_arch_id');
		$stmt->bindParam(':product_arch_id', $this->fields["product_arch_id"] );
		$stmt->execute();
		return $stmt->fetchColumn();
	}
		else
			return NULL;
	}

	/**
	 * get_architecture_capable
	 *
	 * Note: This gets the *real* architecture of the machine (i.e. what it is capable of), but not necessarily installed to.
	 * To get the *current* (installed) architecture of a machine, use get_architecture().
	 *
	 * @access public
	 * @return *real* string Architecture of the machine, if no parameter in
	 * @return *real* ID Architecture of the machine, if $need_id parameter in
	 */
	function get_architecture_capable() {
	if( isset($this->fields["arch_id"]) )
	{
		$stmt = get_pdo()->prepare('SELECT arch FROM arch WHERE arch_id=:arch_id');
		$stmt->bindParam(':arch_id', $this->fields["arch_id"] );
		$stmt->execute();
		return $stmt->fetchColumn();
	}
		else
			return NULL;
	}

	/**
	 * get_hwelement
	 * 
	 * @access public
	 * @return latest hardware element values of this machine
	 */
	function get_hwelement($module_name, $element_name) {
		if (!($stmt = get_pdo()->prepare('select max(config_id) from config,machine where machine.machine_id=:machineid and machine.machine_id=config.machine_id'))) {
			return null;
		}
		$stmt->bindParam(':machineid', $this->fields["id"]);
		$stmt->execute();
		$config_id = $stmt->fetchColumn();
		if (!($stmt2 = get_pdo()->prepare('select module.module_id from module,config_module,module_name where module_name.module_name=:modulename and config_module.config_id=:configid and module.module_id=config_module.module_id and module_name.module_name_id=module.module_name_id'))) {
			return null;
		}
		$stmt2->bindParam(':modulename', $module_name);
		$stmt2->bindParam(':configid', $config_id);
		$stmt2->execute();
		$module_id = $stmt2->fetchColumn();
		if (!($stmt3 = get_pdo()->prepare('select value from module_part where module_id=:moduleid and element=:elementname'))) {
			return null;
		}
		$stmt3->bindParam(':moduleid', $module_id);
		$stmt3->bindParam(':elementname', $element_name);
		$stmt3->execute();
		$ret = $stmt3->fetchColumn();
		while ($row = $stmt3->fetchColumn())
			{ $ret .= "\n".$row; }
		return $ret;
	}

	/**
	 * Call get_hwelement to query hardware elements values. Include get_cpu_model, get_momery_size, get_disk_model, get_partions etc.
	 * 
	  *@access public
	 * @return latest hardware element info value of this machine
	 */
	function get_cpu_numbers() {
		return( isset($this->fields['cpu_nr']) ? $this->fields['cpu_nr'] : NULL );
	}
	function get_memory_size() {
		return( isset($this->fields['memsize']) ? $this->fields['memsize'] : NULL );
	}
	function get_disk_size() {
		return( isset($this->fields['disksize']) ? $this->fields['disksize'] : NULL );
	}
	function get_cpu_vendor() {
		if( !isset($this->fields['cpu_vendor_id']) )
			return NULL;
		if( !($stmt = get_pdo()->prepare('SELECT cpu_vendor FROM cpu_vendor WHERE cpu_vendor_id=:id')) )
			return NULL;
		$stmt->bindParam(':id',$this->fields['cpu_vendor_id']);
		$stmt->execute();
		return $stmt->fetchColumn();
	}
	function get_vmusedmemory() {
		$memory = $this->get_hwelement("vmusedmemory", "VMUsedMemory");
		return $memory;
	}
	function get_avaivmdisk() {
		$avaivmdisk = $this->get_hwelement("avaivmdisk","AvaiVMDisk");
		return $avaivmdisk;
	}

	/**
	 * get_devel_tools()
	 *
	 * @access public
	 * @return int(bool) indicating whether client is running devel tools.
	 */
	function get_devel_tools() {
		$devel_tools = $this->get_hwelement("devel_tools", "DevelTools");
		return $devel_tools;
	}

	/*
	 * get_rpm_list()
	 *
	 * @access public
	 * @return string list of client installed packages.
	 */
	function get_rpm_list() {
		$stmt = get_pdo()->prepare('SELECT rpm_list FROM machine WHERE machine_id = :id');
		$stmt->bindParam(':id',$this->fields['machine_id']);
		$stmt->execute();
		return $stmt->fetchColumn();
	}

	/**
	 * get_tools_out_of_date
	 *
	 * @access public
	 * @return array containing list of outdated packages.
	 * @return bool false if no packages were outdated.
	 */
	function get_tools_out_of_date() {
		$rpm_str = $this->get_rpm_list();
		if (!$rpm_str) {
                        return array('qa_hamsta 2.2.0');
                }
		$rpm_list = array();
		foreach (explode("\n", $rpm_str) as $rpm) {
			$rpm_vals = explode(" ", $rpm);
			if (sizeof($rpm_vals) == 2) {
				$rpm_list[$rpm_vals[0]] = $rpm_vals[1];
			}
		}
		
		$old_packages = array();
		$tools_packages = array("qa_hamsta", "qa_hamsta-cmdline", "qa_hamsta-common", "qa_tools", "qa_lib_perl", "qa_lib_ctcs2", "qa_lib_config", "qa_lib_keys");
		$versions = array();
		foreach (array_unique($GLOBALS['packageVersions']) as $package) {
			$package_data = explode(" ", $package);
			if (sizeof($package_data) == 2) {
				$key = $package_data[0];
				$val = $package_data[1];
				if (in_array($key, $tools_packages)) {
					if (!array_key_exists($key, $versions)) {
						$versions[$key] = $val;
					} else {
						$current_version = explode(".", substr($versions[$key], strpos($versions[$key], "-")+1));
						$suggested_version = explode(".", substr($val, strpos($val, "-")+1));
						if ($this->check_newer_version($current_version, $suggested_version)) {
							$versions[$key] = $val;
						}
					}
				}
			}
		}
		foreach ($versions as $key => $val) {
			if (array_key_exists($key, $rpm_list)) {
				$server_core_version = explode(".", substr($val, 0, strpos($val, "-")));
				$server_sub_version = explode(".", substr($val, strpos($val, "-")+1));
				$client_core_version = explode(".", substr($rpm_list[$key], 0, strpos($rpm_list[$key], "-")));
				$client_sub_version = explode(".", substr($rpm_list[$key], strpos($rpm_list[$key], "-")+1));
				if ($this->check_newer_version($client_core_version, $server_core_version) ||
					($server_core_version == $client_core_version && $this->check_newer_version($client_sub_version, $server_sub_version))) {
					$old_packages[] = $key.' '.$rpm_list[$key];
				}
			}
		}

		if ($old_packages)
			return $old_packages;
		else
			return false;
	}

	/**
	 * check_newer_version 
	 * 
	 * @access public
	 * @param array() the old version to compare
	 * @param array() the new version to compare
	 * @return The newer version of the two arguments.
	 */
	function check_newer_version($old, $new) {
		if ($old[0] < $new[0]) {
			return 1;
		} else if ($old[0] == $new[0] && $old[1] < $new[1]) {
			return 1;
		} else if (array_key_exists(2, $old) &&
			array_key_exists(2, $new) &&
			$old[0] == $new[0] &&
			$old[1] == $new[1] &&
			$old[2] < $new[2]) {
			return 1;
		}
		return 0;
	}

	/**
	 * get_last_used 
	 * 
	 * @access public
	 * @return string Date string as returned by the database indicating 
	 *	  the last usage of the machine
	 */
	function get_last_used() {
	if( isset($this->fields["last_used"]) )
		return $this->fields["last_used"];
	else
		return NULL;
	}
	
	/**
	 * get_unique_id 
	 * 
	 * @access public
	 * @return string Unique ID if the machine
	 */
	function get_unique_id() {
	if( isset($this->fields["unique_id"]) )
			return $this->fields["unique_id"];
		else
			return NULL;
	}
 
	/**
	 * get_powerswitch 
	 * 
	 * @access public
	 * @return string Unique ID if the machine
	 */
	function get_powerswitch() {
	if( isset($this->fields["powerswitch"]) )
			return $this->fields["powerswitch"];
		else
			return NULL;
	}
	
	/**
	 * set_powerswitch 
	 *
	 * Sets the powerswitch description of the machine
	 * 
	 * @param string $powerswitch has the configuration of the connected powerwitch
	 * @access public
	 * @return void
	 */
	function set_powerswitch($powerswitch)  {
		$stmt = get_pdo()->prepare('UPDATE machine SET powerswitch = :powerswitch WHERE machine_id = :id');
		$stmt->bindParam(':id', $this->fields["id"]);
		$stmt->bindParam(':powerswitch', $powerswitch);
		$stmt->execute();
	}
        /**
         * get_powertype
         *
         * @access public
         * @return string Unique ID if the machine
         */
        function get_powertype() {
        if( isset($this->fields['powertype']) )
                        return $this->fields["powertype"];
                else
                        return NULL;
        }

        /**
         * set_powertype
         *
         * Sets the powertype description of the machine
         * 
         * @param string $powertype has the configuration of the connected powerswitch
         * @access public
         * @return void
         */
        function set_powertype($powertype)  {
                if (($powertype == 's390') or ($powertype == 'apc') or ($powertype == NULL)) {
			$stmt = get_pdo()->prepare('UPDATE machine SET powertype = :powertype WHERE machine_id = :id');
        	        $stmt->bindParam(':id', $this->fields["id"]);
	                $stmt->bindParam(':powertype', $powertype);
                	$stmt->execute();
		}
		else
			return NULL;
        }

        /**
         * get_powerslot
         *
         * @access public
         * @return string Unique ID if the machine
         */
        function get_powerslot() {
        if( isset($this->fields['powerslot']) )
                        return $this->fields["powerslot"];
                else
                        return NULL;
        }

        /**
         * set_powerslot
         *
         * Sets the powerslot description of the machine
         * 
         * @param string $powerslot has the slot of the connected powerswitch
         * @access public
         * @return void
         */
        function set_powerslot($powerslot)  {
                $stmt = get_pdo()->prepare('UPDATE machine SET powerslot = :powerslot WHERE machine_id = :id');
                $stmt->bindParam(':id', $this->fields["id"]);
                $stmt->bindParam(':powerslot', $powerslot);
                $stmt->execute();
        }

        /**
         * start_machine
         *
         * @acces public
         * @return void
         *
         */
        function start_machine()  {
                $powerswitch = $this->get_powerswitch();
		$powertype = $this->get_powertype();
                $powerslot = $this->get_powerslot();
                if ($powertype == "s390")
                        power_s390($powerslot, "start");
		else if ($powertype == "apc")
			power_apc($powerswitch, $powerslot, 'start');
        }

        /**
         * stop_machine
         *
         * @acces public
         * @return void
         *
         */
        function stop_machine()  {
		$powerswitch = $this->get_powerswitch();
                $powertype= $this->get_powertype();
                $powerslot= $this->get_powerslot();
                if ($powertype == "s390")
                        power_s390($powerslot, 'stop');
		else if ($powertype == "apc")
			power_apc($powerswitch, $powerslot, 'stop');
        }

        /**
         * restart_machine
         *
         * @acces public
         * @return void
         *
         */
        function restart_machine()  {
		$powerswitch = $this->get_powerswitch();
                $powertype= $this->get_powertype();
                $powerslot= $this->get_powerslot();
                if ($powertype == "s390")
                        power_s390($powerslot, 'restart');
		else if ($powertype == "apc")
			power_apc($powerswitch, $powerslot, 'restart');
        }


	/**
	 * get_serialconsole 
	 * 
	 * @access public
	 * @return string Unique ID if the machine
	 */
	function get_serialconsole() {
	if( isset($this->fields["serialconsole"]) )
			return $this->fields["serialconsole"];
		else
			return NULL;
	}
	
	/**
	 * set_serialconsole 
	 *
	 * Sets the serialconsole description of the machine
	 * 
	 * @param string $serialconsole has the configuration of the connected serialswitch (for remote control)
	 * @access public
	 * @return void
	 */
	function set_serialconsole($serialconsole)  {
		$stmt = get_pdo()->prepare('UPDATE machine SET serialconsole = :serialconsole WHERE machine_id = :id');
		$stmt->bindParam(':id', $this->fields["id"]);
		$stmt->bindParam(':serialconsole', $serialconsole);
		$stmt->execute();
	}

	/** Add by csxia
	*/
	/**
	 * get_consoledevice
	 * 
	 * @access public
	 * @return string Unique ID if the machine
	 */
	function get_consoledevice() {
	if( isset($this->fields["consoledevice"]) )
			return $this->fields["consoledevice"];
		else
			return NULL;
	}

	/**
	 * set_consoledevice 
	 *
	 * Sets the serialdevice
	 * 
	 * @param string $consoledevice is device name of console point e.g ttyS0 
	 * @access public
	 * @return void
	 */
	function set_consoledevice($consoledevice)  {
		$stmt = get_pdo()->prepare('UPDATE machine SET consoledevice = :consoledevice WHERE machine_id = :id');
		$stmt->bindParam(':id', $this->fields["id"]);
		$stmt->bindParam(':consoledevice', $consoledevice);
		$stmt->execute();
	}

	/**
	 * get_consolespeed
	 * 
	 * @access public
	 * @return int speed of console device
	 */
	function get_consolespeed() {
	if( isset($this->fields["consolespeed"]) )
			return $this->fields["consolespeed"];
		else
			return NULL;
	}

	/**
	 * set_consolespeed 
	 *
	 * Sets the	consolespeed 
	 * 
	 * @param string $consolespeed is device speed of serail console 
	 * @access public
	 * @return void
	 */
	function set_consolespeed($consolespeed)  {
		$stmt = get_pdo()->prepare('UPDATE machine SET consolespeed = :consolespeed WHERE machine_id = :id');
		$stmt->bindParam(':id', $this->fields["id"]);
		$stmt->bindParam(':consolespeed', $consolespeed);
		$stmt->execute();
	}


	/**
	 * get_consolesetdefault
	 * 
	 * @access public
	 * @return int whether this lable set
	 */
	function get_consolesetdefault() {
	if( isset($this->fields["consolesetdefault"]) )
			return $this->fields["consolesetdefault"];
		else
			return NULL;
	}

	/**
	 * set_consolesetdefault
	 *
	 * Sets the serail console at reinstallation
	 * 
	 * @param int 
	 *		0 disable console direction
	 *		  1 enable console direction 
	 * @access public
	 * @return void
	 */
	function set_consolesetdefault ($consolesetdefault)  {
		$consolesetdefault ? $consolesetdefault = 1 : $consolesetdefault = 0;
		$stmt = get_pdo()->prepare('UPDATE machine SET consolesetdefault = :consolesetdefault WHERE machine_id = :id');
		$stmt->bindParam(':id', $this->fields["id"]);
		$stmt->bindParam(':consolesetdefault', $consolesetdefault);
		$stmt->execute();
	}
	

	/**
	 * get_def_inst_opt
	 * 
	 * @access public
	 * @return the default installation option per machine
	 */
	function get_def_inst_opt() {
	if( isset($this->fields["default_option"]) )
			return $this->fields["default_option"];
		else
			return NULL;
	}

	/**
	 *	set_def_inst_opt 
	 *
	 * Sets the default installation option 
	 * 
	 * @param  string default installation option
	 * @access public
	 * @return void
	 */
	function set_def_inst_opt($default_option)  {
		$stmt = get_pdo()->prepare('UPDATE machine SET default_option = :default_option WHERE machine_id = :id');
		$stmt->bindParam(':id', $this->fields["id"]);
		$stmt->bindParam(':default_option', $default_option);
		$stmt->execute();
	}
	//end added 

	/**
	 * get_status_string 
	 * 
	 * @access public
	 * @return string Name of the current status of the machine
	 */
	function get_status_string() {
		$stmt = get_pdo()->prepare('SELECT machine_status FROM machine_status WHERE machine_status_id = :status_id');
		$stmt->bindParam(':status_id', $this->fields["machine_status_id"]);
		$stmt->execute();
		$mstatus = $stmt->fetchColumn();
		if($this->is_busy()) {
			$mstatus .= "/ job running";
		}
		return $mstatus;
	}
	
	/**
	 * get_previous_jobs 
	 * 
	 * @access public
	 * @return string xml_file and short_name of the last ran jobs
	 */
	function get_previous_jobs() {
		$stmt = get_pdo()->prepare('select xml_file, short_name from job JOIN job_on_machine USING(job_id) JOIN machine USING(machine_id) WHERE machine.name = :name order by job_on_machine.job_id desc limit 3;');
		$stmt->bindParam(':name', $this->fields["name"]);
		
		$stmt->execute();
		return $stmt->fetchAll(PDO::FETCH_COLUMN, 0);
	}

	/**
	 * get_status_id 
	 * 
	 * @access public
	 * @return int ID of the current status of the machine
	 */
	function get_status_id() {
	if( isset($this->fields["machine_status_id"]) )
			return $this->fields["machine_status_id"];
		else
			return NULL;
	}

	/**
	 * set_status_id
	 *
	 * Sets the status of the machine
	 * 
	 * @param int $status_id ID of the new status
	 * @access public
	 * @return void
	 */
	function set_status_id($status_id) {
		$stmt = get_pdo()->prepare('UPDATE machine SET machine_status_id = :status_id WHERE machine_id = :id');
		$stmt->bindParam(':id', $this->fields["id"]);
		$stmt->bindParam(':status_id', $status_id);
		$stmt->execute();
	}
	
	
	/**
	 * get_maintainer_string 
	 * 
	 * @access public
	 * @return string
	 * @todo Return the name of the maintainer instead of the ID
	 */
	function get_maintainer_string() {
		if (!empty($this->fields["maintainer_id"])) {
			return $this->fields["maintainer_id"];
		} else {
			return NULL;
		}
	}

	/**
	 * set_maintainer_id 
	 *
	 * Sets the maintainer of the machine
	 * 
	 * @param mixed $maintainer ID of the new maintainer
	 * @access public
	 * @return void
	 */
	function set_maintainer_string($maintainer)  {
		$stmt = get_pdo()->prepare('UPDATE machine SET maintainer_id = :maintainer WHERE machine_id = :id');
		$stmt->bindParam(':id', $this->fields["id"]);
		$stmt->bindParam(':maintainer', $maintainer);
		$stmt->execute();
	}
	
	/**
	 * get_used_by 
	 * 
	 * @access public
	 * @return string Login for which the machine is reserved 
	 */
	function get_used_by() {
		if( isset($this->fields["usedby"]) )
			return $this->fields["usedby"];
		else
			return NULL;
	}

	function get_used_by_name() {
		if ($used_by = User::get_by_openid($this->get_used_by()))
			return $used_by->get_name();
		else
			return NULL;
	}
	
	/**
	 * set_used_by 
	 *
	 * Marks a machine as reserved for a user
	 * 
	 * @param string $user Login of the user to reserve the machine for
	 * @access public
	 * @return void
	 */
	function set_used_by($user) {
		$this->fields["usedby"] = $user;
		$stmt = get_pdo()->prepare('UPDATE machine SET usedby = :used_by WHERE machine_id = :id');
		$stmt->bindParam(':id', $this->fields["id"]);
		$stmt->bindParam(':used_by', $this->fields["usedby"]);
		$stmt->execute();
	}
	
	/**
	 * get_usage
	 * 
	 * @access public
	 * @return string Usage of the machine
	 */
	function get_usage() {
	if( isset($this->fields["usage"]) )
			return $this->fields["usage"];
		else
			return NULL;
	}
	
	/**
	 * set_usage 
	 *
	 * @param string $usage Usage of the machine
	 * @access public
	 * @return void
	 */
	function set_usage($usage) {
		$stmt = get_pdo()->prepare('UPDATE machine SET `usage` = :usage WHERE machine_id = :id');
		$stmt->bindParam(':id', $this->fields["id"]);
		$stmt->bindParam(':usage', $usage);
		$stmt->execute();
	}

	/**
	 * get_expires
	 *
	 * @access public
	 * @return string Expires date and release the machine if it's reservation has expired.
	 */
	function get_expires() {
		if( isset($this->fields["expires"]) ) {
			$expires = strtotime($this->fields["expires"]);
			$today = time();
			$remaining = $expires - $today;
			if ($remaining > 0) {
				$days = $remaining/86400;
				if ($days > 1)
					return round($days);
				else
					return ceil($days);
			} else if ($remaining < 0 && $expires > 0) { #Check if remaining is negative, then expired, but if expires is also negative, then error.
				$this->set_used_by('');
				$this->set_usage('');
				$this->set_expires(NULL);
				$this->set_reserved(NULL);
				return NULL;
			} else {
				return NULL;
			}
		} else {
			return NULL;
		}
	}

	/**
	 * get_expires
	 *
	 * @access public
	 * @return string Expires date formated.
	 */
	function get_expires_formated() {
		$days = $this->get_expires();
		if ($days != NULL)
			return $days.' days';
		else
			return NULL;
	}


	/**
	 * set_expires
	 *
	 * @param string $expires Expiration date of the machine reservation.
	 * @access public
	 * @return void
	 */
	function set_expires($days) {
		if ($days != 0 && is_numeric($days)) {
			$this->set_reserved(date('Y/m/d H:i:s'));
			$days_sql = 'DATE_ADD(NOW(), INTERVAL :days DAY)';
		} else {
			$days = NULL;
			$days_sql = ':days';
		}
		$stmt = get_pdo()->prepare('UPDATE machine SET `expires` = '.$days_sql.' WHERE machine_id = :id');
		$stmt->bindParam(':id', $this->fields["id"]);
		$stmt->bindParam(':days', $days);
		$stmt->execute();
	}
	
	/**
	 * get_reserved
	 *
	 * @access public
	 * @return string Reserved date.
	 */
	function get_reserved() {
		if( isset($this->fields["reserved"]) ) {
			$date = date('Y/m/d H:i:s', strtotime($this->fields["reserved"]));
			return date('Y/m/d', strtotime($date));
		} else {
			return NULL;
		}
	}

	/**
	 * set_reserved
	 *
	 * @param string $reserved Reservation date of the machine reservation.
	 * @access public
	 * @return void
	 */
	function set_reserved($reserved) {
		$stmt = get_pdo()->prepare('UPDATE machine SET `reserved` = :reserved WHERE machine_id = :id');
		$stmt->bindParam(':id', $this->fields["id"]);
		$stmt->bindParam(':reserved', $reserved);
		$stmt->execute();
	}

	/**
	 * get_product 
	 * 
	 * @access public
	 * @return string Product that the machine is running
	 */
	function get_product() {
		$stmt = get_pdo()->prepare('SELECT product FROM product WHERE product_id=:product_id');
		$stmt->bindParam(':product_id',$this->fields['product_id']);
		$stmt->execute();
		return $stmt->fetchColumn();
/*
		$product = $this->fields["description"];
		
		$product = str_replace("SUSE", ";SUSE", $product);
		$product = str_replace("open;SUSE", ";openSUSE", $product);
		$product = str_replace(";SUSELinuxEnterpriseServer", ";SLES", $product);
		$product = str_replace(";SUSELinuxEnterpriseDesktop", ";SLED", $product);
	$product = str_replace("SLESforSAPApplications", ";SLES4SAP", $product);
	
	// make product shorter for displaying
	if (ereg("BRANCH",$product, $erg)) {
		//echo "here: $product <br>";
		$arr = array();
		$arr = preg_split("/;/",$product);
		//print_r($arr);
		return  nl2br($arr[0]);
	}
		if (ereg("^([A-Za-z0-9.\-]+);([A-Za-z0-9.]+)(\(([A-Za-z0-9_\-]+)\))?VERSION=", $product, $reg)) {
			ereg("PATCHLEVEL=([0-9]+)", $product, $sp);
			$sp[0] = str_replace("PATCHLEVEL=", "SP",$sp[0]);
			if( $sp[0] )
				$reg[2]=ereg_replace('\.[0-9]+',"",$reg[2]);
			ereg("Beta([0-9]+)", $product, $beta);
			ereg("Dom([A-Z0-9]+)", $product, $dom);
			ereg("Build([0-9]+)", $product, $build);
			return $reg[2]." (".$reg[4].") $sp[0] $dom[0] $beta[0] $build[0]";
		}

		return nl2br($product);
		//return nl2br($this->fields["description"]);*/
	}
	
	/**
	 * get_kernel 
	 * 
	 * @access public
	 * @return string Kernel version the machine is running
	 */
	function get_kernel() {
		if( isset($this->fields['kernel']) )
			return $this->fields['kernel'];
		else
			return NULL;
/*			
		$product = $this->fields["description"];
		
		$product = str_replace("SUSE", ";SUSE", $product);
		$product = str_replace("open;SUSE", ";openSUSE", $product);
		$product = str_replace(";SUSELinuxEnterpriseServer", ";SLES", $product);
		$product = str_replace(";SUSELinuxEnterpriseDesktop", ";SLED", $product);
	$product = str_replace("SLESforSAPApplications", ";SLES4SAP", $product);

		if (ereg("^([A-Za-z0-9.\-]+);([A-Za-z0-9.]+)(\(([A-Za-z0-9_\-]+)\))?VERSION=", $product, $reg)) {
			return $reg[1];
		}
		return "see product";
*/
	}

	
	/**
	 * get_affiliation 
	 * 
	 * @access public
	 * @return string Affiliation of the machine
	 */
	function get_affiliation() {
	if( isset($this->fields["affiliation"]) )
			return $this->fields["affiliation"];
		else
			return NULL;
	}
	
	/**
	 * set_affiliation 
	 *
	 * Sets the affiliation of the machine
	 * 
	 * @param string $affiliation Description of the affiliation
	 * @access public
	 * @return void
	 */
	function set_affiliation($affiliation)  {
		$stmt = get_pdo()->prepare('UPDATE machine SET affiliation = :affiliation WHERE machine_id = :id');
		$stmt->bindParam(':id', $this->fields["id"]);
		$stmt->bindParam(':affiliation', $affiliation);
		$stmt->execute();
	}

	/**
	 * get_anomaly 
	 * 
	 * @access public
	 * @return string Description of the anomalies of the machine
	 */
	function get_anomaly() {
	if( isset($this->fields["anomaly"]) )
			return $this->fields["anomaly"];
		else
			return NULL;
	}
	
	/**
	 * set_anomaly 
	 *
	 * Sets the anomalies description of the machine
	 * 
	 * @param string $anomaly Description of the anomalies
	 * @access public
	 * @return void
	 */
	function set_anomaly($anomaly)  {
		$stmt = get_pdo()->prepare('UPDATE machine SET anomaly = :anomaly WHERE machine_id = :id');
		$stmt->bindParam(':id', $this->fields["id"]);
		$stmt->bindParam(':anomaly', $anomaly);
		$stmt->execute();
	}

	/**
	 * get_notes 
	 * 
	 * @access public
	 * @return string Notes for the machine (consisting of affiliation and anomalies, if any)
	 */
	function get_notes() {
	$anomaly=$this->get_anomaly();
		return $this->get_affiliation() . ($anomaly ? ".&#10;&#10;ANOMALIES: " . $anomaly : "");
	}

	/**
	 * is_busy 
	 * 
	 * @access public
	 * @return boolean true if a job is currently running on the machine; false otherwise 
	 */
	function is_busy() {
		$stmt = get_pdo()->prepare('SELECT busy FROM machine WHERE machine_id = :id');
		$stmt->bindParam(':id', $this->fields["id"]);
		$stmt->execute();
		
		$busy = $stmt->fetchColumn();
		$stmt->closeCursor();
		return $busy;
	}

	function get_busy()	{
		return is_busy();
	}
	
	/**
	 * set_busy
	 *
	 * Sets the busy flag of the machine
	 * 
	 * @param int $busy 0 for free, 1 for job running.
	 * @access public
	 * @return void
	 */
	function set_busy($busy)  {
		$stmt = get_pdo()->prepare('UPDATE machine SET busy = :busy WHERE machine_id = :id');
		$stmt->bindParam(':id', $this->fields["id"]);
		$stmt->bindParam(':busy', $busy);
		$stmt->execute();
	}
	
	/**
	 * update_busy
	 *
	 * Updates the busy flag of the machine. If the busy flag is set to 2
	 * (manually blocked), the flag will not be changed. Otherwise it will be
	 * set to 1 if there are still jobs running or 0 if no more jobs are
	 * running on the machine.
	 * 
	 * @access public
	 * @return void
	 */
	function update_busy()  {

		if ($this->count_running_jobs()) {
			$this->set_busy(1);
		} else {
			$this->set_busy(0);
		}
	}

        /**
         * has_perm 
         * 
         * @access public
         * @return boolean true if a job is has perm_str on the machine; false otherwise 
         */
        function has_perm($perm_str) {
                $stmt = get_pdo()->prepare('SELECT FIND_IN_SET(:perm_str,perm) FROM machine WHERE machine_id = :id');
                $stmt->bindParam(':id', $this->fields["id"]);
                $stmt->bindParam(':perm_str', $perm_str);
                $stmt->execute();

                $perm = $stmt->fetchColumn();
                $stmt->closeCursor();
                return $perm;
        }

        /**
         * set_perm
         *
         * Sets the perm flag of the machine
         * 
         * @param str $perm_str : job,install,partition,boot
         * @access public
         * @return void
         */
        function set_perm($perm_str)  {
                $stmt = get_pdo()->prepare('UPDATE machine SET perm = :perm WHERE machine_id = :id');
                $stmt->bindParam(':id', $this->fields["id"]);
                $stmt->bindParam(':perm', $perm_str);
                $stmt->execute();
        }


	/**
	 * get_role 
	 * 
	 * @access public
	 * @return string Role of the machine
	 */
	function get_role() {
		if( isset($this->fields["role"]) )
			return $this->fields["role"];
		else
			return NULL;
	}

	/**
	 * get_type 
	 * 
	 * @access public
	 * @return string Type of the machine
	 */
	function get_type() {
		if( isset($this->fields["type"]) )
			return $this->fields["type"];
		else
			return NULL;
	}

	/**
	 * get_vh
	 * 
	 * @access public
	 * @return string VH (hostname or virtual host) of the machine (for VM only)
	 */
	function get_vh() {
		if( isset($this->fields["vh_id"]) )
			return Machine::get_by_id($this->fields["vh_id"])->get_hostname();
		else
			return NULL;
	}

	/**
	 * get_vh_id
	 * 
	 * @access public
	 * @return machine_id of VH of the machine (for VM only)
	 */
	function get_vh_id() {
		if( isset($this->fields["vh_id"]) )
			return $this->fields["vh_id"];
		else
			return NULL;
	}

	/**
	 * get_children
	 *
	 * @access public
	 * @return array of Machine objects which represents virtual machines 
	 *         running on this VH. If this machine is not VH, NULL is 
	 *         returned.
	 */
	function get_children() {
		if( ! $this->get_role() == "VH" )  
			return NULL;

		if ( !isset($this->children ) ) {
			$search = new MachineSearch();
			$search->filter_vh($this->get_id());
			$this->children = $search->query();
		}

		return $this->children;

	}

	/**
	 * get_current_configuration 
	 * 
	 * @access public
	 * @return Configuration The most recently used configuration for this machine
	 */
	function get_current_configuration() {
		$stmt = get_pdo()->prepare('SELECT * FROM config WHERE machine_id = :machine ORDER BY timestamp_last_active DESC LIMIT 1');
		$stmt->bindParam(':machine', $this->fields["id"]);
		$stmt->execute();
		
		$row = $stmt->fetch(PDO::FETCH_ASSOC);
		return $row ? new Configuration($row) : null;
	}

	function get_current_configuration_id() {
		$stmt = get_pdo()->prepare('SELECT config_id FROM config WHERE machine_id = :machine ORDER BY timestamp_last_active DESC LIMIT 1');
		$stmt->bindParam(':machine', $this->fields["id"]);
		$stmt->execute();
		
		$row = $stmt->fetch(PDO::FETCH_ASSOC);
		return $row ? $row["config_id"] : null;
	}
	
	function get_partition_bycid($cid) {
		$stmt = get_pdo()->prepare('SELECT mp.value FROM config_module AS c JOIN module_part AS mp ON c.module_id=mp.module_id JOIN module AS md ON md.module_id=mp.module_id JOIN module_name AS mn ON md.module_name_id=mn.module_name_id WHERE mn.module_name="system_partition" AND mp.element="pt_ns" AND  c.config_id= :cid');
		$stmt->bindParam(':cid',$cid);
		$stmt->execute();
		$row = $stmt->fetchall(PDO::FETCH_ASSOC);
		$ptarray = array();
		if($row) {
			foreach($row as $pt) {
				foreach($pt as $key => $value){
					$ptarray[]=$value;
				}
			}

			return $ptarray;

		}else {
			return null;
		}
		
	}	
	function get_swap_bycid($cid) {
		$stmt = get_pdo()->prepare('SELECT mp.value FROM config_module AS c JOIN module_part AS mp ON c.module_id=mp.module_id JOIN module AS md ON md.module_id=mp.module_id JOIN module_name AS mn ON md.module_name_id=mn.module_name_id WHERE mn.module_name="swap" AND mp.element="Partition_path" AND  c.config_id= :cid');
		$stmt->bindParam(':cid',$cid);
		$stmt->execute();
		$row = $stmt->fetch(PDO::FETCH_ASSOC);
		if($row) {

			return $row['value'];

		}else {
			return null;
		}
		
	}	

	/**
	 * get_configurations 
	 * 
	 * @access public
	 * @return array Array of all configurations ever attached to this machine
	 */
	function get_configurations() {
		$stmt = get_pdo()->prepare('SELECT * FROM config WHERE machine_id = :machine ORDER BY timestamp_last_active DESC');
		$stmt->bindParam(':machine', $this->fields["id"]);
		$stmt->execute();
		
		$result = array();
		while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
			$result[] = new Configuration($row);
		}

		return $result;
	}

	
	/**
	 * get_all_jobs 
	 *
	 * @param int $limit Optional. Maximal number of jobs to return.
	 * @param int $start Optional. Number of first row to be returned.
	 * @access public
	 * @return array Array of all jobs executed on this machine, including
	 *	  pending jobs
	 */
	function get_all_jobs($limit = 0, $start = 0) {
		$sql = 'SELECT * FROM job j LEFT JOIN job_on_machine k ON k.job_id = j.job_id WHERE machine_id = :machine_id ORDER BY j.job_status_id ASC, j.job_id DESC';
		if ($limit) {
			$sql .= ' LIMIT '.((int) $start).','.((int) $limit);
		}

		if (!($stmt = get_pdo()->prepare($sql))) {
			return null;
		}
		$stmt->bindParam(':machine_id', $this->fields["id"]);
		
		$stmt->execute();
		$result = array();
		while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
			$result[] = new JobRun($row);
		}

		return $result;
	}
	
	/**
	 * count_all_jobs 
	 * 
	 * @access public
	 * @return int Number of all jobs executed on this machine, including
	 *	  pending jobs
	 */
	function count_all_jobs() {
		$sql = 'SELECT COUNT(*) FROM job j LEFT JOIN job_on_machine k ON k.job_id = j.job_id WHERE machine_id = :machine_id ORDER BY j.job_id DESC';

		if (!($stmt = get_pdo()->prepare($sql))) {
			return null;
		}
		$stmt->bindParam(':machine_id', $this->fields["id"]);
		$stmt->execute();
		$result = $stmt->fetchColumn();
		$stmt->closeCursor();

		return $result;
	}
	
	/**
	 * count_running_jobs 
	 * 
	 * @access public
	 * @return int Number of all jobs currently running on this machine	 
	 */
	function count_running_jobs() {
		$sql = 'SELECT COUNT(*) FROM job j LEFT JOIN job_on_machine k ON k.job_id = j.job_id WHERE machine_id = :machine_id AND k.job_status_id = 2 ORDER BY j.job_id DESC';

		if (!($stmt = get_pdo()->prepare($sql))) {
			return null;
		}
		$stmt->bindParam(':machine_id', $this->fields["id"]);
		$stmt->execute();
		$result = $stmt->fetchColumn();
		$stmt->closeCursor();

		return $result;
	}
	
	/**
	 * get_jobs_by_active 
	 * 
	 * @param bool $active true if active machines should be searched, false if 
	 *	  inactive machines should be searched
	 * @param int $limit 
	 * @access public
	 * @return array Array of jobs that are currently (in)active
	 */
	function get_jobs_by_active($active, $limit = 0) {
		$sql = 'SELECT * FROM job j LEFT JOIN job_on_machine k ON k.job_id = j.job_id WHERE k.machine_id=:machine_id 
				AND '.($active ? '' : 'NOT ').'((stop IS NULL) OR (stop = "")) ORDER BY j.job_status_id ASC, j.job_id DESC';
		if ($limit) {
			$sql .= ' LIMIT '.((int) $limit);
		}

		if (!($stmt = get_pdo()->prepare($sql))) {
			echo "null";
			return null;
		}
		$stmt->bindParam(':machine_id', $this->fields["id"]);
		
		$stmt->execute();
		$result = array();
		while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
			$result[] = new JobRun($row);
		}

		return $result;
	}

	private static function get_master_socket() {
		if (is_null(Machine::$master_socket)) {
			if (!(Machine::$master_socket = fsockopen(CMDLINE_HOST, CMDLINE_PORT))) {
				return false;
			}
			stream_set_blocking(Machine::$master_socket, false);
		
			$count = 0;
			while (($s = fgets(Machine::$master_socket, 4096)) != "$>") {
				if (!$s) {
					if (($count++) > 3) {
						fclose(Machine::$master_socket);
						Machine::$master_socket = null;
						Machine::$readerr = "Giving up after 3 empty reads from master";
						return null;
					}
					sleep(1);
					continue;
				}
			}
		}

		return Machine::$master_socket;
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
	function send_job($filename) {
		if (!($sock = Machine::get_master_socket())) {
			$this->errmsg = (empty(Machine::$readerr)?"cannot connect to master!":Machine::$readerr);
			return false;
		}
		
		fputs($sock, "send job ip ".$this->get_ip_address()." ".$filename."\n");

		$response = "";
		while (($s = fgets($sock, 4096)) != "$>") {
			$response .= $s;
		}

		if (!stristr($response, "job send to scheduler")) {
			$this->errmsg = $response;
			return false;
		}
			
		return true;
	}


	/**
	 * get_architectures 
	 *
	 * Note: This gets the *current* architectures of the machines (i.e. what they are currently installed to).
	 * To get the *real* (capable) architecture of the machines, use get_architectures_capable().
	 *
	 * @return array (key=>val): All current (installed) architectures present in the database
	 */
	static public function get_architectures() {
		$stmt = get_pdo()->prepare('SELECT DISTINCT arch.arch, arch.arch_id FROM arch JOIN machine WHERE machine.product_arch_id = arch.arch_id ORDER BY arch');
		$stmt->execute();
		
		$result = array();
		while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
			$result[$row["arch_id"]] = $row["arch"];
		}

		return $result;
	}

	/**
	 * get_architectures_capable
	 *
	 * Note: This gets the *real* architectures of the machines (i.e. what they are capable of, but not necessarily installed to).
	 * To get the currently installed architectures of the machines, use get_architectures().
	 *
	 * @return array (key=>val): All real (capable) architectures present in the database
	 */
	static public function get_architectures_capable() {
		$stmt = get_pdo()->prepare('SELECT DISTINCT arch.arch, arch.arch_id FROM arch JOIN machine WHERE machine.arch_id = arch.arch_id ORDER BY arch');
		$stmt->execute();

		$result = array();
		while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
			$result[$row["arch_id"]] = $row["arch"];
		}

		return $result;
	}
	
	/**
	 * get_statuses 
	 * 
	 * @return array All possible statuses. The returned array is an 
	 *	  associative array using the status ID as key and its
	 *	  name as value.
	 */
	static public function get_statuses() {
		$stmt = get_pdo()->prepare('SELECT machine_status_id, machine_status FROM machine_status ORDER BY machine_status');
		$stmt->execute();
		
		$result = array();
		while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
			$result[$row["machine_status_id"]] = $row["machine_status"];
		}

		return $result;
	}

	/**
	 * del_machine
	 *
	 * Removes a machine from hamsta.
	 *
	 * @param Machine $machine Machine to remove from hamsta
	 *
	 * @return boolean true if the machine could be deleted, false if no
	 * machine has been deleted.
	 */
	public function del_machine() {
		$id = $this->get_id();
		# First, get rid of the data with machine_id in its table
        $sql1 = "DELETE FROM machine WHERE machine_id=$id;DELETE FROM group_machine WHERE machine_id=$id;DELETE FROM config WHERE machine_id=$id;DELETE FROM job_on_machine WHERE machine_id=$id";
		if(!($stmt = get_pdo()->prepare($sql1)))
			return null;
		$firstPassed = $stmt->execute();

		# Second, get rid of the data of other tables which related to the data deleted in First phrase
        $sql2 = "DELETE FROM config_module WHERE config_id NOT IN (SELECT config_id FROM config);DELETE FROM job WHERE job_id NOT IN (SELECT job_id FROM job_on_machine)";
		if(!($stmt = get_pdo()->prepare($sql2)))
			return null;
		$secondPassed = $stmt->execute();

        #Third, get rid of module information, make database slim. Delete records according to the change of config_module table
        $sql3 = "DELETE FROM module WHERE module_id NOT IN (SELECT module_id FROM config_module);DELETE FROM module_part WHERE module_id NOT IN (SELECT module_id FROM config_module)";
        if(!($stmt = get_pdo()->prepare($sql3)))
            return null;
        $thirdPassed = $stmt->execute();
		return $firstPassed and $secondPassed and $thirdPassed;
	}

	/**
	 * get_log_entries
	 *
	 * @param int $id Database ID of the machine
	 * @access public
	 * @return array Log array
	 */
	static function get_log_entries($id, $limit = 0) {

		$result = array();

		if (!($stmt = get_pdo()->prepare('SELECT * FROM log WHERE machine_id = :id AND job_on_machine_id IS NULL ORDER BY log_id DESC' . ((is_int($limit) and $limit != 0) ? " LIMIT $limit" : "")))) {
			return null;
		}

		$stmt->bindParam(':id', $id);
		$stmt->execute();

		while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
			$result[] = new Log($row);
		}

		return $result;
	}

	private static $related_tables = array('group_machine','log','job_on_machine','config');
	/**
	 * merge_other_machines
	 *
	 * Steals related information from other machine. The caller should delete the machine after.
	 *
	 * @param int $other_id machine_id of the other machine
	 *
	 * @access public
	 * @return bool true if the operation succeeded
	 */
	function merge_other_machine($other_id)	{
		$ret = true;
		foreach( self::$related_tables as $table )	{
			if( !($stmt = get_pdo()->prepare("UPDATE IGNORE $table SET machine_id=:new_id WHERE machine_id=:old_id")))	{
				continue;
			}
			$stmt->bindParam(':new_id',$this->fields['machine_id']);
			$stmt->bindParam(':old_id',$other_id);
			$ret = $ret && $stmt->execute();
		}
		return $ret;
	}


	/**
	 * _purge
	 * Purges one sort of the related records - hwinfo history, logs, jobs, or groups.
	 *
	 * @param string $table (group_machine|log|job_on_machine|config)
	 * @access protected
	 * @return bool true if succeeded
	 */
	protected function _purge($table)	{
		if( !array_search($table,self::$related_tables) )
			return false;
		if( !($stmt = get_pdo()->prepare("DELETE FROM `$table` WHERE machine_id=:id")) )
			return false;
		$stmt->bindParam(':id',$this->fields['machine_id']);
		return $stmt->execute();
	}

	/**
	 * purge_config_history()
	 * Purges machine's hwinfo history
	 *
	 * @access public
	 * @return bool true if succeeded
	 */
	function purge_config_history()	{
		if( !($config = $this->get_current_configuration()) )
			return false;
		if( !($stmt = get_pdo()->prepare("DELETE FROM `config` WHERE machine_id=:id AND config_id<>:cid")) )
			return null;
		$stmt->bindParam(':id',$this->fields['machine_id']);
		$stmt->bindParam(':cid',$config->get_id());
		return $stmt->execute();
	}

	/**
	 * purge_group_membership()
	 * Purges machine's group memberships
	 *
	 * @access public
	 * @return bool true if succeeded
	 */
	function purge_group_membership() {
		return $this->_purge('group_machine');
	}

	/**
	 * purge_job_history()
	 * Purges machine's job history
	 *
	 * @access public
	 * @return bool true if succeeded
	 */
	function purge_job_history() {
		if( !$this->_purge('job_on_machine') )
			return false;
		# TODO: this should be removed after one job on multiple machines correctly implemented
		if( !($stmt = get_pdo()->prepare("DELETE FROM `job` WHERE NOT EXISTS( SELECT * FROM job_on_machine WHERE job_on_machine.job_id=job.job_id )")) )
			return true;
		$stmt->execute();
		return true;
	}

	/**
	 * purge_log()
	 * Purges machine's logs
	 *
	 * @access public
	 * @return bool true if succeeded
	 */
	function purge_log() {
		return $this->_purge('log');
	}

	/* generic getters/setters */

	# list of DB fields with types
	# 'i'=> int/tinyint, 's'=>varchar/text, 'd'=>date/timestamp, array=>enum, other strings: values from that table 
	static $field_types = array(
		'machine_id'=>'i',
		'unique_id'=>'s',
		'name'=>'s',
		'arch_id'=>'arch',
		'maintainer_id'=>'s',
		'ip'=>'s',
		'product_id'=>'product',
		'product_arch_id'=>'arch',
		'release_id'=>'release',
		'kernel'=>'s',
		'description'=>'s',
		'last_used'=>'s',
		'machine_status_id'=>'machine_status',
		'affiliation'=>'s',
		'usage'=>'s',
		'usedby'=>'s',
		'anomaly'=>'s',
		'serialconsole'=>'s',
		'powerswitch'=>'s',
		'busy'=>'i',
		'consoledevice'=>'s',
		'consolespeed'=>'s',
		'consolesetdefault'=>'i',
		'default_option'=>'s',
		'role'=>array('SUT','VH'),
		'type'=>'s',
		'vh_id'=>'machine',
		'reserved'=>'d',
		'expires'=>'d',
		'rpm_list'=>'s'
	);

	/**
	 * get
	 *
	 * Generic getter function
	 *
	 * @param string $field Name of the field to get, as in the DB.
	 *
	 * @access public
	 * @return string the value of the field, or null if NULL/error/unknown field
	 */
	function get($field)	{
		if( !isset(self::$field_types[$field]) )
			return null;
		if( !($stmt = get_pdo()->prepare("SELECT `$field` FROM machine WHERE machine_id=:id")) )
			return null;
		$stmt->bindParam(':id',$this->fields['machine_id']);
		$stmt->execute();
		$row = $stmt->fetch(PDO::FETCH_ASSOC);
		return $row ? $row[$field] : null;
	}

	/**
	 * set
	 *
	 * Generic setter function
	 *
	 * @param string $field Name of the field to set, as in the DB.
	 * @param string $value Value to be set here (caller responsible for proper value).
	 *
	 * @access public
	 * @return bool true if the update succeeds
	 */
	function set($field,$value)	{
		$type = self::$field_types[$field];
		if( !isset($type) )
			return null;
		if( !($stmt = get_pdo()->prepare("UPDATE machine SET `$field`=:val WHERE machine_id=:id")) )
			return null;
		if( strlen($type)>1 && strlen($value)==0 )
			$value=null;
		$stmt->bindParam(':val',$value);
		$stmt->bindParam(':id',$this->fields['machine_id']);
		$this->fields[$field]=$value;
		return $stmt->execute();
	}

	/**
	 * enumerte
	 *
	 * Reads enum values. This can be used to list all combinations, its matching subset,
	 * 	or just a single value.
	 *
	 * @access public
	 * @param string $field Name of the field to enumerate (must have the proper type)
	 * @param mixed $values Null to return all possibilities, ID (scalar) to return single name,
	 * 	array of IDs to return a matching subset
	 * @return mixed the matching name for a scalar $values, array (matching) IDs=>names otherwise.
	 */
	static function enumerate($field,$values=null)	{
		if( !isset(self::$field_types[$field]) )
			return null;
		$table = self::$field_types[$field];
		if( strlen($table)<=1 )
			return null;
		if( is_array($table) )
			$ret=$table;
		else	{
			$id = $table . '_id';
			$sql = "SELECT DISTINCT `$id`,`$table` FROM `$table`";
			if( is_array($values) )	{
				if( count($values)>0 )	{
					for( $i=0; $i<count($values); $i++ )
						$values[$i] = get_pdo()->quote($values[$i]);
					$sql .= " WHERE `$id` IN (" . implode(',',$values) . ')';
				}
			}
			else if( isset($values) )
				$sql .= " WHERE `$id`=" . get_pdo()->quote($values);
			if( !($stmt=get_pdo()->prepare($sql)) )
				return null;
			$stmt->execute();
			$ret = array();
			while( $row = $stmt->fetch(PDO::FETCH_ASSOC) )
				$ret[$row[$id]] = $row[$table];
		}
		if( !isset($values) || is_array($values) )
			return $ret;
		else
			return (isset($ret[$values]) ? $ret[$values] : null );
	}
}



/**
 * MachineSearch 
 *
 * Manages a search for machines
 * '=' for exact matching , 'LIKE' for SQL LIKE matching
 * @version $Rev: 1841 $
 * @author Kevin Wolf <kwolf@suse.de> 
 */
class MachineSearch {
	
	const FILTER_EQUALS = 1;
	const FILTER_LIKE = 2;
	const FILTER_IN = 3;
	private $where;
	private $params;
	private $tables;
	private $postfilters;
	/**
	 * __construct 
	 *
	 * Creates a new MachineSeach object
	 * 
	 * @return void
	 */
	public function __construct() {
		$this->where = array();
		$this->params = array();
		$this->tables = array();
		$this->postfilters = array();
		$this->condition_str = 'WHERE 1 ';
	}

	/**
	 * query 
	 *
	 * Performs the search on the database
	 * 
	 * @return array Array of matching Machine objects; null on error
	 */
	public function query() {
		// Build the SQL query
		$sql = 'SELECT DISTINCT machine.* FROM ';
		$table_str = 'machine ';
		foreach ($this->tables as $table => $condition) {
			$table_str .= ",".$table;
			$this->condition_str .= ' AND '.$condition;
		}
        foreach ($this->where as $condition) {
            $this->condition_str .= ' AND '.$condition;
        }
		$sql .= $table_str." ".$this->condition_str.' ORDER BY machine.name';

		// Create a statemt object and bind the parameters
		if (!($stmt = get_pdo()->prepare($sql))) {
			return null;
		}

		// Start the query and get the result
		$stmt->execute($this->params);
		$result = array();
		while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
			$machine = new Machine($row);
			$result[] = $machine;
		}

		foreach ($result as $index => $machine) {
			foreach ($this->postfilters as $filter) {
				if (!$filter->matches($machine)) {
					unset($result[$index]);
					break;
				}
			}
		}

		return $result;
	}

	/**
	 * add_condition 
	 *
	 * Adds a condition based on the attributes of the machine itself to 
	 * the query. This function cannot be used for matching modules or
	 * module elements.
	 * 
	 * @return bool true if the condition could be added to the search; false
	 *	  on error
	 */
    protected function add_condition($field, $value, $operator = '=') {
        if (!ereg("[a-z_`]+", $field)) {
            return false;
        }

        if (!in_array($operator, array('=', 'LIKE', 'IN', 'IS NOT NULL'))) {
            return false;
        }

        if ($operator == 'IN') {
            if (!is_array($value)) {
                return false;
            }

            if (empty($value)) {
                $this->where[] = '0';
                return true;
            }

            foreach ($value as &$id) {
                $id = get_pdo()->quote($id);
            }

           $value = '(' . join(',', $value) . ')';
           $this->where[] = $field . ' ' . $operator . ' ' .$value;

        } elseif ($operator == 'IS NOT NULL') {
            $this->where[] = $field . ' IS NOT NULL';
        } else {
            $this->where[] = $field . ' ' . $operator . ' :' . str_replace(array(".","`"), "_", $field);
            $this->params[":".str_replace(array(".","`"), "_", $field)] = $value;
        }

        return true;
    }
	
	/**
	 * add_table 
	 *
	 * Adds another table to the SQL query
	 * 
	 * @param string $table Name of the table to add
	 * @param string $join_condition SQL condition used to perform the join
	 * @return boolean true on success; false otherwise
	 */
	protected function add_table($table, $join_condition) {
		if (!ereg("[a-z_]+", $table)) {
			return false;
		}

		if (array_key_exists($table, $this->tables)) {
			return false;
		}	

		$this->tables[$table] = $join_condition;

		return true;
	}

	/**
	 * add_postfilter 
	 *
	 * Adds a filter implemented in PHP. As these filters require the database
	 * to read out all rows in the first place because the filtering is done
	 * by PHP code, these filters are not as efficient as SQL conditions.
	 *
	 * Whenever possible choose a SQL condition instead.
	 * 
	 * @param Filter $filter 
	 * @return void
	 */
	protected function add_postfilter(Filter $filter) {
		$this->postfilters[] = $filter;
	}

	/**
	 * filter_in_array 
	 *
	 * Filters for machines whose ID is in the given array
	 * 
	 * @param array $ids Array of the IDs of all machines to find
	 * @return void
	 */
	public function filter_in_array($ids) {
		$this->add_condition('machine_id', $ids, 'IN');
	}
	
	/**
	 * filter_group 
	 *
	 * Filters for machines belonging to the given group
	 * 
	 * @param string $group_name Group name
	 * @return void
	 */
	public function filter_group($group_name) {
		$this->add_table('group_machine', 'group_machine.machine_id = machine.machine_id');
		$this->add_table('`group`', '`group`.group_id = group_machine.group_id');
		$this->add_condition('`group`.`group`', $group_name, '=');
	}

	/**
	 * filter_architecture 
	 * 
	 * Filter for machines of a given architecture
	 * 
	 * @param string $arch Name or substring of the architecture
	 * @return void
	 */
	public function filter_architecture($arch, $operator = '=') {
        $stmt = get_pdo()->prepare('SELECT arch_id FROM arch WHERE arch="' . $arch . '"');
        $stmt->execute();
        $arch_id = $stmt->fetchColumn();
		$this->add_condition('product_arch_id', $arch_id, $operator);
	}

	/**
	 * filter_architecture_capable
	 *
	 * Filter for machines of a given architecture (this is CPU or capable arch)
	 *
	 * @param string $arch Name or substring of the architecture
	 * @return void
	 */
	public function filter_architecture_capable($arch, $operator = '=') {
        $stmt = get_pdo()->prepare('SELECT arch_id FROM arch WHERE arch="' . $arch . '"');
        $stmt->execute();
        $arch_id = $stmt->fetchColumn();
        $this->add_condition('arch_id', $arch_id, $operator);
	}

	/**
	 * filter_status 
	 *
	 * Filter for machines in a given status
	 * 
	 * @param string $status_id ID of the status to search for
	 * @return void
	 */
	public function filter_status_string($status_id, $operator = '=') {
        $this->add_table('machine_status','machine_status.machine_status_id = machine.machine_status_id');
		$this->add_condition('machine_status.machine_status', $status_id, $operator);
	}

    /**
     * Simple filer group. In this group, the condition string is right in the machine table, so we don't need to add_table. This group could be extended.
     * Now it includes:
     * maintainer_string, used_by, usage, kernel, serialconsole, powerswitch
     * 
     * @param string is the column name
     * @return void
     */
    public function filter_maintainer_string($value, $operator = '=') {
        $this->add_condition('maintainer_id', $value, $operator);
    }
    public function filter_used_by($value, $operator = '=') {
        $this->add_condition('usedby', $value, $operator);
    }
    public function filter_usage($value, $operator = '=') {
        $this->add_condition('`usage`', $value, $operator);
    }
    public function filter_kernel($value, $operator = '=') {
        $this->add_condition('kernel', $value, $operator);
    }
    public function filter_serialconsole($value, $operator = '=') {
        $this->add_condition('serialconsole', $value, $operator);
    }
    public function filter_powerswitch($value, $operator = '=') {
        $this->add_condition('powerswitch', $value, $operator);
    }

	/**
	 * filter_vh
	 *
	 * Filter for machines with a given VH
	 *
	 * @param string $vh_id ID of the VH to search for
	 * @return void
	 */
	public function filter_vh($vh_id, $operator = '=') {
		$this->add_condition('machine.vh_id', $vh_id, $operator);
	}

	/**
	 * filter_role
	 *
	 * Filter for machines with a given role
	 * 
	 * @param string $role to search for
	 * @return void
	 */
	public function filter_role($role, $operator = '=') {
		$this->add_condition('machine.role', $role, $operator);
	}

	// TODO: add filter by type (more complicated!)

	/**
	 * filter_module_description 
	 *
	 * Filter for machines with a module matching the given description
	 * 
	 * @param string $module Name of the module (e.g. "netcard")
	 * @param string $description Description to search for
	 * @return void
	 */
	public function filter_module_description($module, $description, $operator = '=') {
		$this->add_postfilter(new FilterModuleDescription($module, $description));
	}
	
	/**
	 * filter_module_driver 
	 *
	 * Filter for machines with a module matching the given driver
	 * 
	 * @param string $module Name of the module (e.g. "netcard")
	 * @param string $driver  Name of the drive to search for (e.g. "tg3")
	 * @return void
	 */
	public function filter_module_driver($module, $driver, $operator = '=') {
		$this->add_postfilter(new FilterModuleDriver($module, $driver));
	}
	
	/**
	 * filter_module_element 
	 *
	 * Filter for machines where a element of the given modules matches the
	 * given name and value.
	 * 
	 * @param string $module Name of the module (e.g. "netcard")
	 * @param string $element Name of the element (e.g. "Vendor")
	 * @param string $value Name of the value to search for
	 * @return void
	 */
	public function filter_module_element($module, $element, $value, $operator = '=') {
		$this->add_postfilter(new FilterModuleElement($module, $element, $value));
	}
	
	/**
	 * filter_anything 
	 *
	 * Performs a search on all elements of all modules of a machine. The 
	 * machine is returned if name or value of any of these elements match
	 * the given text.
	 * 
	 * @param string $text Text to search for
	 * @return void
	 */
	public function filter_anything($text, $operator) {
		$this->add_table('config', 'config.machine_id = machine.machine_id');
		$this->add_table('config_module', 'config.config_id = config_module.config_id');
		$this->add_table('module', 'module.module_id = config_module.module_id');
		$this->add_table('module_part', 'module_part.module_id = module.module_id');
		
		if ($operator == 'LIKE') {
			$text = "%".$text."%";
		}
		$this->condition_str = "WHERE (module_part.value ".$operator."'".$text."' OR module_part.element ".$operator."'".$text."') ";
	}
}


/**
 * Filter 
 *
 * Defined a PHP filter for machine searches. You cannot use Filter itself,
 * instead use its subclasses.
 * 
 * @version $Rev: 1841 $
 * @author Kevin Wolf <kwolf@suse.de> 
 */
abstract class Filter {
	protected $operator;
	
	/**
	 * matches 
	 * 
	 * @param Machine $machine Machine to be checked
	 * @return bool true if the given machine matches the filter; false otherwise
	 */
	abstract public function matches(Machine $machine);

	/**
	 * set_operator 
	 *
	 * Sets the matching operator to be used for the filter. This operator may
	 * or may not be used by a Filter.
	 * 
	 * @param $operator ('=' or 'LIKE')
	 * @return void
	 */
	public function set_operator($operator) {
		$this->operator = $operator;
	}
}	

/**
 * FilterModuleDescription 
 *
 * Filters for machines with a module with given description.
 * Supports exact matching only.
 * 
 * @version $Rev: 1841 $
 * @author Kevin Wolf <kwolf@suse.de> 
 */
class FilterModuleDescription extends Filter {
	private $module;
	private $description;

	/**
	 * __construct 
	 * 
	 * @param mixed $module Name of the module (e.g. "netcard")
	 * @param mixed $description Description to search for
	 * @return void
	 */
	public function __construct($module, $description) {
		$this->module = $module;
		$this->description = $description;
	}
	
	/**
	 * matches 
	 * 
	 * @see Filter::matches()
	 */
	public function matches(Machine $machine) {
		$config = $machine->get_current_configuration();
		if ($config == null) {
			return false;
		}
		
		$module = $config->get_module($this->module);
		if (is_null($module)) {
			return false;
		}

		return ($module->__toString() == $this->description);
	}
}	

/**
 * FilterModuleDriver 
 * 
 * Filters for machines with a module with given driver.
 * Supports exact matching only.
 *
 * @version $Rev: 1841 $
 * @author Kevin Wolf <kwolf@suse.de> 
 */
class FilterModuleDriver extends Filter {
	private $module;
	private $driver;

	/**
	 * __construct 
	 * 
	 * @param mixed $module Name of the module (e.g. "netcard")
	 * @param mixed $driver Driver name to search for
	 * @return void
	 */
	public function __construct($module, $driver) {
		$this->module = $module;
		$this->driver= $driver;
	}
	
	/**
	 * matches 
	 * 
	 * @see Filter::matches()
	 */
	public function matches(Machine $machine) {
		if (!($configuration = $machine->get_current_configuration())) {
			return 0;
		}
		
		$module = $configuration->get_module($this->module);

		if (is_null($module)) {
			return 0;
		}
		return ($module->get_driver() == $this->driver);
	}
}	

/**
 * FilterModuleElement 
 * 
 * Filters for machines where the value a given element of a module matches
 * a given text. 
 * Supports exact matching only.
 * 
 * @version $Rev: 1841 $
 * @author Kevin Wolf <kwolf@suse.de> 
 */
class FilterModuleElement extends Filter {
	private $module;
	private $element;
	private $value;

	/**
	 * __construct 
	 * 
	 * @param mixed $module Name of the module (e.g. "netcard")
	 * @param mixed $element Name of the element of the module (e.g. "Vendor")
	 * @param mixed $value Element value to search for
	 * @return void
	 */
	public function __construct($module, $element, $value) {
		$this->module = $module;
		$this->element = $element;
		$this->value = $value;
	}
	
	/**
	 * matches 
	 * 
	 * @see Filter::matches()
	 */
	public function matches(Machine $machine) {
		if (!($configuration = $machine->get_current_configuration())) {
			return 0;
		}
		
		$module = $configuration->get_module($this->module);
		if (is_null($module)) {
			return 0;
		}
		return ($module->get_element_from_any_part($this->element) == $this->value);
	}
}	

?>
