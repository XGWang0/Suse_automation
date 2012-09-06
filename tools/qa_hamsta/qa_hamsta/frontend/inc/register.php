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

  /**
   * Logic of the register page
   */
if(!defined('HAMSTA_FRONTEND')) {
  $go = 'register';
  return require("index.php");
 }
$html_title = "Register";

$user_name = isset ($_SESSION['user_name']) ? $_SESSION['user_name'] : '';
$user_email = isset ($_SESSION['user_email']) ? $_SESSION['user_email'] : '';
unset ($_SESSION['user_name']);
unset ($_SESSION['user_email']);

/* In case the Provider sent us *both* user full name and
 * email, we can use these to add user directly into our DB.
 *
 * If that is not the case use the data to pre-fill the
 * registration form (see in html).
 */
if ( User::isLogged()
     && ! User::isRegistered(User::getIdent(), $config)
     && ! empty ($user_name)
     && ! empty ($user_email) ) {
  User::addUser (User::getIdent(), $user_name, $user_email, $config);
  $_SESSION['mtype'] = 'success';
  $_SESSION['message'] = 'You have been successfuly registered into Hamsta.';
  header ('Location: index.php');
}

if ( request_str("submit")
     && User::isLogged() ) {
  $name = isset ($_POST['name']) ? $_POST['name'] : '';
  $email = isset ($_POST['email']) ? $_POST['email'] : '';

  if ( empty($name) || empty($email) ) {
    $_SESSION['mtype'] = 'failure';
    $_SESSION['message'] = 'Fill in the form, please.';
    header('Location: index.php?go=register');
    exit();
  }

  /* Submit registration info to database.*/
  if ( ! User::isRegistered(User::getIdent(), $config) ) {
    if (User::addUser(User::getIdent(), $name, $email)) {
      $_SESSION['mtype'] = 'success';
      $_SESSION['message'] = 'Registration was successful.';
    } else {
      $_SESSION['mtype'] = 'failure';
      $_SESSION['message'] = 'There has been an registration error.';
    }
  } else {
    $user = User::getInstance($config);
    $user->setName($name);
    $user->setEmail($email);
    $_SESSION['mtype'] = "success";
    $_SESSION['message'] = "Successfully updated registration information.";
    header ('Location: index.php?go=user');
  }
}

?>
