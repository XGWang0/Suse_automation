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


  /**
   * Class representing an user role.
   *
   * @author Pavel Kacer <pkacer@suse.com>
   */
class UserRole
{

  /**
   * name
   *
   * @var name Name of this role.
   */
  private $name;

  /**
   * description
   *
   * @var description Description of this role.
   */
  private $description;

  /**
   * __construct
   *
   * Implicit constructor
   *
   * @param name Name of the role to be created.
   */
  private function __construct ($name, $description)
  {
    $this->name = $name;
    $this->description = $description;
  }

  /**
   * getByName
   *
   * Returns a UserRole object if found in database, NULL otherwise.
   * 
   * @param  name Name of the role.
   * @param  config An instance of  Zend_Config class.
   * 
   * @return New UserRole object if name is found in database. NULL is
   * returned otherwise.
   */
  public static function getByName ($name, $config)
  {
    $db = Zend_Db::factory ($config->database);
    $res = $db->fetchAll ('SELECT * FROM user_role WHERE role = ?', $name);
    
    $db->closeConnection ();
    return isset ($res[0]) ? new UserRole ($res[0]['role'], $res[0]['descr']) : NULL;
  }

  /**
   * add
   *
   * Adds new role into the system.
   *
   * @param name Name of the new role.
   * @param description Description of new role.
   * @param config And instance of Zend_Config class.
   *
   * @return An instance of new user role or null if some error occurs
   * (e.g. role of that name already exists).
   */
  public static function add ($name, $description, $config) {
    $db = Zend_Db::factory ($config->database);
    // TODO fill in method body
    $db->closeConnection ();
    return null;
  }
  
  /**
   * getName
   *
   * Returns name of this Role.
   *
   * @return Role name as String.
   */
  public function getName ()
  {
    return $this->name;
  }

  /**
   * setName
   *
   * Changes name of this role to new_name.
   *
   * @param new_name New name for this role.
   * 
   * @return Number greater than 0 if the name was successfuly
   * changed, 0 othewise.
   */
  public function setName ($newName)
  {
    $db = Zend_Db::factory ($config->database);
    $data = array ( 'role' => $newName );
    if ( isset ($ident) ) {
      $res = $db->update ('user_role', $data, 'role = '
                          . $db-quote ( htmlspecialchars ($this->name) ) );
    }

    if ($res) {
      $this->name = $newName;
    }

    $db->closeConnection ();
    return $res;
  }

}

?>