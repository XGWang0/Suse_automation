<?php
header('Content-Type: text/plain');
require_once('qadb.php');
$connID=connect_to_mydb();
$name=http('name');
$what=http('what');
if( in_array($what, array('products', 'releases', 'architectures') ) )
	$data=enum_list_val($what);
else
{
	$data=get_script_versions($name);
	foreach($data as $row)
		printf("%s\n", join("\t",$row));
	return;
}
print join( "\n", $data );
?>
