<?php

require_once ('Zend/Auth.php');
require_once ('Zend/Auth/Adapter/OpenId.php');
require_once ('Zend/Auth/Adapter/DbTable.php');
/* Required only for password authentication */
require_once ('Zend/Db.php');

/**
 * Class serves as wrapper around Zend_Auth class.
 *
 * Provides methods for different types of authentication and logout
 * procedures.
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
class Authenticator extends Zend_Auth
{

  /**
   * Authenticates user using OpenID.
   * 
   * Uses Zend_Config for database connection.
   *
   * @param Zend_Config $config Instance of class Zend_Config.
   *
   * @return boolean True if succeded, false otherwise.
   */
  public static function openid($config) {

    $auth = parent::getInstance();

    if ((isset($_GET['action'])
         && $_GET['action'] == "login")
        || isset($_GET['openid_mode'])
        || isset($_POST['openid_mode'])) {

      if ( isset ($_GET['action'])
           && $_GET['action'] == 'logout') {
        self::logout();
      } else {
        if ( isset($_GET['openid_identity'] ) ) {
          $adapter = new Zend_Auth_Adapter_OpenId();
        } else {
          $adapter = new Zend_Auth_Adapter_OpenId($config->authentication->openid->url);
        }

        $result = $auth->authenticate($adapter);

        if ( ! isset($_GET['action'])
             && ! $result->isValid() ) {
          $auth->clearIdentity();
          Zend_Session::destroy(true);
          Zend_Session::forgetMe();
          foreach ($result->getMessages() as $message) {
            echo ("$message<br />\n");
          }
          return false;
        } else {
          return true;
          header ('Location: index.php');
        }
      }
    }
  }

  /**
   * Authenticates user using password.
   *
   * Uses Zend_Config for database connection.
   *
   * @param string $login Login name of the user.
   * @param string $password Password of the user.
   * @param Zend_Config $config Instance of the class Zend_Config.
   */
  public static function password($login, $password, $config) {
    $auth = parent::getInstance();
    $db = Zend_Db::factory($config->database);
    $adapter = new Zend_Auth_Adapter_DbTable($db, 'user', 'user_login', 'password', null);
    $adapter->setIdentity($login);
    $adapter->setCredential($password);
    $result = $auth->authenticate($adapter);

    if ( ! $result->isValid() ) {
      $auth->clearIdentity();
      /* DEBUG
       foreach ($result->getMessages() as $message) {
       echo ("$message<br />\n");
       }
      */
      $_SESSION['mtype'] = 'failure';
      $_SESSION['message'] = 'Login attempt has failed. Check your credentials.';
    } else {
      header ('Location: index.php');
    }
  }

  /**
   * Logs the user out of the application.
   *
   * Destroys the current sesion if the user is logged in. It will not
   * do anything if the user is not logged in.
   *
   */
  public static function logout() {
    $auth = parent::getInstance();
    if ($auth->hasIdentity()) {
      if (isset($_GET['action']) &&
          $_GET['action'] == 'logout') {
        $auth->clearIdentity();
        Zend_Session::destroy(true);
        Zend_Session::forgetMe();
        header('Location: index.php');
      }
    }
  }

}

?>
