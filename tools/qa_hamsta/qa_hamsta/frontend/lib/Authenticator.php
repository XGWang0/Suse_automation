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
        Zend_Session::destroy(true);
        Zend_Session::forgetMe();
        header('Location: index.php');
      }
    }
  }

}

?>
