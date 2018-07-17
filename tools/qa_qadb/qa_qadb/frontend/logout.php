<?php
require_once "Zend/Auth.php";
require_once "Zend/Session.php";
require_once "qadb.php";

$auth = Zend_Auth::getInstance();
$auth->clearIdentity();
Zend_Session::regenerateId();
html_success("Logged out.", true);
header("Location: index.php");	
?>

