<?php

/* webservice for Kilian Petsch <kpetsch@suse.de> */

$name=http('name');
if( $name )	{
	$machine=Machine::get_by_hostname($name);
	$rh = new ReservationsHelper ($machine);
	$ret = join (';', $rh->getUserNames ());
}
else
	$ret="Usage: ".$_SERVER['REQUEST_URI']."&name=<hostname>";

header('Content-Type: text/plain');
print $ret;
exit;
?>
