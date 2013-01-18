<?php

require_once ('Zend/Db.php');
require_once ('Zend/Session.php');

require_once ('Notificator.php');
require_once ('../frontenduser/Authenticator.php');

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

  /** @var int User id in the database. */
  private $user_id;
  /** @var string External login string (e.g. OpenId url). */
  private $extern_id;
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
  /** @var string[] List of role names this user is cast in. */
  private $userRoles = null;

  /**
   * Creates new instance.
   *
   * @param \Zend_Config $config Application configuration.
   * @param int $user_id Id of the user in database.
   * @param string $extern_id External identifier of the user (e.g. OpenId).
   * @param string $login Login of the user.
   * @param string $name Full name of the user.
   * @param string $email E-mail of the user.
   * @param \UserRole $role Role to set for the user.
   */
  private function __construct ( $config, $user_id,
                                 $extern_id, $login,
                                 $name, $email,
                                 $role)
  {
    $this->config = $config;
    $this->user_id = $user_id;
    $this->extern_id = $extern_id;
    $this->login = $login;
    $this->name = $name;
    $this->email = $email;
    $this->currentRole = $role;
    $this->userRoles = $this->getRoleList ();
  }

  /**
   * Get name of the user from database.
   *
   * @param string $ident Login identification of the user.
   * @param \Zend_Config $config Instance of the application configuration.
   *
   * @return mixed Name of the user if found or NULL.
   */
  private static function getDbName ($ident, $config)
  {
    try
      {
        $db = Zend_Db::factory ($config->database);
        if ( isset ($ident) )
          $res = $db->fetchAll ('SELECT name FROM `user` WHERE login = ?', $ident);

        $db->closeConnection ();
        return isset ($res[0]['name']) ? $res[0]['name'] : null;
      }
    catch (Zend_Db_Exception $e)
      {
        return null;
      }
  }

  /**
   * Get email of the user from database.
   *
   * @param string $ident Login identification of the user.
   * @param \Zend_Config $config Instance of the application configuration.
   *
   * @return mixed Email of the user if found or NULL.
   */
  private static function getDbEmail ($ident, $config)
  {
    try
      {
        $db = Zend_Db::factory ($config->database);
        if ( isset ($ident) )
          $res = $db->fetchAll ('SELECT email FROM `user` WHERE login = ?', $ident);
        
        $db->closeConnection ();
        return isset ($res[0]['email']) ? $res[0]['email'] : null;
      }
    catch (Zend_Db_Exception $e)
      {
        return null;
      }
  }

  /**
   * Get user password from database.
   *
   * @param string $ident Login identification of the user.
   * @param \Zend_Config $config Instance of the application configuration.
   *
   * @return mixed Password in hexa string hash of the user if found or null.
   */
  public function getPassword ()
  {
    try
      {
        $db = Zend_Db::factory ($this->config->database);
	$res = $db->fetchAll ('SELECT password FROM `user` WHERE login = ?', $this->getLogin ());
        $db->closeConnection ();
        return isset ($res[0]['password']) ? $res[0]['password'] : null;
      }
    catch (Zend_Db_Exception $e)
      {
        return null;
      }
  }

  /**
   * Set name of the user in the database.
   *
   * @param string $ident Login identification of the user.
   * @param string $newName Name to be set.
   *
   * @return integer Number greater than zero on success, zero otherwise.
   */
  private function setDbName ($ident, $newName)
  {
    try
      {
        $db = Zend_Db::factory ($this->config->database);
        $ident = $db->quote ($ident);
        $name = $db->quote ($newName);
        $data = array ( 'name' => $newName );
        if ( isset ($ident) ) {
          $res = $db->update ('user', $data, 'login = ' . $ident);
        }
        $db->closeConnection ();
        return $res;
      }
    catch (Zend_Db_Exception $e)
      {
        return 0;
      }
  }

  /**
   * Set email of the user in the database.
   *
   * @param string $ident Login identification of the user.
   * @param string $newEmail E-mail to be set.
   *
   * @return integer Number greater than zero on success, zero otherwise.
   */
  private function setDbEmail ($ident, $newEmail)
  {
    try
      {
        $db = Zend_Db::factory ($this->config->database);
        $ident = $db->quote ($ident);
        $data = array ( 'email' => $newEmail );
        if ( isset ($ident) ) {
          $res = $db->update ('user', $data, 'login = ' . $ident);
        }
        $db->closeConnection ();
        return $res;
      }
    catch (Zend_Db_Exception $e)
      {
        return 0;
      }
  }

  /**
   * Set password of the user in the database.
   *
   * @param string $ident Login identification of the user.
   * @param string $newPassword Plain string password. It will be hashed on the insertion into DB.
   *
   * @return integer Number greater than zero on success, zero otherwise.
   */
  private function setDbPassword ($ident, $newPassword)
  {
    try
      {
        $db = Zend_Db::factory ($this->config->database);
        $stmt = $db->query ('UPDATE user SET password = SHA1(?) WHERE login = ?',
                            Array ($newPassword, $ident));
        $res = $stmt->execute();
        $db->closeConnection ();
        return $res;
      }
    catch (Zend_Db_Exception $e)
      {
        return 0;
      }
  }

  /**
   * Returns role name that this user has cached.
   *
   * Default role name is returned, if no role name is cached. The
   * cached role name is stored in session.
   *
   * @return string Cached role name or ROLE_SESSION_NAMESPACE.
   */
  private static function getCachedOrDefaultRole ()
  {
    try
      {
        $ns = new Zend_Session_Namespace (self::ROLE_SESSION_NAMESPACE);
        if ( isset($ns->curRole) )
          {
            return $ns->curRole;
          }
        else
          {
            return self::DEFAULT_ROLE;
          }
      }
    catch (Zend_Session_Exception $e)
      {
        return self::DEFAULT_ROLE;
      }
  }

  /**
   * Returns some of the fields of the user.
   *
   * It should return one user or null in all cases. Access to the
   * result fields is like e.g. $res[0]['login']. Returned fields are
   * 'user_id', 'extern_id', 'login', 'name' and 'email'.
   * 
   * @param \Zend_Config $config Instance of the Zend_Config class.
   * @param string $login Login of the user to the application.
   * @param string $extern_id External authentication identifier (e.g. OpenId).
   * @param int $id Database id of the user record.
   *
   * @return string[][]|null Array of hashes or null if no user was
   * found.
   */
  private static function getUserFields ($config, $login = null, $extern_id = null, $id = null)
  {
    $sql = 'SELECT user_id, extern_id, login, name, email FROM `user` WHERE ';
    $identifier = null;
    if (isset ($login))
      {
        $sql .= 'login = ?';
        $identifier = $login;
      }
    else if (isset ($extern_id))
      {
        $sql .= 'extern_id = ?';
        $identifier = $extern_id;
      }
    else if (isset ($id))
      {
	$sql .= 'user_id = ?';
	$identifier = $id;
      }
    else
      {
        return null;
      }

    try
      {
        $db = Zend_Db::factory ($config->database);
        $res = $db->fetchAll ($sql, $identifier);
        $db->closeConnection ();
        return (isset ($res[0])) ? $res : null;
      }
    catch (Zend_Db_Exception $e)
      {
        return null;
      }
  }

  /**
   * Returns an instance of <b>registered</b> user by login.
   *
   * @param string $login Login name of the user.
   * @param \Zend_Config $config Object of type Zend_Config.
   *
   * @return \User|null Returns the user if she is registered.
   */
  public static function getByLogin ($login, $config)
  {
    $user_fields = self::getUserFields ($config, $login, null, null);

    if (isset ($user_fields))
      {
        return new User ( $config,
                          $user_fields[0]['user_id'],
                          $user_fields[0]['extern_id'],
                          $user_fields[0]['login'],
                          $user_fields[0]['name'],
                          $user_fields[0]['email'],
                          UserRole::getByName (self::getCachedOrDefaultRole(), $config) );
      }
    return null;
  }

  /**
   * Returns an instance of <b>registered</b> user by external id.
   *
   * @param int $id Id of user. Can be either login for password identification or 
   * @param \Zend_Config $config Application configuration.
   * 
   * @return \User|null Returns the user if she is registered.
   */
  public static function getById ($id, $config)
  {
    if (is_numeric ($id))
      {
	$user_fields = self::getUserFields ($config, null, null, $id);
      }
    else
      {
	switch ($config->authentication->method)
	  {
	  case "openid":
	    $user_fields = self::getUserFields ($config, null, $id, null);
	    break;
	  case "password":
	    $user_fields = self::getUserFields ($config, $id, null, null);
	    break;
	  default:
	    return null;
	  }
      }

    if (isset ($user_fields))
      {
        return new User ( $config,
                          $user_fields[0]['user_id'],
                          $user_fields[0]['extern_id'],
                          $user_fields[0]['login'],
                          $user_fields[0]['name'],
                          $user_fields[0]['email'],
                          UserRole::getByName (self::getCachedOrDefaultRole(), $config) );
      }
    return null;
  }

  /**
   * Authenticates this user using method set in configuration.
   *
   * @param \Zend_Config $config Application configuration.
   */
  public static function authenticate ($config)
  {
    $auth = Authenticator::getInstance ();
    if ($auth->hasIdentity ())
      {
        if ( isset($_GET['action'])
             && $_GET['action'] == "logout" )
          {
            self::logout ();
            return true;
          }
      }

    switch ($config->authentication->method)
      {
      case 'password':
        if ( isset ($_POST['action'])
             && $_POST['action'] == 'Login')
          {
            $login = isset ($_POST['login']) ? $_POST['login'] : '';
            $password = isset ($_POST['password']) ? $_POST['password'] : '';
            if ( empty($login) || empty ($password) )
              {
                Notificator::setErrorMessage ('Please fill in your credentials.');
              }
	    else
              {
                $res = Authenticator::password ($login, $password, $config);
		if ($res)
		  {
		    header ('Location: index.php');
		  }
		else
		  {
		    Notificator::setErrorMessage ('Login attempt has failed. Check your credentials.');
		  }
              }
          }
        break;
      case 'openid':
	if (self::isLogged ())
	  {
	    /* If the user is logging in for the first time he has to
	     * be registered in the database.
	     *
	     * If there is enough data from the OpenId provider, try
	     * to register automatically. Otherwise the user has to
	     * fill out the registration form. */
            if (! self::isRegistered (self::getIdent(), $config))
              {
		error_log ('Going to register new user "' . User::getIdent () . '".');

                if (! isset ($_GET['go']) || $_GET['go'] != 'register')
                  {
                    header ('Location: index.php?go=register');
		    exit ();
                  }
              }
            else if ( self::isRegistered (self::getIdent(), $config) )
              {
		/* Check if all data of the user are consistent. It
		 * can change any time during the application use. */
                $user = User::getById (self::getIdent (), $config);
                $dbName = $user->getName ();
                $dbEmail = $user->getEmail ();

                if ( ! isset ($dbName) || empty ($dbName)
                     || ! isset ($dbEmail) || empty($dbEmail)
		     && ( ! isset ($_GET['go'])
			  || $_GET['go'] != 'register') )
		  {
		    header ('Location: index.php?go=register');
		  }
              }
	  }
	elseif (isset ($_GET['action']) && $_GET['action'] == 'login'
	    || isset ($_GET['openid_mode']) && $_GET['openid_mode'] == 'id_res')
	  {
	    $res = Authenticator::openid ($config->authentication->openid->url);
	    /* Store user data in the session for registration. */
	    if (isset ($_GET['openid_sreg_fullname']))
	      {
		$_SESSION['user_name'] = $_GET['openid_sreg_fullname'];
	      }

	    if (isset ($_GET['openid_sreg_email']))
	      {
		$_SESSION['user_email'] = $_GET['openid_sreg_email'];
	      }
	    header ('Location: index.php');
	    exit ();
	  }
	elseif (isset ($_GET['openid_mode']) && $_GET['openid_mode'] != 'id_res'
		&& ! self::isLogged ())
	  {
	    self::logout ();
	    error_log ('OpenId user authentication failed. The OpenId provider has not sent openid_mode="id_res"');
	    Notificator::setErrorMessage ('Your OpenId provider has denied to authorize you. The provider URL is "' . $config->authentication->openid->url . '".');
	    header ('Location: index.php');
	    exit ();
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
  public static function logout ()
  {
    if (self::isLogged ()
	&& isset($_GET['action'])
	&& $_GET['action'] == 'logout') {
      Authenticator::logout ();
      header ('Location: index.php');
    }
  }

  /**
   * Returns the logged status of this user.
   *
   * @return boolean True if logged in. False otherwise.
   */
  public static function isLogged ()
  {
    $auth = Authenticator::getInstance ();
    return $auth->hasIdentity ();
  }

  /**
   * Returns identity of this user that is used for authentication.
   *
   * For OpenId returns OpenId url and for password authentication
   * uses login from database.
   *
   * @return string Login identification.
   */
  public static function getIdent ()
  {
    return Authenticator::getInstance ()->getIdentity ();
  }

  /**
   * Prints user status.
   *
   * Prints message displaying user status with clickable user name
   * and role redirecting to user configuration page. If the she is
   * not logged in the message is not printed.
   *
   * @param \Zend_Config $config Application configuration.
   */
  public static function printStatus ($config)
  {
    if ( self::isLogged () )
      {
        $ident = self::getIdent();
	$registered = self::isRegistered ($ident, $config);
        if ( $registered )
          {
            $user = self::getById ($ident, $config);
            $outName = $user->getName ();
            if ( ! isset ($outName) || empty ($outName) ) {
              $outName = $ident;
            }
            $outRoleName = $user->getCurrentRole ()->getName ();
          }
        else
          {
            $outName = $ident;
          }
      
        echo ("Logged in as <a class=\"bold\" href=\"index.php?go=user\">"
              . $outName . "</a>"
              . (($registered && count ($user->getRoleList ()) > 1)
                 ? ("(<a href=\"index.php?go=user\">" . $outRoleName
                    . "</a>)")
                 : "")
              . "\n");
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
  public static function printLogInOut ($form = false)
  {
    if ( self::isLogged () )
      {
        echo ('<a href="index.php?action=logout">Logout</a>' . "\n");
      }
    else
      {
        if ($form)
          {
            echo ('<a href="index.php?go=login">Log in</a>' . "\n");
          }
        else
          {
            echo ('<a href="index.php?action=login">Log in</a>' . "\n");
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
  public static function addUser ($extern_id, $login, $name, $email, $config)
  {
    $db = Zend_Db::factory ($config->database);
    $data = Array (
                   'extern_id' => $extern_id,
                   'login' => $login,
                   'name' => $name,
                   'email' => $email
                   );
    $added = $db->insert ('user', $data);
    if ($added > 0)
      {
        $user = User::getByLogin ($login, $config);
        $defRole = UserRole::getByName (self::DEFAULT_ROLE, $config);
        if ( isset ($defRole) )
          {
            $defRole->addUser ($user);
          }
      }

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
  public static function isRegistered ($ident, $config)
  {
    $db = Zend_Db::factory ($config->database);
    $sql = 'SELECT user_id FROM user WHERE ';

    switch ($config->authentication->method) {
    case "openid":
      $sql .= 'extern_id = ?';
      break;
    case "password":
      $sql .= 'login = ?';
      break;
    default:
      return false;
    }

    $res = $db->fetchAll ($sql, $ident);
    return isset ($res[0]['user_id']);
  }

  public function getId ()
  {
    return $this->user_id;
  }
  
  public function getExternId ()
  {
    return $this->extern_id;
  }

  /**
   * Returns full name of this user.
   *
   * @return string Full user name.
   */
  public function getName ()
  {
    return $this->name;
  }

  /**
   * Returns e-mail of this user.
   *
   * @return string User e-mail.
   */
  public function getEmail ()
  {
    return $this->email;
  }

  /**
   * Returns login identifier of this user.
   *
   * @return string User login.
   */
  public function getLogin()
  {
    return $this->login;
  }

  /**
   * Set new full name for this user.
   *
   * @param string $name New full name for this user.
   * 
   * @return boolean True if name has been changed, false otherwise. 
   */
  public function setName ($name)
  {
    if ( $this->setDbName ($this->login, $name) )
      {
        $this->name = $name;
        return true;
      }
    else
      {
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
  public function setEmail ($email)
  {
    if ( $this->setDbEmail ($this->login, $email) )
      {
        $this->email = $email;
        return true;
      }
    else
      {
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
  public function setPassword ($password)
  {
    return $this->setDbPassword ($this->login, $password);
  }

  /**
   * Return current role of this user.
   *
   * @return \UserRole Current role this user is cast to.
   */
  public function getCurrentRole ()
  {
    return $this->currentRole;
  }

  /**
   * Set current role of this user to roleName.
   *
   * @param string roleName Name of new role.
   *
   * @return True if change was succesfull, false otherwise.
   */
  public function setRole ($roleName)
  {
    if ( ! $this->isInRole($roleName)
         && $this->couldBeInRole ($roleName))
      {
        $newRole = UserRole::getByName($roleName, $this->config);
        if ( isset($newRole) )
          {
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
  public function isInRole ($roleName)
  {
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
  public function couldBeInRole($roleName)
  {
    return in_array ($roleName, $this->getRoleList ());
  }

  /**
   * Return list of roles this user can be cast in.
   *
   * @return string[] List of roles this user can be cast in.
   */
  public function getRoleList ()
  {
    if ( isset ($this->userRoles) )
      {
        return $this->userRoles;
      }
    else
      {
        $db = Zend_Db::factory ($this->config->database);
        $sql = 'SELECT role FROM user NATURAL JOIN user_in_role NATURAL JOIN user_role WHERE login = ?';
        $res = $db->fetchCol ($sql, $this->login);
        $db->closeConnection ();
        return $res;
      }
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

  /**
   * Retrieves a list of all users in database.
   *
   * All users from database are returned. The function does not check
   * anything. If the administrator you changes authentication types
   * and there are users from all those types, you get them all.
   *
   * @return \User[] An array of all users in the database ordered by
   * their logins.
   */
  public static function getAllUsers ($config)
  {
    try {
      $db = Zend_Db::factory ($config->database);
      $sql = 'SELECT login FROM user ORDER BY name';
      $res = $db->fetchCol ($sql);
      $users = Array();
      foreach ($res as $login)
        {
          $users[] = User::getByLogin ($login, $config);
        }
      $db->closeConnection ();
      return $users;
    } catch (Zend_Db_Exception $e) {
      return null;
    }
  }

}

function capable ()
{
        global $config;
        $cap=func_get_args();
        if( !$config->authentication->use )
                return true;
        $ident=User::getIdent();
        if( !User::isLogged() || !User::isRegistered($ident,$config) )
                return false;
        $user=User::getById($ident,$config);
        foreach($cap as $c) {
                if( $user->isAllowed($c) )
                        return true;
        }
        return false;
}

?>