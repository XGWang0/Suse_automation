<?php

require_once('qadb.php');
common_header(array('title'=>'QADB enum types'));
print "<h1>Enum tables</h1>\n";

$step=http('step','l');

$steps=array('l'=>'List');
$steps_alt=array('fk'=>'Foreign key','d'=>'Detail','stat'=>'Usage statistics','val'=>'Values');
print steps('enums.php?step=',$steps,$step,$steps_alt);

if( $step=='d' )	{
	$table=http('table');
	$data=mysql_foreign_keys_list($table);
	if(!$data)
		print html_error("No such table: '$table'");
	else	{
		print html_table($data);

	}
}
else if( $step=='stat' )	{
	$table=http('table');
	$data=mysql_foreign_keys_list($table,1);
	print html_table($data,array('total'=>1,'id'=>'stat','sort'=>'s'.str_repeat('i',count($data[0])-1)));
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
		print html_text_button('values',"$t&step=val");
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
?>
