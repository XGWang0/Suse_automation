<?php

function vector_mysql_query( $sql )
{
    $ret = array();
    $idx = 0;

    if( empty($sql) )
        return $ret;

    $result = mysql_query($sql) or die( mysql_error() );

    while( $row = mysql_fetch_array( $result ) )
        $ret[$idx++] = $row[0];

    return $ret;
}

function scalar_mysql_query( $sql )
{
    if ( empty($sql) )
        return null;

    $result = mysql_query($sql) or die(mysql_error());
    if(!($row = mysql_fetch_array( $result ))) return null;
    return $row[0];
}

// map { @{$_} } @_;
function merge_array($a)
{
	$ret=array();
	foreach($a as $myval)
		$ret=array_merge($ret,$myval);
	return $ret;
}

function dump_array($a,$name)
{
	print $name;
	print_r($a);
	print "<br/>\n";
}

// splits part from bench_parts 
// into first part, middle part, and last part
function split_part($part)
{
	$first = strpos($part,';');
	$last = strrpos($part,';');
	if( $last==false )
		return array($part);

	# next character behind ';' or '; '
	$nfirst = min( strlen($part)-1, ($first + ( $part[$first+1]==' ' ? 2 : 1 )));
	$nlast  = min( strlen($part)-1, ($last  + ( $part[$last+1]==' ' ? 2 : 1 )));
		
	return array( 
		substr($part,0,$first), 
		substr($part,$nfirst,$last-$nfirst),
		substr($part,$nlast)
		);
}


?>
