<?php


/** library functions - common DB and HTML functions */
require_once($_SERVER['DOCUMENT_ROOT'].'/tblib/tblib.php');

if( !isset($enums) )
	$enums=array();

$enums = array_merge( $enums, array(
	'qaconf_key'	=> array('qaconf_key_id','qaconf_key'),
	'qaconf'	=> array('qaconf_id','desc'),
));

/** logs into DB, checks user, prints header, prints navigation bar */
function common_header($args=null)
{
	global $conn_id,$glob_dest;
#	$is_production_server = ( $_SERVER['SERVER_ADDR'] == '10.10.3.155' );
	$defaults=array(
		'session'=>true,
		'connect'=>true,
		'icon'=>'icons/qadb_ico.png'
	);
	$args=args_defaults($args,$defaults);
	if( $args['session'] )
		session_start();
	if( $args['connect'] )
		$conn_id=connect_to_mydb();
	print html_header($args);
}

function qaconf_insert($desc)	{
	return insert_query('INSERT INTO qaconf(`desc`) VALUES(?)','s',$desc);
}

function qaconf_list($header=1,$limit=null)	{
	return mhash_query($header,$limit,'SELECT qaconf_id,`desc` FROM qaconf');
}

function qaconf_row_insert($id,$key,$val,$cmt)	{
	$key_id=enum_get_id_or_insert('qaconf_key',$key);
	if( !$key_id )
		return null;
#	print "Inserting qaconf_id=$id key=$key val=$val cmt=$cmt<br/>\n";
	if( $cmt )
		return insert_query('INSERT INTO qaconf_row(qaconf_id,qaconf_key_id,val,cmt) VALUES(?,?,?,?)','iiss',$id,$key_id,$val,$cmt);
	else
		return insert_query('INSERT INTO qaconf_row(qaconf_id,qaconf_key_id,val) VALUES(?,?,?)','iis',$id,$key_id,$val);
}

function qaconf_set_desc($qaconf_id,$desc)	{
	return update_query('UPDATE qaconf SET `desc`=? WHERE qaconf_id=?','si',$desc,$qaconf_id);
}

function qaconf_write_data_parsed($qaconf_id,$parsed)	{
	if( !$qaconf_id )
		return null;
	$num=0;
	foreach( $parsed as $row )	{
		if( isset($row['key']) && $row['key'] )	{
			$row_id=qaconf_row_insert($qaconf_id,$row['key'],$row['val'],(isset($row['cmt']) ? $row['cmt'] : null));
			$num++;
		}
	}
	return $num;
}

function qaconf_delete_rows($qaconf_id)	{
	return update_query('DELETE FROM qaconf_row WHERE qaconf_id=?','i',$qaconf_id);
}

function qaconf_insert_parsed($desc,$parsed)	{
	$qaconf_id=qaconf_insert($desc);
	return qaconf_write_data_parsed($qaconf_id,$parsed);
}

function qaconf_replace_parsed($qaconf_id,$desc,$parsed)	{
	qaconf_set_desc($qaconf_id,$desc);
	qaconf_delete_rows($qaconf_id);
	return qaconf_write_data_parsed($qaconf_id,$parsed);
}


function preg_match_replace(&$text,$pattern,$replace)	{
	if( !preg_match($pattern,$text,$matches)	)
		return array();
	$text=preg_replace($pattern,$replace,$text);
	return $matches;
}

function qaconf_parse_row($row)	{
	$ret=array();
	if( $m=preg_match_replace($row,'/#\s*src=(.+)$/','') )	
		$ret['src']=$m[1];
	if( $m=preg_match_replace($row,'/#\s*(.+)$/','') )
		$ret['cmt']=$m[1];
	if( preg_match("/([\w_\d]+)\s*=\s*(.*)$/",$row,$m) )	{
		$m[2]=preg_replace('/^\'(.*)\'\s*$/','\1',$m[2]);
		$m[2]=preg_replace('/^"(.*)"\s*$/','\1',$m[2]);
		$ret['key']=$m[1];
		$ret['val']=$m[2];
	}
	if( count($ret) )
		return $ret;
	return null;
}

function qaconf_parse_text($text,&$bad_rows=null)	{
	$rows=preg_split('/\r?\n/',$text);
	$ret=array();
	for( $i=0; $i<count($rows); $i++ )	{
		$parsed=qaconf_parse_row($rows[$i]);
		if( $parsed )
			$ret[] = $parsed;
		else if( is_array($bad_rows) )
			$bad_rows[$i] = $rows[$i];
	}
	return $ret;
}

function qaconf_insert_unparsed($desc,$text,&$bad_rows=null)	{
	$parsed=qaconf_parse_text($text,$bad_rows);
	return qaconf_insert_parsed($desc,$parsed);
}

function qaconf_replace_unparsed($qaconf_id,$desc,$text,&$bad_rows=null)	{
	$parsed=qaconf_parse_text($text,$bad_rows);
	return qaconf_replace_parsed($qaconf_id,$desc,$parsed);
}

function qaconf_get_desc($qaconf_id)	{
	return scalar_query('SELECT `desc` FROM qaconf WHERE qaconf_id=?','i',$qaconf_id);
}

function qaconf_get_rows($qaconf_id)	{
	return mhash_query(1,null,'SELECT qaconf_key_id as `key`,val,cmt as cmt FROM qaconf_row WHERE qaconf_id=?','i',$qaconf_id);
}

function qaconf_get_rows_translated($qaconf_id)	{
	$data=qaconf_get_rows($qaconf_id);
	table_translate($data,array(
		'enums'=>array(	'key'=>'qaconf_key' ),
	));
	return $data;
}

function qaconf_get_file($qaconf_id)	{
	$ret='';
	$data=qaconf_get_rows_translated($qaconf_id);
	return qaconf_format_data($data);
}

function qaconf_format_data($data)	{
	$ret='';
	for( $i=1; $i<count($data); $i++ )	{
		$d=$data[$i];
		$ret .= $d['key'].'="'.$d['val'].'"';
		if( isset($d['cmt']) && $d['cmt'] )
			$ret .= "\t# ".$d['cmt'];
		if( isset($d['src']) && $d['src'] )
			$ret .= "\t# src=".$d['src'];
		$ret .= "\n";
	}
	return $ret;
}

function qaconf_merge($list)	{
	$ret=array();
	foreach($list as $id)	{
		$desc=qaconf_get_desc($id);
		$conf=qaconf_get_rows_translated($id);
		$ret[0]=$conf[0];
		for( $i=1; $i<count($conf); $i++ )	{
			$r=$conf[$i];
			if(!$r['key'])
				continue;
			$key=$r['key'];
			$r['src']=$desc;
			$ret[$key]=$r;
		}
	}
	return array_values($ret);
}

?>
