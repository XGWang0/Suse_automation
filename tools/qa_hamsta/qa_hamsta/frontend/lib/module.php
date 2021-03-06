<?php

/**
 * Represents a module of a configuration.
 *
 * @package Configuration
 * @author Kevin Wolf <kwolf@suse.de> 
 * @version $Rev: 1638 $
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
class Module {

    /**
     * @var string Name of the module (e.g. "netcard").
     */
    private $name;

    /**
     * @var int Version of the module.
     */
    private $version;

    /**
     * @var array Associative array where keys are part IDs und values are
     *      another associative array where keys are element names and values
     *      are element values.
     * <br />
     * @example Example structure:
     * <pre>
     *  $elements = array(
     *      0 => array(
     *          "Description" => "36: None 00.0: 11300 Partition",
     *          "Device File" => "/dev/sda1"
     *      ),
     *      1 => array(
     *          "Description" => "37: None 00.0: 11300 Partition",
     *          "Device File" => "/dev/sda2"
     *      )
     *  );
     * </pre>
     *      
     */
    private $elements;

    /**
     * Creates a new instance of Module.
     *
     * The constructor is meant to be called only by functions that
     * directly access the database and have to get an object from
     * their query result.
     *
     * @param string $name Name of the module.
     * @param int $version Version of the module.
     * @param array $elements Associative array of the elements of the modules
     *      (keys are element names and values are element values).
     *
     * @return void
     */
    public function __construct($name, $version, $elements) {
        $this->name = $name;
        $this->version = $version;
        $this->elements = array();

        foreach ($elements as $element) {
            $this->elements[$element["part"]][$element["element"]] 
                = $element["value"];
        }
    }

    /**
     * Creates an instance of Module class by name and version.
     *
     * @param string $name Name of the module to get.
     * @param int $version Version of the module to get.
     * @access public
     * @return Module Module corresponding to the given name and version.
     */
    static function get_by_name_version($name, $version) {
        if (!($stmt = get_pdo()->prepare('SELECT * FROM module JOIN module_name USING(module_name_id) JOIN module_part USING(module_id) WHERE module_name = :name AND module_version = :version ORDER BY element'))) {
            return null;
        }
        $stmt->bindParam(':name', $name);
        $stmt->bindParam(':version', $version);

        $stmt->execute();
        $result = $stmt->fetchAll(PDO::FETCH_ASSOC);

        return $result ? new Module($name, $version, $result) : null;
    }

    /**
     * Getter for the name of this module.
     * 
     * @access public
     * @return string Name of the module.
     */
    function get_name() {
        return $this->name;
    }

    /**
     * Getter for the version of this module.
     * 
     * @access public
     * @return int|string Version of the module.
     */
    function get_version() {
        return $this->version;
    }
    
    /**
     * Getter for elements of this module.
     * 
     * @param int $part ID of the part to return the elements of.
     * @access public
     * @return array Elements of the module (keys are element names and values
     *      are element values).
     */
    function get_elements($part) {
        return $this->elements[$part];
    }
    
    /**
     * Getter for parts of this module.
     * 
     * @access public
     * @return array Array of the parts of the module. Each part is an associative
     * array with element names as keys an element values as values.
     */
    function get_parts() {
        return $this->elements;
    }
    
    /**
     * Getter for specific element of some part.
     * 
     * @param string $part Part ID of the element.
     * @param string $element Element to get the value of.
     * @access public
     * @return string Value of the given element of the module.
     */
    function get_element($part, $element) {
        return empty($this->elements[$part][$element]) ? '' : $this->elements[$part][$element];
    }
    
    /**
     * Searches for an element in all parts of a module.
     * 
     * @param string $element Element to get the value of.
     * @access public
     * @return string Value of the given element of the module or empty string
     * if the module could not be found.
     */
    function get_element_from_any_part($element) {
        foreach($this->elements as $part) {
            if (!empty($part[$element])) {
                return $part[$element];
            }
        }

        return '';
    }

    /**
     * Getter for the driver of this module.
     * 
     * @access public
     * @return string Name of the driver of the module or empty string if the
     * driver cannot be determined.
     */
    function get_driver() {
        return $this->get_element_from_any_part("Driver");
    }

    /**
     * Returns a string representation of this module.
     *
     * @access public
     * @return string Description of the module.
     */
    public function __toString() {
        switch($this->get_name()) {
            case "memory":  return $this->get_element_from_any_part("Memory Size");
            case "network":  return "Driver: ".$this->get_driver();
        }
        
        if ($value = $this->get_element_from_any_part("Model")) {
            return $value;
        } elseif ($value = $this->get_element_from_any_part("Driver")) {
            return $value;
        } elseif ($value = $this->get_element_from_any_part("Vendor")) {
            return $value;
        } else {
            reset($this->elements[0]);
            list($name, $value) = each($this->elements[0]);
            return $name . " = " . $value;
        }
    }

    /**
     * Checks if a given text is contained in the name or value of an element
     * of this module.
     * 
     * @param string $text Text to search for.
     * @access public
     * @return boolean True if the name or value of an element of this module
     * contains the given text, false otherwise. If the text is empty, returns
     * always false.
     */
    function contains_text($text) {
        if (empty($text)) {
            return false;
        }

        foreach($this->elements as $part) {
            foreach($part as $name => $value) {
               if ((stristr($name, $text) !== FALSE) || (!empty($value) && stristr($value, $text) !== FALSE)) {
                   return true;
               }
            }
        }

        return false;
    }

    /**
     * Checks if a given text is contained in a given element of the module.
     * 
     * @param int $part ID of the part to which the element belongs.
     * @param string $element Name of the element.
     * @param string $text Text to search for.
     * @access public
     * @return boolean true if the name or value of the given element contain
     * the given text, false otherwise. If the text is empty, returns always
     * false.
     */
    function element_contains_text($part, $element, $text) {
        if (empty($text)) {
            return false;
        }
        
        $value = $this->get_element($part, $element);
        return ((stristr($element, $text) !== FALSE) || (!empty($value) && stristr($value, $text) !== FALSE));
    }
}

?>
