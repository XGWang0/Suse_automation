<?php
require_once('qadb.php');
require_once "Zend/Auth.php"; 
require_once "Zend/Session.php";
require_once "Zend/Auth/Adapter/OpenId.php";

# path to OpenID provider
$path="https://www.novell.com/openid";

# auth object
$auth = Zend_Auth::getInstance();

# are we processing the reply from OpenID provider ?
$reply = ( isset($_GET['openid_mode']) || isset($_POST['openid_mode']) );

# authenticate / process reply
$result = $auth->authenticate(
		new Zend_Auth_Adapter_OpenId( $reply ? null : $path )
		);
# On the first run, browser was redirected to the OpenID provider.
# Following code is only performed for OpenID replies:
if( $result->isValid() )	{
	# success
	do_db_connect();
	Zend_Session::regenerateId();
	$ext_ident = $auth->getIdentity();
	$login = http('openid_sreg_username');
	$name  = http('openid_sreg_fullname');
	$email = http('openid_sreg_email');
	
	# locate user by openID
	$tester = tester_get_current();

	# old users have no openID record; locate them by login (and fix)
	if( !$tester )
		$tester = tester_get_by_login($login);

	# new users create a new record
	if( !$tester )
		update_result( tester_insert($login,$ext_ident,$name,$email), true, "Welcome to QADB, $name.", null, true);
	else	{
		$greeting = "Welcome back $name.";

		# if something changed OR the user has no ext_ident, update the record
		if($tester['tester']!=$login || $tester['ext_ident']!=$ext_ident || $tester['name']!=$name || $tester['email']!=$email)
			update_result( tester_update($tester['tester_id'],$login,$ext_ident,$name,$email), false, "$greeting We have updated your settings.", null, true);
		else
			html_success($greeting, true);
	}
}
else	{
	# fail
	$auth->clearIdentity();
	$status = "";
	foreach( $result->getMessages() as $message )	{
		$status .= "$message\n";
	}
	html_error($status, true);
}

# go back
header("Location: index.php");
?>
