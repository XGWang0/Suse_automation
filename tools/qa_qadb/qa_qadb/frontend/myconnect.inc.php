<?php
//myconnect.inc.php
global $mysqluser,$mysqlpasswd,$mysqlhost,$mysqldb;
if( @$role == "admin" )	{
	$mysqluser="qadb_admin";
	$mysqlpasswd="bignastyboy";
}
elseif( @$role == "user" )	{
	$mysqluser="qadb_user";
	$mysqlpasswd="givememydata";
}
else	{
	$mysqluser="qadb_guest";
	$mysqlpasswd="";
}
$mysqlhost="localhost";
$mysqldb="qadb";
$is_pdo=1;
?>
