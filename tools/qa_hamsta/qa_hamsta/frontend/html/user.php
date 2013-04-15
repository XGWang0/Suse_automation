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
?>

<div class="content">
Your external identifier (like OpenID URL) is <?php if (isset ($user) )
   {
     echo "<b>" . (strlen ($user->getExternId ())
		   ? $user->getExternId ()
		   : "not set") . "</b>.";
   }
?>
<br />
Your login is <?php if (isset ($user) )
  {
    echo "<b>" . ($user->getLogin()
		  ? $user->getLogin ()
		  : "not set") . "</b>.";
  }
?>
</div>

<div>
  <p>Your user name is <b><?php echo ( ( isset ($user) )
             ? $user->getName()
             : 'not set');
?></b>.<br />
Your e-mail address is <b><?php echo ( ( isset ($user) )
             ? $user->getEmail()
             : 'not set');
?></b>.<br />
  </p>
</div>

<?php if ( isset ($user) ): ?>
<form type="post">
   <input type="hidden" name="go" value="register" />
   <input type="submit" value="Change" />
</form>
<?php endif; ?>

<?php if ( isset ($user)): ?>
<!-- Form for changing user password. -->
<div style="width: 40%">
<p>
<form method="post" action="index.php?go=user">
  <fieldset>
  <legend>Change your Hamsta password here</legend>
  <input type="hidden" name="chngpswd" value="new" />
    <label id="notice">This password is only for Hamsta. Changes here do not have impact on other systems.</label>
    <table>
      <tr>
        <td><label id="password">New password: </label></td>
        <td><input id="password" type="password" name="pswd" /><br /></td>
      </tr>
      <tr>
        <td><label id="pswdcheck">And for check: </label></td>
        <td><input id="pswdcheck" type="password" name="pswdcheck" /></td>
      </tr>
      <tr>
       <td colspan="2"><input type="submit" value="Change" /></td>
      </tr>
    </table>
  </fieldset>
</form>
</p>
</div>
<?php endif; ?>

<?php
if ( isset ($user) ) {
  echo ("<div>\n");
  $list = $user->getRoleList();
  if ($user->isAllowed ('user_administration'))
    {
?>
  <div>
    <p>
      <a href="index.php?go=adminusers">User, roles and privileges administration</a>
    </p>
  </div>
<?php
    }
  if( $user->isAllowed('master_administration') )	{
	  print '<div><p>' . html_link('Global QA configuration','index.php?go=machine_config') . '</p></div>'."\n";
  }
    echo ("</div>\n");
}
?>
