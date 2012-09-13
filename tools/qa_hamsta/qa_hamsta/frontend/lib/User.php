<?php

require_once ('Zend/Db.php');
require_once ('Zend/Session.php');

require_once ('Authenticator.php');
require_once ('Notificator.php');

/**
 * Class represents authenticated user and provides several methods to
 * operate on user.
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
class User {

  /** @var string Default role for the user on login. */
  const DEFAULT_ROLE = 'user';
  /** @var string Namespace for the \Zend_Session_Namespace to save
   * current role in session. */
  const ROLE_SESSION_NAMESPACE = 'roles';

  /** @var string Login name of the user. */
  private $login;
  /** @var string Full name of the user. */
  private $name;
  /** @var string Email of the user. */
  private $email;
  /** @var \UserRole Current role of the user. */
  private $currentRole;
  /** @var \Zend_Config Application configuration. */
  private $config;

  /**
   * Creates new instance.
   *
   * @param \Zend_Config $config Application configuration.
   * @param string $login Login of the user.
   * @param string $name Full name of the user.
   * @param string $email E-mail of the user.
   * @param \UserRole $role Role to set for the user.
   */
  private function __construct ($config, $login, $name, $email, $role) {
    $this->config = $config;
    $this->login = $login;
    $this->name = $name;
    $this->email = $email;
    $this->currentRole = $role;
  }

  /**
   * Get name of the user from database.
   *
   * @param string $ident Login identification of the user.
   * @param \Zend_Config $config Instance of the application configuration.
   *
   * @return mixed Name of the user if found or NULL.
   */
  private static function getDbName ($ident, $config) {
    $db = Zend_Db::factory ($config->database);
    if ( isset ($ident) )
      $res = $db->fetchAll ('SELECT name FROM `user` WHERE user_login = ?', $ident);

    $db->closeConnection ();
    return isset ($res[0]['name']) ? $res[0]['name'] : NULL;
  }

  /**
   * Get email of the user from database.
   *
   * @param string $ident Login identification of the user.
   * @param \Zend_Config $config Instance of the application configuration.
   *
   * @return mixed Email of the user if found or NULL.
   */
  private static function getDbEmail ($ident, $config) {
    $db = Zend_Db::factory ($config->database);
    if ( isset ($ident) )
      $res = $db->fetchAll ('SELECT email FROM `user` WHERE user_login = ?', $ident);

    $db->closeConnection ();
    return isset ($res[0]['email']) ? $res[0]['email'] : NULL;
  }

  /**
   * Set name of the user in the database.
   *
   * @param string $ident Login indentification of the user.
   * @param string $newName Name to be set.
   *
   * @return integer Number greater than zero on success, zero otherwise.
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
   * Set email of the user in the database.
   *
   * @param string $ident Login indentification of the user.
   * @param string $newEmail E-mail to be set.
   *
   * @return integer Number greater than zero on success, zero otherwise.
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

  /**
   * Set password of the user in the database.
   *
   * @param string $ident Login indentification of the user.
   * @param string $newPassword Plain string password. It will be hashed on the insertion into DB.
   *
   * @return integer Number greater than zero on success, zero otherwise.
   */
  private function setDbPassword ($ident, $newPassword) {
    $db = Zend_Db::factory ($this->config->database);
    $stmt = $db->query ('UPDATE user SET password = SHA1(?) WHERE user_login = ?',
                        Array ($newPassword, $ident));
    $res = $stmt->execute();
    $db->closeConnection ();
    return $res;
  }

  /**
   * Returns role name that this user has cached.
   *
   * Default role name is returned, if no role name is cached. The
   * cached role name is stored in session.
   *
   * @return string Cached role name or ROLE_SESSION_NAMESPACE.
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
   * Returns an instance of <b>registered and currently logged in</b>
   * user.
   *
   * @param \Zend_Config $config Application configuration.
   *
   * @return \User|null Returns the user if she is registered.
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
   * Returns an instance of <b>registered</b> user by login.
   *
   * @param string $login Login name of the user.
   * @param \Zend_Config $config Object of type Zend_Config.
   *
   * @return \User|null Returns the user if she is registered.
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
   * Returns an instance of <b>registered</b> user by id.
   *
   * @param string $id Id of user (number).
   * @param \Zend_Config $config Application configuration.
   * 
   * @return \User|null Returns the user if she is registered.
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
   * @param \Zend_Config $config Application configuration.
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
          Notificator::setErrorMessage ('Please fill in your credentials.');
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

  /**
   * Log out the user.
   */
  public static function logout () {
    Authenticator::logout ();
  }

  /**
   * Returns the logged status of this user.
   *
   * @return boolean True if logged in. False otherwise.
   */
  public static function isLogged () {
    $auth = Authenticator::getInstance ();
    return $auth->hasIdentity ();
  }

  /**
   * Returns login identity of this user.
   *
   * @return string Login identification.
   */
  public static function getIdent () {
    $auth = Authenticator::getInstance ();
    return $auth->getIdentity ();
  }

  /**
   * Prints user status.
   *
   * Prints message with user status with clickable user name and role
   * redirecting to user configuration page. If the she is not logged
   * in the message is not printed.
   *
   * @param \Zend_Config $config Application configuration.
   */
  public static function printStatus ($config) {
    if ( self::isLogged () ) {
      $ident = self::getIdent();
      if ( self::isRegistered ($ident, $config) ) {
        $user = self::getByLogin ($ident, $config);
        $outName = $user->getName ();
        if ( ! isset ($outName) || empty ($outName) ) {
            $outName = $ident;
        }
        $outRoleName = $user->getCurrentRole ()->getName ();
      } else {
        $outName = $ident;
      }
      
      echo ("Logged in as <a class=\"bold\" href=\"index.php?go=user\">"
            . $outName
            . "</a> (<a href=\"index.php?go=user\">"
            . $outRoleName
            . "</a>)\n");
    }
  }

  /**
   * Prints login or logout link.
   *
   * If the user is not logged in prints login link. If she is logged
   * in prints logout link.
   *
   * @param boolean $form Set to true if you want to redirect user to
   * login form.
   */
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
   * Adds a user to the database.
   *
   * It is recommended to check if the user is not already registered
   * before calling this method (see isRegistered ()).
   * 
   * @param string $login Login identification of the user (e.g. openid url or login).
   * @param string $name User's name.
   * @param string $email User's e-mail address.
   * @param \Zend_Config $config Application configuration.
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
    $db->closeConnection ();

    return $added;
  }

  /**
   * Checks if the user is registered in Hamsta.
   *
   * It simply asks database if the login is already there.
   *
   * @param string $login Login identification of the user.
   * @param \Zend_Config $config Application configuration.
   */
  public static function isRegistered ($login, $config) {
    $auth = Authenticator::getInstance ();
    $identity = $auth->getIdentity ();
    $db = Zend_Db::factory ($config->database);
    $res = $db->fetchAll ('SELECT user_login FROM user WHERE user_login = ?', $identity);
    $db->closeConnection ();
    return isset ($res[0]['user_login']);
  }
  
  /**
   * Returns full name of this user.
   *
   * @return string Full user name.
   */
  public function getName () {
    return $this->name;
  }

  /**
   * Returns e-mail of this user.
   *
   * @return string User e-mail.
   */
  public function getEmail () {
    return $this->email;
  }

  /**
   * Returns login identifier of this user.
   *
   * @return string User login (e.g. OpenID or login).
   */
  public function getLogin() {
    return $this->login;
  }

  /**
   * Set new full name for this user.
   *
   * @param string $name New full name for this user.
   * 
   * @return boolean True if name has been changed, false otherwise. 
   */
  public function setName ($name) {
    if ( $this->setDbName ($this->login, $name) ) {
      $this->name = $name;
      return true;
    } else {
      return false;
    }
  }

  /**
   * Set new e-mail for this user.
   *
   * @param string $email New user e-mail.
   *
   * @return boolean True if e-mail has been changed, false otherwise.
   */
  public function setEmail ($email) {
    if ( $this->setDbEmail ($this->login, $email) ) {
      $this->email = $email;
      return true;
    } else {
      return false;
    }
  }

  /**
   * Set new user password.
   *
   * @param string $password New user password. Plain text, no
   * hashing.
   *
   * @return integer Number greater than zero on success, zero otherwise.
   */
  public function setPassword ($password) {
    return $this->setDbPassword ($this->login, $password);
  }

  /**
   * Return current role of this user.
   *
   * @return \UserRole Current role this user is cast to.
   */
  public function getCurrentRole () {
    return $this->currentRole;
  }

  /**
   * Set current role of this user to roleName.
   *
   * @param string roleName Name of new role.
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
   * Getter for the current role of this user.
   *
   * @return \UserRole Current role instance of this user. 
   */
  public function getRole ()
  {
    return $this->currentRole;
  }

  /**
   * Returns result of comparison of current role name with provided
   * roleName parameter.
   *
   * @param string $roleName Name of the role to compare.
   *
   * @return boolean True if user is in role with the same name as in
   * parameter.
   */
  public function isInRole ($roleName) {
    return $this->getCurrentRole ()->getName () == $roleName;
  }

  /**
   * Returns true if user can be cast in the role with name provided
   * in parameter roleName.
   *
   * @param string $roleName Name of the role to search.
   *
   * @return boolean True if user can be cast in the role with
   * provided name.
   */
  public function couldBeInRole($roleName) {
    return in_array ($roleName, $this->getRoleList ());
  }

  /**
   * Return list of roles this user can be cast in.
   *
   * @return string[] List of roles this user can be cast in.
   */
  public function getRoleList () {
    $db = Zend_Db::factory ($this->config->database);
    $sql = 'SELECT role FROM user NATURAL JOIN user_in_role NATURAL JOIN user_role WHERE user_login = ?';
    $res = $db->fetchCol ($sql, $this->login);
    $db->closeConnection ();
    return $res;
  }

  /**
   * Checks if the user in current role has Privilege $privilege.
   *
   * @param string $privilege Privilege name.
   *
   * @return boolean True if user in current role has the privilege,
   * false otherwise.
   */
  public function isAllowed ($privilege)
  {
    return $this->getRole ()->isAllowed ($privilege);
  }

}

?>
