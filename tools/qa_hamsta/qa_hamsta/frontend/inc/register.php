<?php
/* ****************************************************************************
  Copyright (c) 2013 Unpublished Work of SUSE. All Rights Reserved.

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

  /**
   * Logic of the register page
   */
if(!defined('HAMSTA_FRONTEND')) {
  $go = 'register';
  return require("index.php");
 }
$html_title = "Register";

$user_name = isset ($_SESSION['fullname']) ? $_SESSION['fullname'] : '';
$user_email = isset ($_SESSION['email']) ? $_SESSION['email'] : '';
unset ($_SESSION['fullname']);
unset ($_SESSION['email']);
$login = substr (strrchr (User::getIdent (), "/"), 1);

/* In case the Provider sent us *both* user full name and
 * email, we can use these to add user directly into our DB.
 *
 * If that is not the case use the data to pre-fill the
 * registration form (see in html/register.php).
 */
if ( User::isLogged()
     && ! User::isRegistered(User::getIdent(), $config)
     && ! empty ($user_name)
     && ! empty ($user_email) ) {
  /* With OpenId we have to parse user login to add it as well.
   * That usually means the last part of OpenId url.  */
  if ( ! empty ($login) )
    {
      error_log ('Going to register "' . User::getIdent () . '" as a new user.');
      $result = User::addUser (User::getIdent(), $login, $user_name, $user_email, $config);
      if ($result)
	{
          Notificator::setSuccessMessage ('You have been successfuly registered into Hamsta. Please set your password on configuration page.');
	  header ('Location: index.php');
	}
      else
	{
	  User::logout ();
	  error_log ('Can not register user "' . $login . '" to Hamsta.');
	  Notificator::setErrorMessage ('Sorry, you can not be registered now. Contact your administrator.');
	  header ('Location: index.php');
	}
    }
  else
    {
      User::logout ();
      error_log ('The identifier "' . User::getIdent () . '" is not valid OpenId identifier for Hamsta.');
      Notificator::setErrorMessage ('Your identifier is not valid OpenId identifier for Hamsta.');
      header ('Location: index.php?go=register');
    }
  exit ();
}

if ( request_str("submit") && User::isLogged() ) {
  $name = isset ($_POST['name']) ? $_POST['name'] : '';
  $email = isset ($_POST['email']) ? $_POST['email'] : '';

  if ( empty($name) || empty($email) ) {
    Notificator::setErrorMessage ('Fill in the form, please.');
    header('Location: index.php?go=register');
    exit();
  }

  /* Submit registration data to database.*/
  if ( ! User::isRegistered(User::getIdent(), $config) ) {
    error_log ('Going to add user "' . User::getIdent() . '" in the database.');
    if (User::addUser(User::getIdent(), $login, $name, $email, $config)) {
      Notificator::setSuccessMessage ('Registration was successful.');
    } else {
      Notificator::setErrorMessage ('There has been a registration error. Please try to log out and log in again or contact your administrator.');
      error_log ('The user "' . User::getIdent () . '" cannot not be added to database.');
    }
  } else {
    $user = User::getById (User::getIdent (), $config);
    $user->setName($name);
    $user->setEmail($email);
    Notificator::setSuccessMessage ('Successfully updated registration information.');
    header ('Location: index.php?go=user');
  }
} elseif (! User::isLogged ())  {
  Notificator::setErrorMessage ('You cannot register without being logged in.');
  header ('Location: index.php');
  exit ();
}

?>
