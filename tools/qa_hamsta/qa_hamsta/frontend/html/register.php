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
   * Contents of the <tt>register</tt> page
   */
if (!defined('HAMSTA_FRONTEND')) {
  $go = 'register';
  return require("index.php");
}

if ( User::isLogged() ) {
  if ( $user = User::getById (User::getIdent (), $config) )
    {
      $user_name = $user->getName();
      $user_email = $user->getEmail();
    }
}

?>

<p>Please enter your full name and email address to register with Hamsta. This information will be used when reserving machines and to email you job notifications.</p>
<div style="width: 40%">
<form method="POST">
  <fieldset>
	<input type="hidden" name="go" value="register" />
	<table>
		<tr><td>Name</td> <td><input type="text" name="name" value="<?php echo (htmlspecialchars($user_name)) ?>" /></td></tr>
		<tr><td>Email</td> <td><input type="text" name="email" value="<?php echo (htmlspecialchars($user_email)) ?>" /></td></tr>
	</table><br />
<input type="submit" value="Submit" name="submit" />
  </fieldset>
</form>
</div>