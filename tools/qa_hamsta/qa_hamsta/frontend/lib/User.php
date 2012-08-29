<?php

require_once ('Authenticator.php');
require_once ('Zend/Db.php');

class User {

  private $auth;
  private $login;
  private $name;
  private $email;
  
  private function __construct($login, $name, $email) {
    $this->auth = Authenticator::getInstance();
    $this->login = $login;
    $this->name = $name;
    $this->email = $email;
  }

  private static function getDbName($config) {
    $db = Zend_Db::factory($config->database);
    $ident = self::getIdent();
    if (isset ($ident) )
      $res = $db->fetchAll('SELECT name FROM `user` WHERE user_login = ?', $ident);
    
    return isset ($res[0]['name']) ? $res[0]['name'] : 'unset';
  }

  private static function getDbEmail($config) {
    $db = Zend_Db::factory($config->database);
    $ident = self::getIdent();
    if (isset ($ident) )
      $res = $db->fetchAll('SELECT email FROM `user` WHERE user_login = ?', $ident);
    
    return isset ($res[0]['email']) ? $res[0]['email'] : 'unset';
  }

  private function setDbName($newName, $config) {
    $db = Zend_Db::factory($config->database);
    
    // TODO
  }

  private function setDbEmail($newEmail) {
    // TODO
  }

  private function setDbPassword($newPassword) {
    // TODO
  }
  
  public static function getInstance($config) {
    if ( self::isRegistered($config) ) {
      return new User(self::getIdent($config), self::getDbName($config), self::getDbEmail($config));
    } else {
      return null;
    }
  }
  
  /**
   * Authenticates this user using method set in configuration.
   *
   * @param
   *   $config   Object of type Zend_Config.
   */
  public static function authenticate($config) {

    $auth = Authenticator::getInstance();
    if ($auth->hasIdentity()) {
      if (isset($_GET['action'])
          && $_GET['action'] == "logout") {
        self::logout();
        return TRUE;
      }
    }

    switch ($config->authentication->method) {
    case 'password':
      if ( isset ($_POST['action'])
           && $_POST['action'] == 'Login') {
        $login = isset ($_POST['login']) ? $_POST['login'] : '';
        $password = isset ($_POST['password']) ? $_POST['password'] : '';
        if ( ! (empty($login) || empty ($password)) ) {
          Authenticator::password($login, $password, $config);
        } else {
          $_SESSION['mtype'] = 'failure';
          $_SESSION['message'] = 'Please fill in your credentials.';
        }
      }
      break;
    case 'openid':
      Authenticator::openid($config);
      if ( self::isLogged() && ! self::isRegistered($config) ) {
        header ('Location: index.php?go=register');
      }
      break;
    default:
      Authenticator::openid($config);
      if ( self::isLogged() && ! self::isRegistered($config) ) {
        header ('Location: index.php?go=register');
      }
    }

  }

  public static function logout() {
    Authenticator::logout();
  }
 
  public static function isLogged() {
    $auth = Authenticator::getInstance();
    return $auth->hasIdentity();
  }

  public static function getIdent() {
    $auth = Authenticator::getInstance();
    return $auth->getIdentity();
  }

  public static function printStatus($config) {
    if ( self::isLogged() ) {
      if ( self::isRegistered($config) ) {
        $outName = self::getDbName($config);
      } else {
        $outName = self::getIdent();
      }
      echo ('Logged in as <a href="index.php?go=user">' . $outName . "</a>");
    }
  }

  public static function printLogInOut($form = false) {
    if ( self::isLogged() ) {
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
  public static function addUser($login, $name, $email) {
    $stmt = get_pdo()->prepare('INSERT INTO user (user_login, name, email) VALUES(:login, :name, :email)');
    $stmt->bindParam(':login', $login);
    $stmt->bindParam(':name', $name);
    $stmt->bindParam(':email', $email);
    $stmt->execute();
    // TODO return true if added, false if not
  }

  public static function isRegistered($config) {
    $auth = Authenticator::getInstance();
    $identity = $auth->getIdentity();
    $db = Zend_Db::factory($config->database);
    $res = $db->fetchCol('SELECT user_login FROM user WHERE user_login = ?', $identity);
    return isset ($res);
  }
  
  /**
   * get_name
   *
   * @return User name
   */
  public function getName() {
    return $this->name;
  }

  public function getEmail() {
    return $this->email;
  }

  public function setName() {
    // TODO
  }

  public function setEmail() {
    // TODO
  }

}

?>
