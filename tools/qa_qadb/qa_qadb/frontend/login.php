<?php
require_once('qadb.php');
common_header(array(
    'connect'=>false,
    'title'=>'QADB login'
));

// unset all session variables, and destroy session
function destroySession($p_strMessage) {
	session_unset();
	session_destroy();
	print html_error($p_strMessage);
	flush();
	header ('Location: index.php');
	exit ();
}

$openid_auth = false;
$openid_url = "www.novell.com/openid";

if( isset($_SESSION['user']) ) {
	if ( isset($_POST['pass']) )
		$_SESSION['pass'] = $_POST['pass'];

	if ( $_SESSION['user'] == 'root' )
		destroySession("No root login allowed");

	if( substr($_SESSION['ip_address'],0,6)
        != substr($_SERVER['REMOTE_ADDR'],0,6) ) {
		destroySession("Invalid IP Address");
	}
	// verify user-agent is same
	elseif( $_SESSION['user_agent'] 
	        != $_SERVER['HTTP_USER_AGENT'] ) {
		destroySession("Invalid User-Agent");
	}
	// verify access within 20 min
	elseif( (time()-1200) > $_SESSION['last_access'] ) {
		destroySession("Session Timed Out");
	}

	# after we made sure that the user is ok, let's check if he can access the database
	if (! connect_to_mydb() ) {
		if (! $openid_auth ) {
			$mysqluser = 'qadb';
			$password = search_user ($_SESSION['user']);
			if ( count($password) == 0 ) {
				error_log ('Empty password!');
				destroySession ('Wrong user name or user without password.');
			}
		}
	}
	else  {
		header("Location: index.php");
	}
}
elseif ((!isset($_POST['user']) || !isset($_POST['pass'])) && !isset($_GET['openid_mode'])) {

	if ($openid_auth) {
		require_once "Zend/OpenId/Consumer.php";
		$consumer = new Zend_OpenId_Consumer();
		if (!$consumer->login($openid_url)) {
			destroySession("Openid Authentication Failed");
		}
	}

?>
<form name="form1" method="post" action="login.php">
<table width="300" border="0" align="center" cellpadding="0" cellspacing="1" bgcolor="#CCCCCC">
<tr>
<td>
<table width="100%" border="0" cellpadding="3" cellspacing="1" bgcolor="#FFFFFF">
<tr>
<td colspan="3"><strong>Member Login </strong></td>
</tr>
<tr>
<td width="78">Username</td>
<td width="6">:</td>
<td width="294"><input name="user" type="text" /></td>
</tr>
<tr>
<td>Password</td>
<td>:</td>
<td><input name="pass" type="password" /></td>
</tr>
<tr>
<td>&nbsp;</td>
<td>&nbsp;</td>
<td><input type="submit" name="Submit" value="Login" class="btn"/></td>
</tr>
</table>
</td>
</tr>
</table>
</form>
<?php
}
else	{
	$_SESSION['user']		= $_POST['user'];
	$_SESSION['email']		= "john.doe@mysite.com";
	$_SESSION['ip_address']		= $_SERVER['REMOTE_ADDR'];
	$_SESSION['user_agent']		= $_SERVER['HTTP_USER_AGENT'];
	$_SESSION['last_access']	= time();
	$_SESSION['pass']		= $_POST['pass'];

	if ($openid_auth) {
		require_once "Zend/OpenId/Consumer.php";
		$consumer = new Zend_OpenId_Consumer();
		if (isset($_GET['openid_mode']) && $_GET['openid_mode'] == "id_res") {
			 if ($consumer->verify($_GET, $id)) {
				$id_array = explode("/", $id);
				$_SESSION['OPENID_AUTH'] = $id_array[count($id_array)-1];
				/* Just to make sure we can use select below. */
				connect_to_mydb();
				$_SESSION['user'] = $_SESSION['OPENID_AUTH'];
				$_SESSION['pass'] = "";

				if (! isset ($_SESSION['role'])) {
					$user_role = get_user_role ($_SESSION['user']);
					if (isset ($user_role)) {
						$_SESSION['role'] = $user_role;
					} else {
						destroySession('You do not have assigned role to your user name.');
					}
				}
			}
		}
	}
	header("Location: login.php");
}
print html_footer();
?>
