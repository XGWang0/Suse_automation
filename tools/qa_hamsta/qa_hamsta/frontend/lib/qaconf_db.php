<?php


/** library functions - common DB and HTML functions */
require_once('../tblib/tblib.php');

if( !isset($enums) )
	$enums=array();

$enums = array_merge( $enums, array(
	'qaconf_key'	=> array('qaconf_key_id','qaconf_key'),
	'qaconf'	=> array('qaconf_id','desc'),
));

define('QACONF_GLOBAL',1);
define('QACONF_COUNTRY',2);
define('QACONF_SITE',3);
define('QACONF_MASTER',4);
define('QACONF_MAX_SYS_ID',QACONF_MASTER);

/** logs into DB, checks user, prints header, prints navigation bar */
function common_header($args=null)
{
	global $conn_id,$glob_dest;
#	$is_production_server = ( $_SERVER['SERVER_ADDR'] == '10.10.3.155' );
	$defaults=array(
		'session'=>true,
		'connect'=>true,
		'icon'=>'icons/qadb_ico.png',
		'jquery'=>true,
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

function qaconf_list($ids=array(),$header=1,$limit=null)	{
	$cnt=count($ids);
	if( $cnt )	{
		$where='qaconf_id IN(?'.str_repeat(',?',$cnt-1).')';
		$format=str_repeat('i',$cnt);
		$args=$ids;
	}
	else	{
		$where='qaconf_id>?';
		$format='i';
		$args=array(0 /*QACONF_MAX_SYS_ID*/);
	}
	$sql="SELECT qaconf_id, `desc`, (SELECT COUNT(*) FROM qaconf_row WHERE qaconf_row.qaconf_id=qaconf.qaconf_id) AS rows, GROUP_CONCAT(DISTINCT `group`) AS groups, GROUP_CONCAT(name) AS machines, sync_url FROM qaconf LEFT JOIN machine USING(qaconf_id) LEFT JOIN `group` USING(qaconf_id) WHERE $where GROUP BY qaconf_id ORDER BY qaconf_id DESC";
	return call_user_func_array('mhash_query',array_merge(array($header,$limit,$sql,$format),$args));
#	return mhash_query($header,$limit,'SELECT qaconf_id,`desc`,GROUP_CONCAT(`group`) AS groups,GROUP_CONCAT(name) AS machines FROM qaconf LEFT JOIN machine USING(qaconf_id) LEFT JOIN `group` USING(qaconf_id) WHERE qaconf_id>? GROUP BY qaconf_id','i',0 /*QACONF_MAX_SYS_ID*/);
}

function qaconf_list_for_select()	{
	return array_merge(
		array(array('null','(none)')),
		matrix_query(0,null,'SELECT qaconf_id,`desc` FROM qaconf WHERE qaconf_id>'.QACONF_MAX_SYS_ID)
	);
}

#function qaconf_get_details($id)	{
#	return row_query('SELECT `desc`,sync_url FROM qaconf WHERE qaconf_id=?','i',$id);
#}

function qaconf_get_sync_url($id)	{
	return scalar_query('SELECT sync_url FROM qaconf WHERE qaconf_id=?','i',$id);
}

function qaconf_set_sync_url($id,$sync_url)	{
	return update_query('UPDATE qaconf SET sync_url=? WHERE qaconf_id=?','si',$sync_url,$id);
}

function qaconf_set_desc($qaconf_id,$desc)	{
	return update_query('UPDATE qaconf SET `desc`=? WHERE qaconf_id=?','si',$desc,$qaconf_id);
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

function qaconf_delete($qaconf_id)	{
	$ret=qaconf_delete_rows($qaconf_id);
	if( $ret>=0 )
		$ret=update_query('DELETE FROM qaconf WHERE qaconf_id=?','i',$qaconf_id);
	return $ret;
}

function qaconf_usage_count($qaconf_id)	{
	return row_query('SELECT (SELECT COUNT(*) FROM machine WHERE qaconf_id=?) AS machines, (SELECT COUNT(*) FROM `group` WHERE qaconf_id=?) AS groups','ii',$qaconf_id,$qaconf_id);
}

function qaconf_usage_machine($qaconf_id)	{
	return vector_query(null,'SELECT machine_id FROM machine WHERE qaconf_id=?','i',$qaconf_id);
}

function qaconf_usage_group($qaconf_id)	{
	return vector_query(null,'SELECT group_id FROM `group` WHERE qaconf_id=?','i',$qaconf_id);
}

function qaconf_detach_machine($qaconf_id)	{
	return update_query('UPDATE machine SET qaconf_id=NULL WHERE qaconf_id=?','i',$qaconf_id);
}

function qaconf_detach_group($qaconf_id)	{
	return update_query('UPDATE `group` SET qaconf_id=NULL WHERE qaconf_id=?','i',$qaconf_id);
}

function qaconf_insert_parsed($desc,$parsed)	{
	$qaconf_id=qaconf_insert($desc);
	qaconf_write_data_parsed($qaconf_id,$parsed);
	return $qaconf_id;
}

function qaconf_replace_body_parsed($qaconf_id,$parsed)	{
	qaconf_delete_rows($qaconf_id);
	return qaconf_write_data_parsed($qaconf_id,$parsed);
}

function qaconf_replace_parsed($qaconf_id,$desc,$parsed)	{
	qaconf_set_desc($qaconf_id,$desc);
	return qaconf_replace_body_parsed($qaconf_id,$parsed);
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

function qaconf_replace_unparsed($qaconf_id,$desc,$text,&$bad_rows=null)	{
	qaconf_set_desc($qaconf_id,$desc);
	return qaconf_replace_body_unparsed($qaconf_id,$text,$bad_rows);
}

function qaconf_insert_unparsed($desc,$text,&$bad_rows=null)	{
	$parsed=qaconf_parse_text($text,$bad_rows);
	return qaconf_insert_parsed($desc,$parsed);
}

function qaconf_replace_body_unparsed($qaconf_id,$text,&$bad_rows=null)	{
	$parsed=qaconf_parse_text($text,$bad_rows);
	return qaconf_replace_body_parsed($qaconf_id,$parsed);
}

function qaconf_get_desc($qaconf_id)	{
	return scalar_query('SELECT `desc` FROM qaconf WHERE qaconf_id=?','i',$qaconf_id);
}

function qaconf_get_by_desc($desc)	{
	return scalar_query('SELECT qaconf_id FROM qaconf WHERE `desc`=?','s',$desc);
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
			$r['qaconf_id']=$id;
			$ret[$key]=$r;
		}
	}
#	$ret[0]['src']='src';
#	$ret[0]['qaconf_id']='id';
	return array_values($ret);
}

function qaconfs_global()	{
	return array(QACONF_GLOBAL,QACONF_COUNTRY,QACONF_SITE,QACONF_MASTER);
}

function qaconfs_for_machine($machine_id)	{
	$ret=qaconfs_global();
	$groups=group_machine_list_group($machine_id);
	foreach( array_keys($groups) as $group )	{
		if(($qaconf_id=group_get_qaconf_id($group)))
			$ret[]=$qaconf_id;
	}
	if(( $qaconf_id=machine_get_qaconf_id($machine_id) ))
		$ret[]=$qaconf_id;
	return $ret;
}

function qaconfs_for_machines($machines=array())	{
	$args=array_merge(array(1,null,'SELECT machine_id,name AS machine,machine.qaconf_id AS machine_qaconf_id,group_id,`group`,`group`.qaconf_id AS group_qaconf_id FROM machine LEFT JOIN group_machine USING(machine_id) LEFT JOIN `group` USING(group_id) WHERE machine_id IN('.join(',',array_fill(0,count($machines),'?')).')',str_repeat('i',count($machines))),$machines);
	return call_user_func_array('mhash_query',$args);
}

function qaconfs_for_group($group)	{
	$ret=qaconfs_global();
	if(( $qaconf_id=group_get_qaconf_id($group) ))
		$ret[]=$qaconf_id;
	return $ret;
}

function machine_get_qaconf_id($machine_id)	{
	return scalar_query('SELECT qaconf_id FROM machine WHERE machine_id=?','i',$machine_id);
}

function machine_set_qaconf_id($machine_id,$qaconf_id)	{
	return update_query('UPDATE machine SET qaconf_id=? WHERE machine_id=?','ii',$qaconf_id,$machine_id);
}

function machine_get_by_ip($ip)	{
	return scalar_query('SELECT machine_id FROM machine WHERE ip=?','s',$ip);
}

function machine_get_name($machine_id)	{
	return scalar_query('SELECT name FROM machine WHERE machine_id=?','i',$machine_id);
}

function group_get_name($group_id)	{
	return scalar_query('SELECT `group` FROM `group` WHERE group_id=?','i',$group_id);
}

#function group_get_details($group_id)	{
#	return row_query('SELECT `group`,qaconf_id FROM `group` WHERE group_id=?','i',$group_id);
#}

function group_get_qaconf_id_by_name($group)	{
	return scalar_query('SELECT qaconf_id FROM `group` WHERE `group`=?','s',$group);
}

function group_set_qaconf_id_by_name($group,$qaconf_id)	{
	return update_query('UPDATE `group` SET qaconf_id=? WHERE `group`=?','is',$qaconf_id,$group);
}

function group_machine_list_group($machine_id)	{
	return vector_query(null,'SELECT group_id FROM group_machine WHERE machine_id=?','i',$machine_id);
}

function group_get_qaconf_id($group_id)	{
	return scalar_query('SELECT qaconf_id FROM `group` WHERE group_id=?','i',$group_id);
}

function groups_list_machine_names($group_ids)	{
	$ret=array();
	foreach( $group_ids as $id )	{
		if(( $data=vector_query(null,'SELECT name FROM machine JOIN group_machine USING(machine_id) WHERE group_id=?','i',$id) ))
			$ret=array_merge($ret,$data);
	}
	return array_unique($ret);
}

?>
