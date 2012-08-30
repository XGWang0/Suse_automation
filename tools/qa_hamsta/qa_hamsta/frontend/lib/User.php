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

/**
 * Class represents authenticated user and provides several methods
 * for checking user status.
 *
 * @author Pavel Kacer <pkacer@suse.com>
 */
class User {

  private $auth;
  private $login;
  private $name;
  private $email;
  private $config;
 
  private function __construct ($config, $login, $name, $email) {
    $this->auth = Authenticator::getInstance ();
    $this->config = $config;
    $this->login = $login;
    $this->name = $name;
    $this->email = $email;
  }

  private static function getDbName ($config) {
    $db = Zend_Db::factory ($config->database);
    $ident = self::getIdent ();
    if ( isset ($ident) )
      $res = $db->fetchAll ('SELECT name FROM `user` WHERE user_login = ?', $ident);
    
    return isset ($res[0]['name']) ? $res[0]['name'] : 'unset';
  }

  private static function getDbEmail ($config) {
    $db = Zend_Db::factory ($config->database);
    $ident = self::getIdent ();
    if ( isset ($ident) )
      $res = $db->fetchAll ('SELECT email FROM `user` WHERE user_login = ?', $ident);
    
    return isset ($res[0]['email']) ? $res[0]['email'] : 'unset';
  }

  /**
   *
   */
  private function setDbName ($newName) {
    $db = Zend_Db::factory ($this->config->database);
    $ident = self::getIdent ();
    $ident = $db->quote ($ident);
    $name = $db->quote ($newName);
    $data = array ( 'name' => $newName );
    if ( isset ($ident) ) {
      $res = $db->update ('user', $data, 'user_login = ' . $ident);
    }
    return $res;
  }

  private function setDbEmail ($newEmail) {
    $db = Zend_Db::factory ($this->config->database);
    $ident = self::getIdent ();
    $ident = $db->quote ($ident);
    $data = array ( 'email' => $newEmail );
    if ( isset ($ident) ) {
      $res = $db->update ('user', $data, 'user_login = ' . $ident);
    }
    return $res;
  }

  private function setDbPassword ($newPassword) {
    $db = Zend_Db::factory ($this->config->database);
    $ident = self::getIdent ();
    $data = array ( 'name' => $newPassword );
    if ( isset ($ident) ) {
      $res = $db->update ('user', $data, 'user_login = ' . $ident);
    }
  }

  /**
   * Returns an instance of *registered* user. That means only
   * instances of registered users will be returned.
   *
   * @param config  Object of type Zend_Config
   */
  public static function getInstance ($config) {
    return self::isRegistered ($config)
      ? new User ( $config, self::getIdent ($config),
                   self::getDbName ($config),
                   self::getDbEmail ($config) )
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
        if ( ! (empty ($login) || empty ($password)) ) {
          Authenticator::password ($login, $password, $config);
        } else {
          $_SESSION['mtype'] = 'failure';
          $_SESSION['message'] = 'Please fill in your credentials.';
        }
      }
      break;
    case 'openid':
      Authenticator::openid ($config);
      if ( self::isLogged ()
           && ! self::isRegistered ($config)) {
        
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
      }
      break;
    default:
      // User has to set some type of configuration.
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
    if ( self::isLogged () ) {
      if ( self::isRegistered ($config) ) {
        $outName = self::getDbName ($config);
      } else {
        $outName = self::getIdent ();
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
   */
  public static function addUser ($login, $name, $email) {
    $stmt = get_pdo()->prepare('INSERT INTO user (user_login, name, email) VALUES(:login, :name, :email)');
    $stmt->bindParam (':login', $login);
    $stmt->bindParam (':name', $name);
    $stmt->bindParam (':email', $email);
    $stmt->execute ();
    // TODO return true if added, false if not
  }

  public static function isRegistered ($config) {
    $auth = Authenticator::getInstance ();
    $identity = $auth->getIdentity ();
    $db = Zend_Db::factory ($config->database);
    $res = $db->fetchCol ('SELECT user_login FROM user WHERE user_login = ?', $identity);
    return isset ($res);
  }

  /**
   * getName
   *
   * @return User name
   */
  public function getName () {
    return $this->name;
  }

  public function getEmail () {
    return $this->email;
  }

  public function setName () {
    if ( $this->setDbName ($name) ) {
      $this->name = $name;
      return true;
    } else {
      return false;
    }
  }

  public function setEmail () {
    if ( $this->setDbEmail ($email) ) {
      $this->email = $email;
      return true;
    } else {
      return false;
    }
  }

  public function setPassword ($password) {
    // TODO finish
    return true;
  }

}

?>
