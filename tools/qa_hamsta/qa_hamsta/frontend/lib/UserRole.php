<?php

/**
 * Class represents user role.
 *
 * @package User
 * @author Pavel Kačer <pkacer@suse.com>
 * @version 1.0.0
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
class UserRole
{

  /** @var string Name of this role. */
  private $name;

  /** @var string Description of this role. */
  private $description;

  /** @var \Zend_Config Application configuration. */
  private $config;

  /**
   * Creates new instance of the UserRole.
   *
   * @param string $name Name of the role to be created.
   * @param string $description Description of the role.
   * @param \Zend_Config $config Application configuration.
   */
  private function __construct ($name, $description, $config)
  {
    $this->name = $name;
    $this->description = $description;
    $this->config = $config;
  }

  /**
   * Gets a role by its name.
   * 
   * @param string $name Name of the role to retrieve.
   * @param \Zend_Config $config Application configuration.
   * 
   * @return \UserRole|null New UserRole instance if name is found in
   * database. NULL is returned otherwise.
   */
  public static function getByName ($name, $config)
  {
    $db = Zend_Db::factory ($config->database);
    $res = $db->fetchAll ('SELECT * FROM user_role WHERE role = ?', $name);
    
    $db->closeConnection ();
    return isset ($res[0]) ? new UserRole ($res[0]['role'], $res[0]['descr'], $config) : NULL;
  }

  /**
   * Adds new role into the system.
   *
   * @param string $name Name of the new role.
   * @param string $description Description of new role.
   * @param \Zend_Config $config And instance of Zend_Config class.
   *
   * @return An instance of new user role or null if some error occurs
   * (e.g. role of that name already exists).
   */
  public static function add ($name, $description, $config)
  {
    $db = Zend_Db::factory ($config->database);
    // TODO fill in method body
    $db->closeConnection ();
    return null;
  }
  
  /**
   * Returns name of this Role.
   *
   * @return string Name of this role.
   */
  public function getName ()
  {
    return $this->name;
  }

  /**
   * Changes name of this role to provided new name.
   *
   * @param string $newName New name for this role.
   * 
   * @return integer Number greater than zero if the name was
   * successfuly changed, zero otherwise.
   */
  public function setName ($newName)
  {
    $db = Zend_Db::factory ($this->config->database);
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

  /**
   * Casts user into this role.
   *
   * @param \User $user An instance of User.
   *
   * @return integer Number greater than zero if user has been added, zero otherwise.
   */
  public function addUser ($user)
  {
    if ( isset ($user)
      && ! in_array ($this->getName(), $user->getRoleList()) )
      {
        $db = Zend_Db::factory ($this->config->database);
        $roleId = $db->fetchCol ('SELECT role_id FROM user_role WHERE role = ?', $this->getName ());
        $userId = $db->fetchCol ('SELECT user_id FROM user WHERE user_login = ?', $user->getLogin ());
        if ( isset ($roleId[0]) && isset ($userId[0]) )
          {
            $data = Array (
                           'user_id' => $userId[0],
                           'role_id' => $roleId[0]
                           );
            return $db->insert ('user_in_role', $data);
          }
      }
    return 0;
  }

}

?>
