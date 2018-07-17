<?php

/**
 * Represents a configuration of a machine at one time.
 *
 * A configuration consists of all the hardware of the machine.
 * Provides methods for different types of authentication and logout
 * procedures.
 *
 * @package Configuration
 * @author Kevin Wolf <kwolf@suse.de> 
 * @version $Rev: 1696 $
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
class Configuration {

    /**
     * @var array Associative array containing the values of all
     * database fields of this configuration.
     */
    private $fields;

    
    /**
     * @var array Contains all modules that already have been queried from
     * the database.
     */
    private $modules_cache;

    /**
     * Creates a new instance of Configuration.
     *
     * The constructor is meant to be called only by functions that
     * directly access the database and have to get an object from
     * their query result.
     * 
     * @param array $fields Values of all database fields.
     */
    function __construct($fields) {
        $this->fields = $fields;
	$this->fields['cid'] = $this->fields['config_id'];
        $this->modules_cache = array();
    }

    /**
     * Gets current configuration by provided id.
     * 
     * @param int $cid ID of the configuration to get
     * @access public
     * @return Configuration Configuration with the given ID or null if no 
     *      matching configuration is found.
     */
    static function get_by_id($cid) {
        if (!($stmt = get_pdo()->prepare('SELECT * FROM config WHERE config_id = :cid'))) {
            return null;
        }
        $stmt->bindParam(':cid', $cid);

        $stmt->execute();
        $row = $stmt->fetch(PDO::FETCH_ASSOC);
        $stmt->closeCursor();

        return $row ? new Configuration($row) : null;
    }

    /**
     * Gets machine with this configuration.
     * 
     * @access public
     * @return \Machine Machine to which the configuration belongs
     */
    function get_machine() {
        if (!($stmt = get_pdo()->prepare('SELECT * FROM machine WHERE machine_id = :id'))) {
            return null;
        }
        $stmt->bindParam(':id', $this->fields["machine"]);
        $stmt->execute();
        $row = $stmt->fetch(PDO::FETCH_ASSOC);
        $stmt->closeCursor();

        return $row ? new Machine($row) : null;
    }

    /**
     * Returns id of this configuration.
     * 
     * @access public
     * @return int ID of the configuration.
     */
    function get_id() {
        return $this->fields["cid"];
    }
    
    /**
     * Returns timestamp of creation of this configuration.
     * 
     * @access public
     * @return string Date and time of creation.
     */
    function get_created() {
        return $this->fields["timestamp_created"];
    }

    /**
     * Returns timestamp of last activity of this configuration.
     * 
     * @access public
     * @return string Date and time when the configuration was last active
     */
    function get_last_activity() {
        return $this->fields["timestamp_last_active"];
    }

    /**
     * Returns all modules of this configuration.
     * 
     * @access public
     * @return array Array of Module objects for all modules belonging to the
     *      configuration.
     */
    function get_modules() {
        if (!($stmt = get_pdo()->prepare('SELECT * FROM config_module JOIN module USING(module_id) JOIN module_name USING(module_name_id) WHERE config_id = :cid ORDER BY module_name'))) {
            return null;
        }
        $stmt->bindParam(':cid', $this->fields["cid"]);
        $stmt->execute();
        $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

        $result = array();
        foreach ($rows as $row) {
            if ($module = Module::get_by_name_version($row["module_name"], $row["module_version"])) {
                $this->modules_cache[$row["module_name"]] = $module;
                $result[] = $module;
            } else {
              // TODO Do something when module does not exist
            }
        }

        return $result;
    }
    
    /**
     * Returns module by provided name.
     *
     * @param string $module_name Name of the module to get
     * @access public
     * @return \Module Module of the configuration with the given module name
     */
    function get_module($module_name) { 

        if (!empty($this->modules_cache[$module_name])) {
            return $this->modules_cache[$module_name];
        }
        
        if (!($stmt = get_pdo()->prepare('SELECT * FROM config_module JOIN module USING(module_id) JOIN module_name USING(module_name_id) WHERE config_id = :cid AND module_name = :module_name'))) {
            return null;
        }
        $stmt->bindParam(':cid', $this->fields["cid"]);
        $stmt->bindParam(':module_name', $module_name);
        
        $stmt->execute();
        $row = $stmt->fetch(PDO::FETCH_ASSOC);
        $stmt->closeCursor();

        if ($module = Module::get_by_name_version($row["module_name"], $row["module_version"])) {
            $this->modules_cache[$module_name] = $module;
            return $module;
        } else {
            return null;
        }
    }
}

?>
