<?php

define ("MS_UP", 1);
define ("MS_DOWN", 2);
define ("MS_NOT_RESPONDING", 5);
define ("MS_UNKNOWN", 6);

/**
 * Represents a single machine.
 *
 * @package Machine
 * @author Kevin Wolf <kwolf@suse.de> 
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
class Machine {

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
	 * @var array An array containing the machines which are
	 * running on this machine.
	 * 
	 * This is null if the machine is not Virtualization Host (role VH).
	 * If the machine is VH, this variable is filled by the first call 
	 * function get_children.
	 */
	private $children = null;

	/**
	 * Creates a new instance of Machine.
	 *
	 * The constructor is meant to be called only by functions
	 * that directly access the database and have to get an object
	 * from their query result.
	 * 
	 * @param array $fields Values of all database fields.
	 */
	function __construct($fields) {
		$this->fields = $fields;
		$this->fields['id'] = $this->fields['machine_id'];
	}

	/**
	 * Gets a machine by hostname.
	 *
	 * @param string $hostname Hostname of the machine to get.
	 * @access public
	 * @return \Machine Machine with the given hostname
	 *	  or null if no matching machine is found.
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
	 * Gets a machine by its id.
	 * 
	 * @param int $id Database ID of the machine.
	 * @access public
	 * @return Machine Machine with the given database ID
	 *	  or null if no matching machine is found.
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
	 * Gets a machine by IP address.
	 * 
	 * @param int $ip Database IP address of the machine.
	 * @access public
	 * @return Machine Machine with the given database IP
	 *	  or null if no matching machine is found.
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
	 * Gets an ID of this machine.
	 * 
	 * @access public
	 * @return int Database ID of the machine.
	 */
	function get_id() {
		if( isset($this->fields["id"]) )
			return $this->fields["id"];
		else
			return NULL;
	
	}

	/**
	 * Gets a hostname of this machine.
	 * 
	 * @access public
	 * @return string Hostname of the machine.
	 */
	function get_hostname() {
		if( isset($this->fields["name"]) )
			return $this->fields["name"];
		else
			return NULL;
	}

	/**
	  * Alias for get_hostname()
	  * @access public
	  * @return string Hostname of the machine.
	  **/
	function __toString()	{
		return $this->get_hostname();
	}

	/**
	 * Gets an IP address of this machine.
	 * 
	 * @access public
	 * @return string IP address of the machine.
	 */
	function get_ip_address() {
		if( isset($this->fields["ip"]) )
			return $this->fields["ip"];
		else
			return NULL;
	}

    /**
     * Gets group this machine is in.
     * 
     * @access public
     * @return string Group name of this machine.
     */
    function get_group() {
	$gnames = "";
	$result = "";
    	if( isset($this->fields["id"]) ) {
			$stmt = get_pdo()->prepare('select .group.group from .group,group_machine where .group.group_id=group_machine.group_id and group_machine.machine_id=:machineid');
			$stmt->bindParam(':machineid', $this->fields["id"]);
			$stmt->execute();
			$groups=$stmt->fetchAll();
			if ( count($groups) >= 1 ) {
				foreach ( $groups as $gname ) {
					$gnames .= "$gname[0], ";
				}
				return substr($gnames, 0, -2);
			} else {
				return "";
			}
    	} else {
    		return NULL;
    	}
    }

	/**
	 * Gets architecture of this machine.
	 *
	 * Note: This gets the <b>current</b> architecture of the machine (i.e. what it is currently installed to.
	 * To get the <b>real</b> (capable) architecture of a machine, use get_architecture_capable().
	 *
	 * @access public
	 * @return string Architecture of the machine, if no variable in.
	 * @return ID Architecture of the machine, if $need_id variable in.
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
	 * Gets capable architecture of this machine.
	 *
	 * Note: This gets the <b>real</b> architecture of the machine (i.e. what it is capable of), but not necessarily installed to.
	 * To get the <b>current</b> (installed) architecture of a machine, use get_architecture().
	 *
	 * @access public
	 * @return string Real architecture of the machine, if no parameter in.
	 * @return in Real id architecture of the machine, if $need_id parameter in.
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
	 * Gets latest hardware element of this machine.
	 * 
	 * @access public
	 * @return string Latest hardware element values of this machine.
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
	function get_ishwvirt() {
		$ishwvirt = $this->get_hwelement("ishwvirt","IsHWVirt");
		return $ishwvirt;
	}
	function get_reserved_master() {
		if( !isset($this->fields['hamsta_master_id']) )
			return NULL;
		if( !($stmt = get_pdo()->prepare('SELECT hamsta_master_ip FROM hamsta_master WHERE hamsta_master_id=:id')) )
			return NULL;
		$stmt->bindParam(':id',$this->fields['hamsta_master_id']);
		$stmt->execute();
		return 'http://'.$stmt->fetchColumn().'/hamsta/index.php';
	}

	/**
	 * get_devel_tools()
	 *
	 * @access public
	 * @return int(bool) Indicating whether client is running devel tools.
	 */
	function get_devel_tools() {
		$devel_tools = $this->get_hwelement("devel_tools", "DevelTools");
		return $devel_tools;
	}

	/*
	 * get_rpm_list()
	 *
	 * @access public
	 * @return string List of client installed packages.
	 */
	function get_rpm_list() {
		return $this->get_hwelement ("rpm_list", "RPMList");
	}

	/**
	 * Gets update status of this machine.
	 * 
	 *@access public
	 *@return true if SUT side have hamste update available
	 */
        function get_update_status() {
		return $this->fields["update_status"];
	}

	/**
	 * Gets timestamp this machine was last used.
	 * 
	 * @access public
	 * @return string Date string as returned by the database indicating 
	 *	  the last usage of the machine.
	 */
	function get_last_used() {
	if( isset($this->fields["last_used"]) )
		return $this->fields["last_used"];
	else
		return NULL;
	}
	
	/**
	 * Gets unique identifier of this machine.
	 * 
	 * @access public
	 * @return string Unique ID if the machine.
	 */
	function get_unique_id() {
	if( isset($this->fields["unique_id"]) )
			return $this->fields["unique_id"];
		else
			return NULL;
	}
 
	/**
	 * Gets power switch of this machine.
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
	 * Sets the powerswitch description of the machine.
	 * 
	 * @param string $powerswitch The configuration of the connected powerwitch.
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
         * Sets the powertype description of the machine
         * 
         * @param string $powertype The configuration of the connected powerswitch.
         * @access public
         * @return mixed True or false depending on the result of the
         *		 database update or NULL if powertype function does not
         *		 exist.
         */
        function set_powertype($powertype)  {
		$power_function = "power_".$powertype;
		if (function_exists("$power_function") OR $powertype == NULL) {
			$stmt = get_pdo()->prepare('UPDATE machine SET powertype = :powertype WHERE machine_id = :id');
        	        $stmt->bindParam(':id', $this->fields["id"]);
	                $stmt->bindParam(':powertype', $powertype);
                	return $stmt->execute();
		}
		else
			return NULL;
        }

        /**
         * Checks if powertype is supported
         * 
         * @param string $powertype The configuration of the connected powerswitch.
         * @access public
         * @return bool 
         */
        function check_powertype()  {
		$powertype = $this->get_powertype();
		$power_function = "power_".$powertype;
		if (function_exists("$power_function")) {
			return TRUE; 
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
         * Sets the powerslot description of the machine.
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
         * @return string results of action
         *
         */
        function start_machine()  {
                $powerswitch = $this->get_powerswitch();
		$powertype = $this->get_powertype();
                $powerslot = $this->get_powerslot();
                $power_function = "power_".$powertype;
		if (function_exists("$power_function")) {
			$result = $power_function($powerswitch, $powerslot, 'start');
			return $result;
		}
		else
			return "not_implemented";
        }

        /**
         * stop_machine
         *
         * @acces public
         * @return string results of action
         *
         */
        function stop_machine()  {
		$powerswitch = $this->get_powerswitch();
                $powertype= $this->get_powertype();
                $powerslot= $this->get_powerslot();
                $power_function = "power_".$powertype;
		if (function_exists("$power_function")) {
			$result = $power_function($powerswitch, $powerslot, 'stop');
			return $result;
		}
		else
			return "not_implemented";
        }

        /**
         * restart_machine
         *
         * @acces public
         * @return string results of action
         *
         */
        function restart_machine()  {
		$powerswitch = $this->get_powerswitch();
                $powertype= $this->get_powertype();
                $powerslot= $this->get_powerslot();
                $power_function = "power_".$powertype;
		if (function_exists("$power_function")) {
			$result = $power_function($powerswitch, $powerslot, 'restart');
			return $result;
		}
		else
			return "not_implemeted";
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
	 * Sets the serialconsole description of the machine.
	 * 
	 * @param string $serialconsole The configuration of the connected serialswitch (for remote control).
	 * @access public
	 * @return void
	 */
	function set_serialconsole($serialconsole)  {
		$stmt = get_pdo()->prepare('UPDATE machine SET serialconsole = :serialconsole WHERE machine_id = :id');
		$stmt->bindParam(':id', $this->fields["id"]);
		$stmt->bindParam(':serialconsole', $serialconsole);
		$stmt->execute();
	}

	/* Add by csxia	*/
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
	 * Sets the serialdevice.
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
	 * Sets the serail console at reinstallation.
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
	 * Sets the default installation option.
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
	 * Sets the status of the machine.
	 * 
	 * @param int $status_id ID of the new status.
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
	 * Sets the maintainer of the machine
	 * 
	 * @param mixed $maintainer ID of the new maintainer.
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
		$retstr = strlen ($this->get_affiliation()) > 0
		  ? $this->get_affiliation() : "";
		$retstr .= strlen ($this->get_anomaly()) > 0
		  ? (strlen ($this->get_affiliation()) > 0
		     ? " " : "")
		  . "ANOMALIES: " . $this->get_anomaly() : "";
		return $retstr;
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
	 * Updates the busy flag of the machine.
	 *
	 * If the busy flag is set to 2 (manually blocked), the flag
	 * will not be changed. Otherwise it will be set to 1 if there
	 * are still jobs running or 0 if no more jobs are running on
	 * the machine.
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
	 * Check for multiple machine permissions and return result.
	 *
	 * @param array $permissions An array of permission strings to check for.
	 *
	 * @return boolean True if machine has permissions from the
	 * $permissions parameter, false otherwise.
	 */
	public function has_permissions($permissions) {
		$machine_perms = explode(',', $this->get_perm());
		if (array_diff($permissions, $machine_perms)) {
			return false;
		}
		return true;
	}

	/**
	 * Get a permission string from database set.
	 *
	 * @return string A string representing the permission set from database.
	 */
	function get_perm () {
		return $this->fields['perm'];
	}

        /**
         * Sets the perm flag of the machine.
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
	 * Check if this machine is a virtual guest.
	 *
	 * @return boolean True if this machine is virtual host. False otherwise.
	 * @see Machine::get_vh_id()
	 */
	public function is_virtual_guest() {
		return $this->get_vh_id() ? true : false;
	}

	/**
	 * get_used_by
	 * This is a workaround function for searching reservator in machine list.
	 *
	 * @access public
	 * @return The reservator name of the machine. 
	 */
	function get_used_by() {
		$rh = new ReservationsHelper ($this);
		return $rh->prettyPrintUsers ();
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
		$sql = 'SELECT * FROM job j LEFT JOIN job_on_machine k USING(job_id) LEFT JOIN job_part_on_machine p USING(job_on_machine_id) WHERE machine_id = :machine_id ORDER BY j.job_id DESC, j.job_status_id ASC';
		if ($limit) {
			$sql .= ' LIMIT '.((int) $start).','.((int) $limit);
		}

		if (!($stmt = get_pdo()->prepare($sql))) {
			return null;
		}
		$stmt->bindParam(':machine_id', $this->fields["id"]);
		
		$stmt->execute();
		$result = array();
		$build_hash = array();
		$mid = $this->fields["id"];
		while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
			$job_id = $row['job_id'];
                        $part_id = $row['job_part_id'];
                        $build_hash[$job_id][$part_id][$mid] = $row;
		}
		foreach ($build_hash as $job_id => $values) {
			$tmp['job_id'] = $job_id;
			$tmp['part_id'] = array();
			foreach ($values as $part => $data) {
				$tmp['part_id'][] = $part;
				$tmp['machines'][$part][$mid] = $data[$mid];
                                $tmp['short_name'] = $data[$mid]['short_name'];
                                $tmp['description'] = $data[$mid]['description'];
                                $tmp['user_id'] = $data[$mid]['user_id'];
                                $tmp['job_status_id'][$part][$mid] = $data[$mid]['job_status_id'];
                                $tmp['start'][$part][$mid] = $data[$mid]['start'];
                                $tmp['stop'][$part][$mid] = $data[$mid]['stop'];
			}
			$result[] = new JobRun($tmp);
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
         * count_queue_jobs 
         * @access public
         * @return int Number of all jobs currently queued on this machine       
         */
        function count_queue_jobs() {
                $sql = 'SELECT COUNT(*) FROM job j LEFT JOIN job_on_machine k USING(job_id) WHERE machine_id = :machine_id AND j.job_status_id = 1 ORDER BY j.job_id DESC';

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
	 * get_current_job
	 *
	 * @return return JobRun object with 'running' or 'connecting' status
	 */
	function get_current_job() {
                $sql = 'SELECT * FROM job j LEFT JOIN job_on_machine k ON k.job_id = j.job_id WHERE machine_id = :machine_id AND (j.job_status_id = 2 OR j.job_status_id = 6) ORDER BY j.job_id DESC';
                if (!($stmt = get_pdo()->prepare($sql))) {
                        return null;
                }
                $stmt->bindParam(':machine_id', $this->fields["id"]);
                $stmt->execute();
                $row = $stmt->fetch(PDO::FETCH_ASSOC);
                if (!empty($row))
                        $result = new JobRun($row);
                else
                        $result = null;
                $stmt->closeCursor();
                return $result;
	}
	/**
	 * get_job_overview_
	 *
	 * @return return string "[running case] Q(JOBNUM)"
	 */
	function get_job_overview() {
		$run_job = $this->get_current_job();
		$result = "";
	        if (!empty($run_job)) {
	                if ($run_job->get_status_string() == 'connecting')
        	                $result .= '<a href="index.php?go=job_details&id='.$run_job->get_id().'">Connecting</a>';
	                else {
	                        $match_arr = array();
	                        $regexp = "/^.*\((qa_test_[0-9a-zA-Z]+)\)|(QA-packages)|(upgrade)|(reinstall)|(Autotest)|(New virtual)|(DefaultXENGrub)/";
	                        $job_name = $run_job->get_name();
	                        if (!empty($job_name)) {
	                                preg_match($regexp,$job_name,$match_arr);
	                                array_shift($match_arr);
	                                $match_str = implode("",$match_arr);
	                                if (!empty($match_str))
	                                        $result .= '<a href="index.php?go=job_details&id='.$run_job->get_id().'">'.$match_str.'</a>';
	                                else
	                                        $result .= '<a href="index.php?go=job_details&id='.$run_job->get_id().'">'.substr($job_name,0,10).'</a>';
	                        }
	                }

	        }
	        if ($this->count_queue_jobs())
	                $result .= ' <span style="float:right; padding-left: 3px;" class="queued">Q('.$this->count_queue_jobs().')</span>';
		return $result;
	}
	/**
	 * count_host_collide 
	 *
	 * @return return number of machines having same hostname
	 */
	function count_host_collide() {
		$sql = 'SELECT count(*) FROM machine WHERE name = :name';
		if (!($stmt = get_pdo()->prepare($sql))) {
                        return null;
                }
		$stmt->bindParam(':name',$this->fields['name']);
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
			$conf = ConfigFactory::build();
			if (!(Machine::$master_socket = fsockopen($conf->cmdline->host, $conf->cmdline->port))) {
				return false;
			}
			stream_set_blocking(Machine::$master_socket, false);
		
			$count = 0;
			while (($s = fgets(Machine::$master_socket, 4096)) != "$>") {
				if (!$s) {
					if (($count++) > 10) {
						fclose(Machine::$master_socket);
						Machine::$master_socket = null;
						Machine::$readerr = "Could not get the master command prompt. Giving up after 10 empty reads from master.";
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
	 * send_master_release 
	 *
	 * Send release command to a machine by the HAMSTA master commandline interface
	 * 
	 * @param NULL
	 *
	 * @access public
	 * @return bool true if the machine is successfully relesed from hamsta master; false on error
	 */
	function send_master_release() {
		if (!($sock = Machine::get_master_socket())) {
			$this->errmsg = (empty(Machine::$readerr)?"cannot connect to master!":Machine::$readerr);
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

		fputs($sock, "release ".$this->get_ip_address()." for master\n");

		$response = "";
		while (($s = fgets($sock, 4096)) != "$>") {
			$response .= $s;
		}

		if (!stristr($response, "succeeded")) {
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
         * get_all_hwtype
         *
         * @return All possible HW types stored in database. Such as hw,vm,xen
         *
         */
        static public function get_all_hwtype() {
                $stmt = get_pdo()->prepare('select DISTINCT type from machine ORDER BY type;');
                $stmt->execute();

                $result = array();
                while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
                        array_push($result,$row["type"]);
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

		//if (!($stmt = get_pdo()->prepare('SELECT * FROM log WHERE machine_id = :id AND job_on_machine_id IS NULL ORDER BY log_id DESC' . ((is_int($limit) and $limit != 0) ? " LIMIT $limit" : "")))) {
		if (!($stmt = get_pdo()->prepare('SELECT * FROM log WHERE machine_id = :id AND job_part_on_machine_id IS NULL ORDER BY log_id DESC' . ((is_int($limit) and $limit != 0) ? " LIMIT $limit" : "")))) {
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
	 * Purges machine's hwinfo history.
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
	 * Purges machine's group memberships.
	 *
	 * @access public
	 * @return bool true if succeeded
	 */
	function purge_group_membership() {
		return $this->_purge('group_machine');
	}

	/**
	 * Purges machine's job history
	 *
	 * @access public
	 * @return bool True if succeeded.
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
	 * Purges machine's logs
	 *
	 * @access public
	 * @return bool True if succeeded.
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
		'anomaly'=>'s',
		'serialconsole'=>'s',
		'powerswitch'=>'s',
		'powertype'=>'s',
		'powerslot'=>'s',
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
		'qaconf_id'=>'i',
	);

	/**
	 * Generic getter function.
	 *
	 * @param string $field Name of the field to get, as in the DB.
	 *
	 * @access public
	 * @return string The value of the field, or null if NULL/error/unknown field.
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
	 * Generic setter function.
	 *
	 * @param string $field Name of the field to set, as in the DB.
	 * @param string $value Value to be set here (caller responsible for proper value).
	 *
	 * @access public
	 * @return bool true if the update succeeds
	 */
	function set($field,$value)	{
		$type = self::$field_types[$field];
		$retval = FALSE;
		if( !isset($type) )
			return null;
		if( !($stmt = get_pdo()->prepare("UPDATE machine SET `$field` = :val WHERE machine_id = :id")) )
			return null;

		/* pkacer@suse.com: This fixes issue with array to
		 * string conversion with 'role' field. This also
		 * checks if the value is in that array. */
		if (! is_array ($type)) {
			if (strlen ($type) > 1 && strlen ($value) == 0) {
				$value = null;
			}
		} else {
			if (! (is_null ($value) || in_array ($value, $type))) {
				return null;
			}
		}

		/* pkacer@suse.com: This fixes issue when a field
		 * requires NULL value. For backward compatibility
		 * some fields are not nullable, so the empty string
		 * '' resulting from `null' is set. */
		try {
			$retval = $stmt->execute (array(':val' => $value, ':id' => $this->fields['machine_id']));
		} catch (PDOException $e) {
			if (is_null ($value) ) {
				/* There IS a difference between `null' and `NULL'. */
				$retval = $stmt->execute (array(':val' => NULL, ':id' => $this->fields['machine_id']));
			}
		}

		if ($retval) {
			$this->fields[$field]=$value;
		}
		return $retval;
	}

	/**
	 * Reads enum values.
	 *
	 * This can be used to list all combinations, its matching
	 * subset, or just a single value.
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

	public function equals ($machine)
	{
		return $this->get_id () == $machine->get_id ();
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
	private $orwhere;
	private $orwhere_for_rough_search;
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
		$this->orwhere = array ();
		$this->orwhere_for_rough_search = array();
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

		if (count ($this->where)) {
			$this->condition_str .= ' AND '
				. implode (' AND ', $this->where);
		}

		/* Has to be enclosed in parenthesis because of the
		 * operator precedence. */
		if (count ($this->orwhere)) {
			$this->condition_str .= ' AND ('
				. implode (' OR ', $this->orwhere) . ')';
		}

		if (count ($this->orwhere_for_rough_search)) {
			$this->condition_str .= ' AND ('
				. implode (' OR ', $this->orwhere_for_rough_search) . ')';
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
        if (! preg_match ('/[a-z_`]+/', $field)) {
            return false;
        }

        if (!in_array($operator, array('=', 'LIKE', 'IN', 'NOT IN', 'IS NOT NULL'))) {
            return false;
        }

        if ($operator == 'IN' || $operator=='NOT IN') {
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

	} elseif ($operator == 'LIKE') {
            $value = "'%".$value."%'";
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
		if (! preg_match ('/[a-z_]+/', $table)) {
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
     * maintainer_string, usage, kernel, serialconsole, powerswitch
     * 
     * @param string is the column name
     * @return void
     */
    public function filter_maintainer_string($value, $operator = '=') {
        $this->add_condition('maintainer_id', $value, $operator);
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

	public function filter_type($type, $operator = 'LIKE')	
	{
		$this->add_condition('machine.type', $type, $operator);
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

		$this->orwhere[] = "module_part.value " . $operator . " :module_part_value";
		$this->params[":module_part_value"] = $text;

		$this->orwhere[] = "module_part.element " . $operator . " :module_part_element";
		$this->params[":module_part_element"] = $text;
	}

        /**
	 * filter_reservation
	 *
	 * Search machines for given type 'my', 'free', 'other'; 
	 * 'my' means machines reserved by the login user.
	 * 'free' means machines not reserved by anyone. 
	 * 'others' means machines reserved by someone other than "my" 
	 * 
	 * @param string $user Text to search for
	 * @type  string Search type
	 * @return void
	 */
	public function filter_reservation($user, $type)
	{
		$machine_ids = array();
		$operator = null;
		if ($type == 'my')
		{
			$user_id = $user->getId();
			$operator = "IN";
			$stmt = get_pdo()->prepare("SELECT machine_id FROM user_machine where user_id = $user_id");
		}
		else if($type == 'free')
		{
			$machine_ids = array();
			$operator = "NOT IN";
			$stmt = get_pdo()->prepare('SELECT machine_id FROM user_machine');
		}
		else if ($type == 'others')
		{
			$machine_ids = array();
			$operator = "IN";
			if (isset($user))
			{
				$user_id = $user->getId();
				$stmt = get_pdo()->prepare("SELECT machine_id FROM user_machine where user_id != $user_id");
			}
			else
			{
				$stmt = get_pdo()->prepare('SELECT machine_id FROM user_machine');
			}
		}
		$r = $stmt->execute();
		$records = $stmt->fetchAll();
		foreach($records as  $r)
		{
			$machine_ids[] = $r[0];
		}
		if (count($machine_ids) > 0)
		{
			$this->orwhere_for_rough_search[] = "machine.machine_id ". $operator . "(". implode(',', $machine_ids) . ")";
		}
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
