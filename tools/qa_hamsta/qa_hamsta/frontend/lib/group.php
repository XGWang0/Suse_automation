<?php

/**
 * Represents a group of machines.
 *
 * @package Machine
 * @author Kevin Wolf <kwolf@suse.de> 
 * @version $Rev: 1615 $
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
class Group {

    /**
     * @var array Associative array containing the values of all database
     *      fields of this group
     */
    private $fields;

    /**
     * Creates a new instance of Group.
     *
     * The constructor is meant to be called only by functions that
     * directly access the database and have to get an object from
     * their query result.
     * 
     * @param array $fields Values of all database fields.
     */
    public function __construct($fields) {
        $this->fields = $fields;
    }
    
    /**
     * Creates a new group. 
     * 
     * @param string $name Name of the new group.
     * @param string $description Description of the new group.
     * @param array $machines Array of Machine objects which form
     *      the new group.
     * @return void
     */
    public static function create($name, $description, $machines) {
        if (!($stmt = get_pdo()->prepare('INSERT INTO `group` (`group`, description) VALUES (:name, :description)'))) {
            return null;
        }
        $stmt->bindParam(':name', $name);
        $stmt->bindParam(':description', $description);
		try
		{
			$stmt->execute();
		}
		catch(Exception $e)
		{
			$errorInfo = $stmt->errorInfo();
			
			# If the error was that there is a duplicate entry
			if($errorInfo[1] == 1062)
			{
				return -2;
			}
			# Some other error
			else
			{
				return -1;
			}
		}

        if (empty($machines)) {
            return;
        }

	$group_id = get_pdo()->lastInsertId();
        
        
        $values = array();
        foreach ($machines as $machine) {
            $values[] = "(".get_pdo()->quote($group_id).",".get_pdo()->quote($machine->get_id()).")";
        }
        $values = join(",", $values);
        
        if (!($stmt = get_pdo()->prepare('INSERT INTO group_machine (group_id, machine_id) VALUES '.$values))) {
            return null;
        }
        $stmt->execute();
    }

    /**
     * Edits a group's information.
     *
     * @param string $name New name for the group.
     * @param string $description New description for the group.
     * @return void
     */
    public function edit($name, $description)
    {
        if (!($stmt = get_pdo()->prepare('UPDATE `group` set `group` = :name, description = :description WHERE group_id = :group_id')))
        {
            return null;
        }
        $stmt->bindParam(':name', $name);
        $stmt->bindParam(':description', $description);
		$stmt->bindParam(':group_id', $this->fields["group_id"]);
		try
		{
			$stmt->execute();
		}
		catch(Exception $e)
		{
			$errorInfo = $stmt->errorInfo();

			# If the error was that there is a duplicate entry
			if($errorInfo[1] == 1062)
			{
				echo "oops";
				return -2;
			}
			# Some other error
			else
			{
				return -1;
			}
		}
    }

    /**
     * Get a Group object by the group name from the database.
     *
     * @param string $name Name of the group to get.
     *
     * @return \Group Requested group object or null if no group matches
     *      the name; null if a database error occurs.
     */
    public static function get_by_name($name) {
        if (!($stmt = get_pdo()->prepare('SELECT * FROM `group` WHERE `group` = :name'))) {
            return null;
        }
        $stmt->bindParam(':name', $name);

        $stmt->execute();
        $row = $stmt->fetch(PDO::FETCH_ASSOC);
        $stmt->closeCursor();

        return $row ? new Group($row) : null;
    }

    /**
     * Get a Group object by the group id from the database.
     *
     * @param int $id ID of the group to get.
     * @return \Group Requested group object or null if no group matches
     *      the ID; null if a database error occurs.
     */
    public static function get_by_id($id) {
        if (!($stmt = get_pdo()->prepare('SELECT * FROM `group` WHERE group_id = :group_id'))) {
            return null;
        }
        $stmt->bindParam(':group_id', $id);

        $stmt->execute();
        $row = $stmt->fetch(PDO::FETCH_ASSOC);
        $stmt->closeCursor();

        return $row ? new Group($row) : null;
    }

    /**
     * Gets Group objects containing all available groups.
     * 
     * @return array Array of Group objects containing all available groups;
     *      null if a database error occurs.
     */
    public static function get_all() {
        if (!($stmt = get_pdo()->prepare('SELECT * FROM `group`'))) {
            return null;
        }

        $stmt->execute();

        $result = array();
        $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);
        foreach ($rows as $row) {
            $result[] = new Group($row);
        }

        return $result;
    }

    /**
     * Gets id of this group.
     *
     * @return int ID of the group.
     */
    public function get_id() {
        return $this->fields["group_id"];
    }

    /**
     * Gets name of this group.
     * 
     * @return string Name of the group.
     */
    public function get_name() {
        return $this->fields["group"];
    }
    
    /**
     * Gets description of this group.
     * 
     * @return string Description of the group.
     */
    public function get_description() {
        return $this->fields["description"];
    }

    /**
     * Gets list of machines in this group.
     * 
     * @return array Array of Machine objects for all machines belonging
     *      to the group; null if a database error occurcs.
     */
    public function get_machines() {
        if (!empty($this->machines)) {
            return $this->machines;
        }


        if (!($stmt = get_pdo()->prepare('SELECT * FROM group_machine WHERE group_id = :group_id'))) {
            return null;
        }
        $stmt->bindParam(':group_id', $this->fields["group_id"]);
        $stmt->execute();
        
        $result = array();
        $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);
        foreach ($rows as $row) {
            $machine = Machine::get_by_id($row["machine_id"]);
            if ($machine != null) {
                $result[] = $machine;
            }
        }

        $this->machines = $result;
        return $result;
    }
    
    /**
     * Deletes the group from the database.
     * 
     * @return void
     */
    public function delete() {
        if (!($stmt = get_pdo()->prepare('DELETE group_machine FROM group_machine WHERE group_machine.group_id  = :group_id'))) {
            return null;
        }
        $stmt->bindParam(':group_id', $this->fields["group_id"]);
        $stmt->execute();

        if (!($stmt = get_pdo()->prepare('DELETE `group` FROM `group` WHERE `group`.`group` = :group_name'))) {
            return null;
					            }
        $stmt->bindParam(':group_name', $this->fields["group"]);
        $stmt->execute();
    }

    /**
     * Adds a machine to the group.
     *
     * @param \Machine $machine Machine to add to the group.
     *
     * @return boolean True if the machine could be added, false if the
     * machine was already member of the group. On other errors, a
     * PDOException is thrown.
     */
    public function add_machine(Machine $machine) { 
        $machine_id = $machine->get_id();

        if (!($stmt = get_pdo()->prepare('INSERT INTO group_machine (group_id, machine_id) VALUES (:group_id, :machine_id)'))) {
            return null;
        }
        $stmt->bindParam(':group_id', $this->fields["group_id"]);
        $stmt->bindParam(':machine_id', $machine_id);

        try {
            $stmt->execute();
            return true;
        } catch (PDOException $e) {
            if (strstr($e->getMessage(), "Duplicate entry")) {
                return false;
            } else {
                throw $e;
            }
        }
    }
    
    /**
     * Removes a machine from the group.
     *
     * @param \Machine $machine Machine to remove from the group.
     *
     * @return boolean True if the machine could be deleted, false if no
     * machine has been deleted.
     */
    public function del_machine(Machine $machine) { 
        $machine_id = $machine->get_id();

        if (!($stmt = get_pdo()->prepare('DELETE FROM group_machine WHERE (group_id, machine_id) = (:group_id, :machine_id)'))) {
            return null;
        }
        $stmt->bindParam(':group_id', $this->fields["group_id"]);
        $stmt->bindParam(':machine_id', $machine_id);
        $stmt->execute();

        return ($stmt->rowCount() > 0);
    }
	
    /**
     * Find groups a machine belongs to.
     *
     * @param Machine $machine Machine to find groups.
     *
     * @return an hash array of "group_id:group" if the machine belongs to
     * group(s), null if a database error occurcs.
     */
    public static function get_groups_by_machine(Machine $machine) {
        $machine_id = $machine->get_id();
        $result = array();

        if (!($stmt = get_pdo()->prepare('select group.group_id,group.group from hamsta_db.group,group_machine where group.group_id=group_machine.group_id and machine_id=:machine_id'))) {
            return null;
        }
        $stmt->bindParam(':machine_id', $machine_id);
        $stmt->execute();
		
        $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);
        foreach ($rows as $row) {
            $group_id = $row["group_id"];
            $group_name = $row["group"];
            if ($group_id != null and $group_name !=null) {
                $result[$group_id] = $group_name;
            }
        }
        return $result;
    }

    public function check_machine_in_group(Machine $machine) {
        $machine_id = $machine->get_id();

        if (!($stmt = get_pdo()->prepare('SELECT * FROM group_machine WHERE (group_id, machine_id) = (:group_id, :machine_id)' ))) {
            return null;
        }

        $stmt->bindParam(':group_id', $this->fields["group_id"]);
        $stmt->bindParam(':machine_id', $machine_id);
        $stmt->execute();
		
        $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

        return ($stmt->rowCount() > 0);
    }
}

?>
