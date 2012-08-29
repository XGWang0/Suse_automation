<?php

require_once ('Zend/Auth.php');
require_once ('Zend/Auth/Adapter/OpenId.php');
require_once ('Zend/Auth/Adapter/DbTable.php');
/* Required only for password authentication */
require_once ('Zend/Db.php');

class Authenticator extends Zend_Auth
{

  public static function openid($config) {
  
    $auth = parent::getInstance();

    if ((isset($_GET['action'])
         && $_GET['action'] == "login")
        || isset($_GET['openid_mode'])
        || isset($_POST['openid_mode'])) {

      if ( isset ($_GET['action'])
           && $_GET['action'] == 'logout') {
        $auth->clearIdentity();
        Zend_Session::destroy();    
      } else {
        if ( isset($_GET['openid_identity'] ) ) {
          $adapter = new Zend_Auth_Adapter_OpenId();
        } else {
          $adapter = new Zend_Auth_Adapter_OpenId($config->authentication->openid->url);
        }

        $result = $auth->authenticate($adapter);

        if ( ! $result->isValid() ) {
          $auth->clearIdentity();
          foreach ($result->getMessages() as $message) {
            echo ("$message\n");
          }
        } else {
          header ('Location: index.php');
        }
      }
    }
  }

  public static function password($login, $password, $config) {
    $auth = parent::getInstance();
    $db = Zend_Db::factory($config->database);
    $adapter = new Zend_Auth_Adapter_DbTable($db, 'user', 'user_login', 'password', null);
    $adapter->setIdentity($login);
    $adapter->setCredential($password);
    $result = $auth->authenticate($adapter);

    if ( ! $result->isValid() ) {
      $auth->clearIdentity();
      /*
      foreach ($result->getMessages() as $message) {
        echo ("$message\n");
      }
      */
      $_SESSION['mtype'] = 'failure';
      $_SESSION['message'] = 'Login attempt has failed. Check your credentials.';
    } else {
      header ('Location: index.php');
    }
  }

  public static function logout() {
    $auth = parent::getInstance();
    if ($auth->hasIdentity()) {
      if (isset($_GET['action']) &&
          $_GET['action'] == 'logout') {
        $auth->clearIdentity();
        Zend_Session::destroy();
        header('Location: index.php');
      }
    }
  }

}

?>