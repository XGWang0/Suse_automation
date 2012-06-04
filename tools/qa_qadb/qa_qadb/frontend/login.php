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
	exit;
}

$openid_auth = false;
$openid_url = "www.novell.com/openid";

if ($openid_auth && isset($_GET['openid_mode']) && $_GET['openid_mode'] == "id_res") {
	require_once "Zend/OpenId/Consumer.php";
	$consumer = new Zend_OpenId_Consumer();
	if ($consumer->verify($_GET, $id)) {
		$_SESSION['OPENID_AUTH'] = $id;
	}
} else if ($openid_auth && !isset($_SESSION['OPENID_AUTH'])) {
	require_once "Zend/OpenId/Consumer.php";
	$consumer = new Zend_OpenId_Consumer();
	$consumer->login($openid_url);
}

if( isset($_SESSION['user']) ) {
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
	if ( ! connect_to_mydb() ){
		destroySession("Wrong user name or password");
	}
	else 
		header("Location: index.php");
}
elseif (  !isset($_POST['user']) || !isset($_POST['pass'] )) {

?>
<table width="300" border="0" align="center" cellpadding="0" cellspacing="1" bgcolor="#CCCCCC">
<tr>
<form name="form1" method="post" action="login.php">
<td>
<table width="100%" border="0" cellpadding="3" cellspacing="1" bgcolor="#FFFFFF">
<tr>
<td colspan="3"><strong>Member Login </strong></td>
</tr>
<tr>
<td width="78">Username</td>
<td width="6">:</td>
<td width="294"><input name="user" type="text" ></td>
</tr>
<tr>
<td>Password</td>
<td>:</td>
<td><input name="pass" type="password" ></td>
</tr>
<tr>
<td>&nbsp;</td>
<td>&nbsp;</td>
<td><input type="submit" name="Submit" value="Login"></td>
</tr>
</table>
</td>
</form>
</tr>
</table>
<?php
}
else{

  $_SESSION['user']   		= $_POST['user'];
  $_SESSION['email']  		= "john.doe@mysite.com";
  $_SESSION['ip_address']	= $_SERVER['REMOTE_ADDR'];
  $_SESSION['user_agent']	= $_SERVER['HTTP_USER_AGENT'];
  $_SESSION['last_access']	= time();
  $_SESSION['pass']		= $_POST['pass'];	
  header("Location: login.php");

}
print html_footer();
?>
