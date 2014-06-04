<?php

require_once ('Zend/Db.php');
require_once ('Zend/Session.php');

require_once ('Notificator.php');
require_once ('ConfigFactory.php');
require_once ('Authenticator.php');

/**
 * Class represents authenticated user and provides several methods to
 * operate on user.
 *
 * @package User
 * @author Pavel Kačer <pkacer@suse.com>
 * @version 1.0.0
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
class User {

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
   */
  private function __construct ( $config, $user_id,
                                 $extern_id, $login,
                                 $name, $email)
  {
    $this->config = $config;
    $this->user_id = $user_id;
    $this->extern_id = $extern_id;
    $this->login = $login;
    $this->name = $name;
    $this->email = $email;
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
  public static function getByLogin ($login, $config = null)
  {
	  if (! isset ($config)) {
		  $config = ConfigFactory::build ();
	  }
    $user_fields = self::getUserFields ($config, $login, null, null);

    if (isset ($user_fields))
      {
        return new User ( $config,
                          $user_fields[0]['user_id'],
                          $user_fields[0]['extern_id'],
                          $user_fields[0]['login'],
                          $user_fields[0]['name'],
                          $user_fields[0]['email']);
      }
    return null;
  }

  public static function getByName ($name) {
	  $sql = 'SELECT * FROM `user` WHERE name = ?';
	  $conf = ConfigFactory::build ();
	  try {
		  $db = Zend_Db::factory ($conf->database);
		  $res = $db->fetchAll ($sql, $name);
		  $db->closeConnection ();
		  if (isset ($res[0])) {
			  return new User ($conf,
					   $res[0]['user_id'],
					   $res[0]['extern_id'],
					   $res[0]['login'],
					   $res[0]['name'],
					   $res[0]['email']);
		  }
		  return null;
	  } catch (Zend_Db_Exception $e) {
		  return null;
	  }
  }

  /**
   * Returns an instance of <b>registered</b> user by external id.
   *
   * @param int $id Id of user. Can be either login for password identification or database id.
   * @param \Zend_Config $config Application configuration.
   *
   * @return \User|null Returns the user if she is registered.
   */
  public static function getById ($id, $config = null)
  {
	if (! isset ($config)) {
		$config = ConfigFactory::build ();
	}
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
                          $user_fields[0]['email']);
      }
    return null;
  }

	/**
	 * Get currently logged in and registered user.
	 *
	 * @return User Currently logged in user or null if the user
	 * is not logged in or is not in the database.
	 */
	public static function getCurrent ()
	{
		$conf = ConfigFactory::build ();
		if (User::isLogged ()
		    && User::isRegistered (User::getIdent (), $conf)) {
			return User::getById (User::getIdent ());
		}
		return null;
	}

	/**
	 * Authenticates this user using method set in configuration.
	 */
	public static function authenticate () {
		$config = ConfigFactory::build ();
		$auth = Authenticator::getInstance ();
		if (self::isLogged ()) {
			if (isset($_GET['action'])
			    && $_GET['action'] == "logout" ) {
				self::logout ();
				header ('Location: index.php');
				return true;
			}
		}

		switch ($config->authentication->method) {
		case 'password':
			if (isset ($_POST['action'])
			    && $_POST['action'] == 'Login') {
				$login = isset ($_POST['login']) ? $_POST['login'] : '';
				$password = isset ($_POST['password']) ? $_POST['password'] : '';
				if (empty ($login) || empty ($password)) {
					Notificator::setErrorMessage ('Please fill in your credentials.');
				} else {
					$res = Authenticator::password ($login, $password, $config);
					if ($res) {
						header ('Location: index.php');
					} else {
						Notificator::setErrorMessage ('Login attempt has failed.'
									      . ' Check your credentials.');
					}
				}
			}
			break;
		case 'openid':
			/* Do the OpenID authentication. */
			$res = Authenticator::openid ($config->authentication->openid->url);

			/* User is logged in. */
			if ($res) {
				/* If the user is logging in for the
				 * first time she has to be registered
				 * in the database.
				 *
				 * If there is enough data from the
				 * OpenId provider, try to register
				 * automatically (see the else
				 * clause). Otherwise the user has to
				 * fill out the registration form. */
				if (self::isRegistered (self::getIdent ())) {
					/* Check if all data of the
					 * user are consistent. We
					 * want users to have name and
					 * email values set. */
					$user = User::getCurrent ();
					$dbName = $user->getName ();
					$dbEmail = $user->getEmail ();

					/* We were not able to get the registration data
					 * so the user has to fill out the form
					 * herself. */
					if ((empty ($dbName) || empty ($dbEmail))
					    && @$_GET['go'] != 'register') {
						self::_sendTo ('register');
					} else if (! empty ($_GET['openid_mode'])) {
						/* Go to the index page. Otherwise the GET data
						 * from OpenID provider stay in the URL. */
						self::_sendTo ();
					}
				} else {
					if (is_object ($res)) {
						/* Result stores SREG data from OpenID
						 * provider response or error messages. */
						$msgs = $res->getMessages ();
						if ($res->isValid ()) {
							self::_saveRegistrationData ($msgs);
							self::_sendTo ('register');
						} else {
							Notificator::setErrorMessage (join (' ', $msgs));
							self::_sendTo ();
						}
					}
				}
			}
			break;
		default:
			/* If no or invalid authentication type is
			 * set, no authentication is possible. */
		}
	}

	/**
	 *
	 */
	private static function _saveRegistrationData ($data) {
		foreach ($data as $key=>$val) {
			$_SESSION[$key] = $val;
		}
	}

	private static function _sendTo ($where = '') {
		$header = 'Location: index.php';
		if (! empty ($where)) {
			$header .= '?go=' . $where;
		}
		header ($header);
		exit ();
	}

  /**
   * Log out the user.
   */
  public static function logout ()
  {
    Authenticator::logout ();
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
   * redirecting to user configuration page. If the user is not logged
   * in the message is not printed.
   *
   * @param \Zend_Config $config Application configuration.
   */
  public static function printStatus ($config)
  {
    if ( self::isLogged () )
      {
        $ident = self::getIdent();

        if ( self::isRegistered ($ident, $config) )
          {
            $user = self::getById ($ident, $config);
            $outName = $user->getName ();
            if ( ! isset ($outName) || empty ($outName) ) {
              $outName = $ident;
            }
          }
        else
          {
            $outName = $ident;
          }

        echo ("Logged in as <a class=\"bold\" href=\"index.php?go=user\">"
              . $outName . "</a>\n");
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
   * before calling this method (see isRegistered ()). This method
   * sets the user password to a randomly generated string.
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
    $added = 0;
    $passwd = sha1 (genRandomString (10));
    $db = Zend_Db::factory ($config->database);
    $data = Array ('extern_id' => $extern_id,
                   'login' => $login,
                   'name' => $name,
                   'email' => $email,
		   'password' => $passwd);

    try
      {
	$added = $db->insert ('user', $data);
      }
    catch (Exception $e)
      {
	error_log ('Error adding user to database. Exception message: ' . $e->getMessage ());
      }

    if ($added > 0)
      {
        $user = User::getByLogin ($login, $config);
	/* Cast user to the default role called 'user' if possible. */
        $defRole = UserRole::getByName ('user', $config);
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
	public static function isRegistered ($ident, $config = null) {
		if (! isset ($config)) {
			$config = ConfigFactory::build();
		}
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
   * Returns user name or login if the name is empty.
   *
   * @return string User name if not empty, login otherwise.
   */
  public function getNameOrLogin ()
  {
     $nm = '';
     $nm = $this->getName ();
     if (empty ($nm))
       {
	 $nm = $this->getLogin ();
       }
     return $nm;
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
   * Returns true if user is cast in the role with name provided in
   * parameter roleName.
   *
   * @param string $roleName Name of the role to search.
   *
   * @return boolean True if user is cast in the role having the
   * provided name.
   */
  public function isInRole ($roleName)
  {
	  return in_array ($roleName, $this->getRoleList ());
  }

  public function isAdmin () {
	  return $this->isInRole ('admin');
  }

  /**
   * Return list of roles this user is cast in.
   *
   * @return string[] List of roles this user is cast in.
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
   * Checks if the user has a privilege.
   *
   * @param string $privilege Privilege name.
   *
   * @return integer Zero (0) if the user does not have the
   * privilege. One (1) if the user has the privilege and two (2) if
   * the user has the privilege and the role the privilege was
   * acquired from is 'admin'.
   */
  public function isAllowed ($privilege) {
	  if (! $this->config->authentication->use) {
		  return true;
	  }
	  $role_names = $this->getRoleList ();
	  $allowed = 0;
	  /* Sort them in descending order so admin will be last. */
	  arsort ($role_names);
	  foreach ($role_names as $role_name)
	  {
		  $role = UserRole::getByName ($role_name, $this->config);
		  if ($role->isAllowed ($privilege)) {
			  $allowed = 1;
			  if ($role->getId () == 1
			      || $role->getName () == 'admin') {
				  $allowed = 2;
			  }
			  break;
		  }
	  }
	  return $allowed;
  }

  /**
   * Returns true if user is allowed all privileges in the list.
   *
   * @param array[string] $list_of_privileges List of names of privileges.
   *
   * @return boolean Returns true if user is allowed all privileges,
   * false otherwise.
   */
  public function isAllowedAll ($privilist) {
	  foreach ($privilist as $priv) {
		  if (! $this->isAllowed ($priv)) {
			  return false;
		  }
	  }
	  return true;
  }

  /**
   * Returns non zero value if user is allowed at least one of the
   * privileges.
   *
   * @param array[string] $list_of_privileges List of names of privileges.
   *
   * @return boolean Returns similar to function isAllowed (). Non
   * zero value if user is allowed at least one of the privileges from
   * the list. Returns false otherwise.
   *
   * @see isAllowed()
   */
  public function isAllowedAny ($privilist) {
	  foreach ($privilist as $priv) {
		  $alwd = $this->isAllowed ($priv);
		  if ($alwd) {
			  return $alwd;
		  }
	  }
	  return false;
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
  public static function getAllUsers ($config = null)
  {
	  if (! isset ($config)) {
		  $config = ConfigFactory::build ();
	  }
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

  /**
   * Returns a string representation of this user.
   *
   * @return string A textual representation of the user. Name and
   * login is returned.
   */
  public function __toString ()
  {
    return $this->getName () . ' (' . $this->getLogin () . ')';
  }

  /**
   * Compare with another user.
   *
   * Compares users using ID in the database.
   *
   * @param User $other_user Other user to compare to.
   * @return boolean True if the objects are equal users.
   */
  public function equals ($other_user)
  {
    if (! isset ($other_user))
      {
	return false;
      }
    return $this->getId () == $other_user->getId ();
  }

}

function user_get()
{
	global $config;
	if( !$config->authentication->use )
		return null;
	return User::getCurrent ();
}

function capable ()
{
        global $config,$user;
        $cap=func_get_args();
	# everything allowed when not using authentication
        if( !$config->authentication->use )
                return true;

	# nothing allowed unless logged in
	if( !$user )
		return false;

	# if no capabilities entered, we just check for being logged in
	if( count($cap)==0 )
		return true;

	# need to have at least one of the permissions
	return $user->isAllowedAny ($cap);
}

/**
  * Check for machine's permissions.
  * accepts args:
  * - owner : permission(s) needed for those who own the machine
  * - other : permission(s) required for those who don't own it, and sufficient for those who do; defaults to $owner . '_reserved' if $owner is a single string
  * Returns if permissions are sufficient.
  **/
function machine_permission($machines,$args)
{
	$config = ConfigFactory::build ();
	$user = User::getCurrent ();
	$owner=hash_get($args,'owner',null);
	$other=hash_get($args,'other',null);

	# everything enabled if we don't use configuration
	if( !$config->authentication->use )
		return true;

	# if no permission specified, we assume that user just needs to be logged in
	if( !$owner )
		return ( !is_null($user) );

	# normalize $machines
	$machines=to_array($machines);
	for($i=0; $i<count($machines); $i++ )	{
		if( is_numeric($machines[$i]) )
			$machines[$i] = Machine::get_by_id($machines[$i]);
	}

	foreach( $machines as $machine )	{
		/* If there is no reservation for the machine or there
		 * is reservation for this user, then the machine can
		 * be edited/reserved. */
		$users_machine = false;
		$reserved_machine = false;
		if (isset ($machine))
		{
			$rh = new ReservationsHelper ();
			$reserved_machine = $rh->hasReservation ($machine);
			$users_machine = $rh->hasReservation ($machine, $user);
		}
		$perms=array_merge(to_array($other),
				   ($users_machine
				    || ! $reserved_machine
				    ? to_array($owner) : array()));
		if( ! call_user_func_array('capable',$perms) )
			return false;
	}
	return true;
}

/**
  * Check for machine's permissions and redirects if missing.
  * accepts args:
  * - owner : permission(s) needed for those who own the machine
  * - other : permission(s) required for those who don't own it, and sufficient for those who do; defaults to $owner . '_reserved' if $owner is a single string
  * - url : redirect URL, default 'index.php'
  * Returns if permissions are sufficient.
  **/
function machine_permission_or_redirect($machines,$args=array())
{
	if( !machine_permission( $machines, $args ) )
		redirect( $args );
}

/**
  * Check for machine's permissions and sets 'disabled.css' if missing.
  * accepts args:
  * - owner : permission(s) needed for those who own the machine
  * - other : permission(s) required for those who don't own it, and sufficient for those who do; defaults to $owner . '_reserved' if $owner is a single string
  * - url : redirect URL, default 'index.php'
  * Returns if permissions are sufficient.
  **/
function machine_permission_or_disabled($machines,$args)
{
	$ret = machine_permission ($machines, $args);
	if (! $ret) {
		disable ($args);
	}
	return $ret;
}

$perm_send_job=array('owner'=>'machine_send_job','other'=>'machine_send_job_reserved');

function permission_or_redirect($args=array())
{
	$perms=hash_get($args,'perm',array());
	if( !call_user_func_array('capable',$perms) )
		redirect($args);
}

function permission_or_disabled($args=array())
{
	$perms=hash_get($args,'perm',array());
	if (! is_array ($perms)) {
		$perms = array ($perms);
	}
	if( !call_user_func_array('capable',$perms) )
		disable($args);
}

?>
