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
 * Contents of the <tt>machine_details</tt> page  
 */
if ( ! defined('HAMSTA_FRONTEND') ) {
	$go = 'user';
	return require("index.php");
}

/* Variable $user is set in inc/user.php file which is always loaded
 * by index.php file. */

if ( $config->authentication->method == 'openid' && isset ($user) ) {
  echo ('<p>Your OpenId url is ');
  echo ('<b>' . $user->getLogin() . "</b>.\n");
  echo ('<br />');
 } else {
  echo ('<p>');
 }

?>

Your user name is <b>
<?php echo ( ( isset ($user) )
             ? $user->getName()
             : 'not set');
?></b>.<br />
Your e-mail address is <b>
<?php echo ( ( isset ($user) )
             ? $user->getEmail()
             : 'not set');
?></b>.<br />
</p>

<?php if ( isset ($user) ): ?>
<form type="post">
  <formset>
    <input type="hidden" name="go" value="register" />
    <input type="submit" value="Change"/>
  </formset>
</form>
<?php endif; ?>

<?php
if ( isset ($user) ) {
  echo ('<div>');
  echo ('Your current role is <b>');
  
  $curRole = $user->getCurrentRole();
  if ( isset ($curRole) ) {
    echo ($curRole->getName());
  }
  echo ('</b>.<br />');

  $list = $user->getRoleList();

  /* Display selection only if user has more than 2 roles available. The
   * first is current role which is not displayed in the selection. */
  if ( count($list) > 1 ) {
    echo ('<p>You can select another current role from the list.</p>');
    echo ('<form method="POST" action="index.php?go=user">');
    echo ('<select name="roles">');

    foreach ($user->getRoleList() as $roleName) {
      if ( isset ($curRole) && $curRole->getName() != $roleName) {
        echo ("<option value=\"$roleName\">" . $roleName . "</option>\n");
      }
    }
    echo ('</select>');
    echo ('<input type="hidden" name="go" value="user" />');
    echo ('<input type="submit" name="role" value="Change" />');
    echo ('</form>');
  }
}

?>
</div>
