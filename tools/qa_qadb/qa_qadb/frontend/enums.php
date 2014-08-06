<?php

require_once('qadb.php');
common_header(array('title'=>'QADB enum types'));
print "<h1>Enum tables</h1>\n";

$step=http('step','l');
$table=http('table');
$id=http('id');
$val=null;
$newval=http('newval');
$submit=http('submit');
$target_id=http('target_id');
if( isset($table) && !array_key_exists($table,$enums) )
	$table=null;
if( isset($table) && isset($id) )	{
	$val=enum_get_val($table,$id);
}
$what=array(
	array('table','',$table,HIDDEN),
	array('id','',$id,HIDDEN),
);

if( token_read(http('wtoken')) && isset($table) && isset($id))	{
#	print "***<br/>\n";
	if( $submit=='delete_enum' )  {
		transaction();
		update_result( enum_delete_id($table,$id), false, "Record $id/$val deleted." );
		commit();
	}
	else if( $submit=='rename' && isset($newval) && ($val != $newval) )	{
		transaction();
		update_result( enum_rename_id($table,$id,$newval), false, "Record $id renamed from '$val' to '$newval'." );
		commit();
	}
	else if( $submit=='merge' && isset($target_id) && ($id!=$target_id) )	{
		$v=efields($table);
		$data=mysql_referers(1,$table,$v[0]);
		transaction();
		for( $i=1; $i<count($data); $i++ )      {
			$t=$data[$i]['table'];
			update_result(
				table_replace_value( $t, $data[$i]['column'], $id, $target_id ),
				false, "Data in table '$t' marged."
			);
		}
		update_result( enum_delete_id($table,$id), false, "Record $id/$val deleted." );
		commit();
	}
	$step='stat';
}

$steps=array('l'=>'List');
$steps_alt=array('fk'=>'Foreign key','d'=>'Detail','stat'=>'Usage statistics','val'=>'Values');
print steps('enums.php?'.($table ? "table=$table&":'').'step=',$steps,$step,$steps_alt);

if( $step=='d' )	{
	$data=mysql_foreign_keys_list($table);
	if(!$data)
		print html_error("No such table: '$table'");
	else	{
		print html_table($data);

	}
}
else if( $step=='stat' )	{
	$data=mysql_foreign_keys_list($table,1);
	$data[0]['ctrl']='Controls';
	for($i=1;$i<count($data);$i++)	{
		$vals=array_values($data[$i]);
		$base="enums.php?table=$table&id=".$vals[0];
		$data[$i]['ctrl']=html_text_button('rename',"$base&step=rename");
		$num=$vals[count($vals)-1];
		if( $num>0 )
			$data[$i]['ctrl'].=html_text_button('merge',"$base&step=merge");
		else
			$data[$i]['ctrl'].=html_text_button('delete',"confirm.php?table=$table&id=".$vals[0]."&confirm=en&step=stat");
	}
	print html_table($data,array('total'=>1,'id'=>'stat','sort'=>'is'.str_repeat('i',count($data[0])-3),'callback'=>'colorize_stat'));
}
else if( $step=='rename' && isset($table) )	{
	$what[]=array('newval','',$val,TEXT_ROW,"$table ID $id value");
	$what[]=array('submit','','rename',HIDDEN);
	$what[]=array('wtoken','',token_generate(),HIDDEN);
	print html_search_form('enums.php',$what,array('submit'=>'rename'));
}
else if( $step=='merge' && isset($table) )	{
	$what[]=array('target_id',enum_list_id_val($table),$id,SINGLE_SELECT,"merge $table ID $id ($val) into");
	$what[]=array('submit','','merge',HIDDEN);
	$what[]=array('wtoken','',token_generate(),HIDDEN);
	print html_search_form('enums.php',$what,array('submit'=>'merge!'));
}
else	{
	$data = mysql_foreign_keys_list_all();
	for($i=1; $i<count($data); $i++)	{
		if( !isset($data[$i]['reference']) )
			continue;
		$t='enums.php?table='.$data[$i]['table'];
		print '<h3>'.$data[$i]['table']."</h3>\n";
		print html_text_button('details',"$t&step=d");
		print html_text_button('usage statistics',"$t&step=stat");
#		print html_text_button('values',"$t&step=val");
		print html_div('','References:');
		print "<ul>\n";
		$parts=preg_split('/ /',$data[$i]['reference']);
		foreach($parts as $p)
			print '<li>' . html_link($p,'enums.php?step=fk&ref='.$p,null) . "</li>\n";
		print "</ul>\n";
	}
}

print "</div>\n";
print html_footer();

function colorize_stat()
{
	$args=func_get_args();
	$total=$args[count($args)-2];
	return ( ($total>0) ? '' : ' skipped');
}
?>
