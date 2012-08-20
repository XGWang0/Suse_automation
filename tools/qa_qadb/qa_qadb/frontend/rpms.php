<?php

require_once("qadb.php");
common_header(array('title'=>'RPM info'));

$rpm_config_id=http('rpm_config_id');
$all     =http('all');

# search form
$what = array(
	array('rpm_config_id', '',$rpm_config_id, TEXT_ROW,'RPM config_id(s)'),
	array('all','',$all,CHECKBOX,'(Incl. matching RPMs)')
);
print html_search_form('rpms.php',$what);

# split $rpm_config_id and filter out existing rpm_config_ids
$splitted = explode(',',$rpm_config_id);
$rpm_config_ids=array();
$errors=array();
foreach($splitted as $id)	{
	if( is_numeric($id) && rpms_num($id)>0 )
		$rpm_config_ids[]=$id;
	else
		$errors[]=$id;
}
$cnt = count($rpm_config_ids);

# non-existing rpm_config_ids
if( count($errors) )
	print html_error("No such rpm_config_id(s): " . join(', ',$errors));

# header, referers
if( $cnt )	{
	print '<h2>'. ($cnt==1 ? 'RPM info for rpm_config_id' : 'Diff rpm_config_ids') . ' ';
	print join(', ',$rpm_config_ids);
	print "</h2>\n";

	print '<div class="screen allresults">References :';
	foreach( $rpm_config_ids as $id )
		printf("\t%s\n",html_text_button($id,"submission.php?rpm_config_id=$id&search=1"));
	print "</div>\n";
}


# print results
if( $cnt == 1 )
{
	# simple list
	print html_table(rpms_fetch($rpm_config_id,1,null),array('id'=>'rpmlist','sort'=>'ss','total'=>true));
}
else if( $cnt > 1 )
{	
	# diff mode
	$data = rpms_diff(null,$all,$rpm_config_ids);
	print html_table($data,array('id'=>'rpmdiff','sort'=>'s'.str_repeat('s',$cnt),'total'=>true));
}

# page footer
print html_footer();

?>
