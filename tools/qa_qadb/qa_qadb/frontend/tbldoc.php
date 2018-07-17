<?php
require_once('qadb.php');
common_header(array('title'=>'Description of database tables'));

$tables=list_tables();

# index
print "<h1>QADB tables</h1>\n<ul>\n";
foreach( $tables as $tbl )
	print '<li>'.html_link($tbl[0],'#'.$tbl[0])."</li>\n";
print "</ul>\n";

# details
foreach( $tables as $tbl )
{
	$table=$tbl[0];
	print '<h2 class="tbldesc"><a name="'.$table.'">'.$table."</a></h2>\n";
	$sql=get_create_table($table);
	$from=0;
	$types=array();
	$ref_tbl=array();
	$ref_field=array();
	while( $from<strlen($sql) )
	{	# process one row from CREATE TABLE

		# get the row
		$to=strpos($sql,"\n",$from);
		if($to === false)
			$to=strlen($sql);
		$row=substr($sql,$from,$to-$from);
#		print $row."<br/>\n";
		$from=$to+1;

		# match the row
		if( preg_match('/^\s*`([^`]+)`\s+(\w+\([^\)]+\)|[^\s]+)/',$row,$matches ) )
			$types[$matches[1]] = $matches[2];
		else if( preg_match('/FOREIGN KEY \(`([^`]+)`\) REFERENCES `([^`]+)`\s+\(`([^`]+)`\)/',$row,$matches ) )
		{
			$ref_tbl  [$matches[1]]=$matches[2];
			$ref_field[$matches[1]]=$matches[3];
		}
	}
	$data=array(array('Field','Type'));
	if( $ref_tbl )
		$data[0][]='References';
	foreach( $types as $field=>$type )
	{
		$row=array($field,$type,'');
		if( isset( $ref_tbl[$field] ) )
			$row[2]=html_link($ref_tbl[$field],'#'.$ref_tbl[$field]);
		$data[]=$row;
	}
	print html_table($data,array('class'=>'tbldesc','evenodd'=>false));
	$desc=table_description($table);
	if( $desc )
		print "<p>$desc</p>\n";
}

print html_footer();

?>
