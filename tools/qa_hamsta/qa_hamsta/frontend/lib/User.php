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

require_once ('Authenticator.php');
require_once ('Zend/Db.php');
require_once ('Zend/Session.php');

/**
 * Class represents authenticated user and provides several methods
 * for checking user status.
 *
 * @author Pavel Kacer <pkacer@suse.com>
 */
class User {

  const DEFAULT_ROLE = 'user';
  const ROLE_SESSION_NAMESPACE = 'roles';

  private $login;
  private $name;
  private $email;
  private $currentRole;
  private $config;

  private function __construct ($config, $login, $name, $email, $role) {
    $this->config = $config;
    $this->login = $login;
    $this->name = $name;
    $this->email = $email;
    $this->currentRole = $role;
  }

  private static function getDbName ($ident, $config) {
    $db = Zend_Db::factory ($config->database);
    if ( isset ($ident) )
      $res = $db->fetchAll ('SELECT name FROM `user` WHERE user_login = ?', $ident);

    $db->closeConnection ();
    return isset ($res[0]['name']) ? $res[0]['name'] : NULL;
  }

  private static function getDbEmail ($ident, $config) {
    $db = Zend_Db::factory ($config->database);
    if ( isset ($ident) )
      $res = $db->fetchAll ('SELECT email FROM `user` WHERE user_login = ?', $ident);

    $db->closeConnection ();
    return isset ($res[0]['email']) ? $res[0]['email'] : NULL;
  }

  /**
   *
   */
  private function setDbName ($ident, $newName) {
    $db = Zend_Db::factory ($this->config->database);
    $ident = $db->quote ($ident);
    $name = $db->quote ($newName);
    $data = array ( 'name' => $newName );
    if ( isset ($ident) ) {
      $res = $db->update ('user', $data, 'user_login = ' . $ident);
    }
    $db->closeConnection ();
    return $res;
  }

  /**
   *
   */
  private function setDbEmail ($ident, $newEmail) {
    $db = Zend_Db::factory ($this->config->database);
    $ident = $db->quote ($ident);
    $data = array ( 'email' => $newEmail );
    if ( isset ($ident) ) {
      $res = $db->update ('user', $data, 'user_login = ' . $ident);
    }
    $db->closeConnection ();
    return $res;
  }

  private function setDbPassword ($ident, $newPassword) {
    $db = Zend_Db::factory ($this->config->database);
    $data = array ( 'password' => $newPassword );
    if ( isset ($ident) ) {
      $res = $db->update ('user', $data, 'user_login = '
                          . $db-quote ( htmlspecialchars ($ident) ) );
    }
    $db->closeConnection ();
    return $res;
  }

  /**
   * getCachedOrDefaultRole
   *
   * Returns role name that this user has cached or default role name
   * if no role name is cached.
   *
   * @return string Role name.
   */
  private static function getCachedOrDefaultRole() {
    $ns = new Zend_Session_Namespace (self::ROLE_SESSION_NAMESPACE);
    if ( isset($ns->curRole) ) {
      return $ns->curRole;
    } else {
      return self::DEFAULT_ROLE;
    }
  }

  /**
   * Returns an instance of *registered* and currently loggend in
   * user.
   *
   * @param Zend_Config  Instance of Zend_Config class.
   */
  public static function getInstance ($config) {
    $ident = self::getIdent ();
    return self::isRegistered ($ident, $config)
      ? new User ( $config, $ident,
                   self::getDbName ($ident, $config),
                   self::getDbEmail ($ident, $config),
                   UserRole::getByName(self::getCachedOrDefaultRole(), $config) )
      : null;
  }

  /**
   * Returns an instance of *registered* user by login.
   *
   * @param login Login name of the user.
   * @param config Object of type Zend_Config.
   */
  public static function getByLogin($login, $config) {
    return self::isRegistered ($login, $config)
      ? new User ($config,
                  $login,
                  User::getDbName($login, $config),
                  User::getDbEmail($login, $config),
                  UserRole::getByName(self::getCachedOrDefaultRole(), $config) )
      : null;
  }

  /**
   * Returns an instance of *registered* user by id.
   *
   * @param id Id of user (number).
   * @param config Object of type Zend_Config.
   */
  public static function getById($id, $config) {
    // TODO get login of this $id
    return self::isRegistered ($login, $config)
      ? new User ($config,
                  $login,
                  User::getDbName($login, $config),
                  User::getDbEmail($login, $config),
                  UserRole::getByName(self::getCachedOrDefaultRole(), $config) )
      : null;
  }

  /**
   * Authenticates this user using method set in configuration.
   *
   * @param
   *   $config   Object of type Zend_Config.
   */
  public static function authenticate ($config) {

    $auth = Authenticator::getInstance ();
    if ($auth->hasIdentity ()) {
      if ( isset($_GET['action'])
           && $_GET['action'] == "logout" ) {
        self::logout ();
        return TRUE;
      }
    }

    switch ($config->authentication->method) {
    case 'password':
      if ( isset ($_POST['action'])
           && $_POST['action'] == 'Login') {
        $login = isset ($_POST['login']) ? $_POST['login'] : '';
        $password = isset ($_POST['password']) ? $_POST['password'] : '';
        if ( ! ( empty($login) || empty ($password) ) ) {
          Authenticator::password ($login, $password, $config);
        } else {
          $_SESSION['mtype'] = 'failure';
          $_SESSION['message'] = 'Please fill in your credentials.';
        }
      }
      break;
    case 'openid':
      Authenticator::openid ($config);
      if ( self::isLogged () ) {
        if ( ! self::isRegistered (self::getIdent(), $config)) {
        
          if ( isset ($_GET['openid_sreg_fullname']) ) {
            $_SESSION['user_name'] = $_GET['openid_sreg_fullname'];
          }

          if ( isset ($_GET['openid_sreg_email']) ) {
            $_SESSION['user_email'] = $_GET['openid_sreg_email'];
          }

          if ( ! isset ($_GET['go'])
               || (isset ($_GET['go']) && $_GET['go'] != 'register') ) {
            header ('Location: index.php?go=register');
          }
        } else if ( self::isRegistered (self::getIdent(), $config) ) {
          $dbName = self::getDbName(self::getIdent(), $config);
          $dbEmail = self::getDbEmail(self::getIdent(), $config);

          if ( ! isset ($dbName) || empty ($dbName)
               || ! isset ($dbEmail) || empty($dbEmail) ) {
            if ( ! isset ($_GET['go'])
                 || (isset ($_GET['go']) && $_GET['go'] != 'register') ) {
              header ('Location: index.php?go=register');
            }
          }
        }
      }
      break;
    default:
      /* If no or invalid authentication type is set, there is no
       * authentication possible. */
    }
  }

  public static function logout () {
    Authenticator::logout ();
  }

  public static function isLogged () {
    $auth = Authenticator::getInstance ();
    return $auth->hasIdentity ();
  }

  public static function getIdent () {
    $auth = Authenticator::getInstance ();
    return $auth->getIdentity ();
  }

  public static function printStatus ($config) {
    $ident = self::getIdent();
    if ( self::isLogged () ) {
      if ( self::isRegistered ($ident, $config) ) {
        $outName = self::getDbName ($ident, $config);
        if ( ! isset ($outName) || empty ($outName) ) {
            $outName = $ident;
        }
      } else {
        $outName = $ident;
      }
      
      echo ('Logged in as <a href="index.php?go=user">' . $outName . "</a>");
    }
  }

  public static function printLogInOut ($form = false) {
    if ( self::isLogged () ) {
      echo ('<a href="index.php?action=logout">Logout</a>' . "\n");
    } else {
      if ($form) {
        echo ('<a href="index.php?go=login">Login</a>' . "\n");
      } else {
        echo ('<a href="index.php?action=login">Login</a>' . "\n");
      }
    }
  }

  /**
   * add_user
   *
   * Adds a user to the database.
   *
   * @param string login (e.g. openid url or login)
   * @param string name User's name
   * @param string email User's email address
   *
   * @return integer Number greater than zero if user has been added, zero otherwise.
   */
  public static function addUser ($login, $name, $email, $config) {
    $db = Zend_Db::factory ($config->database);
    $data = Array (
                   'user_login' => $login,
                   'name' => $name,
                   'email' => $email
                   );
    $added = $db->insert ('user', $data);
    if ($added > 0) {
      $user = User::getByLogin ($login, $config);
      $defRole = UserRole::getByName(self::DEFAULT_ROLE, $config);
      if ( isset ($defRole) ) {
        $defRole->addUser ($user);
      }
    }

    return $added;
  }

  public static function isRegistered ($login, $config) {
    $auth = Authenticator::getInstance ();
    $identity = $auth->getIdentity ();
    $db = Zend_Db::factory ($config->database);
    $res = $db->fetchAll ('SELECT user_login FROM user WHERE user_login = ?', $identity);
    $db->closeConnection ();
    return isset ($res[0]['user_login']);
  }
  
  /**
   * getName
   *
   * Returns name of this user.
   * 
   * @return User name
   */
  public function getName () {
    return $this->name;
  }

  /**
   * getEmail
   *
   * Returns email of this user.
   *
   * @return User email
   */
  public function getEmail () {
    return $this->email;
  }

  /**
   * getLogin
   *
   * Returns login of this user.
   *
   * @return User login (e.g. OpenId)
   */
  public function getLogin() {
    return $this->login;
  }

  public function setName ($name) {
    if ( $this->setDbName ($this->login, $name) ) {
      $this->name = $name;
      return true;
    } else {
      return false;
    }
  }

  public function setEmail ($email) {
    if ( $this->setDbEmail ($this->login, $email) ) {
      $this->email = $email;
      return true;
    } else {
      return false;
    }
  }

  public function setPassword ($password) {
    return $this->setDbPassword ($this->login, $password);
  }

  public function getCurrentRole () {
    return $this->currentRole;
  }

  /**
   * setRole
   *
   * Set current role of this user to roleName.
   *
   * @param roleName Name of new role.
   *
   * @return True if change was succesfull, false otherwise.
   */
  public function setRole ($roleName) {
    if ( ! $this->isInRole($roleName)
         && $this->couldBeInRole ($roleName)) {
      $newRole = UserRole::getByName($roleName, $this->config);
      if ( isset($newRole) ) {
        $ns = new Zend_Session_Namespace (self::ROLE_SESSION_NAMESPACE);
        $ns->curRole = $roleName;
        $this->currentRole = $newRole;
        return true;
      }
    }
    return false;
  }

  /**
   * isInRole
   *
   * Returns comparison of current role name with provided roleName
   * parameter.
   *
   * @param roleName String name of the role to compare.
   *
   * @return True if user is in role with the same name as in
   * parameter.
   */
  public function isInRole ($roleName) {
    return $this->getCurrentRole ()->getName () == $roleName;
  }

  public function couldBeInRole($roleName) {
    return in_array ($roleName, $this->getRoleList ());
  }

  /**
   * getRoleList
   *
   * @return Array List of roles this user is cast in.
   */
  public function getRoleList () {
    $db = Zend_Db::factory ($this->config->database);
    $sql = 'SELECT role FROM user NATURAL JOIN user_in_role NATURAL JOIN user_role WHERE user_login = ?';
    $res = $db->fetchCol ($sql, $this->login);
    $db->closeConnection ();
    return $res;
  }

}

?>
