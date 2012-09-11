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
   * Logic of the user page.
   */
if (!defined('HAMSTA_FRONTEND')) {
  $go = 'user';
  return require("index.php");
 }

$html_title = "User configuration";

if ( User::isLogged() ) {
  $user = User::getInstance($config);
  if ( isset ($_POST['role']) ) {
    $user->setRole ($_POST['roles']);
  } else if ( isset ($_POST['chngpswd']) ) {
    if ( isset ($_POST['pswd']) && isset ($_POST['pswdcheck'])
         && ! (empty ($_POST['pswd'])
               || empty ($_POST['pswdcheck']))
         && $_POST['pswd'] == $_POST['pswdcheck']) {
      $user->setPassword ($_POST['pswd']);
      $_SESSION['mtype'] = 'success';
      $_SESSION['message'] = 'Your password has been successfuly changed.';
    } else {
      $_SESSION['mtype'] = 'fail';
      $_SESSION['message'] = 'The password and checked password have to be the same and cannot be empty.';
    }
  }
}

?>
