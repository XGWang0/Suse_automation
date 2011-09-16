<?php
	//myconnect.inc.php
if( !isset( $_SESSION['user'] ) || !isset($_SESSION['pass']) ){
	$mysqluser="qadb_guest";
	$mysqlpasswd="";
}
else{
	$mysqluser=$_SESSION['user'];
	$mysqlpasswd=$_SESSION['pass'];

}	
$mysqlhost="localhost";
$mysqldb="qadb";

?>
