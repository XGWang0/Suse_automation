<?php

require_once("qadb.php");
common_header(array('title'=>'RPM info'));

$configID=http('configID');
$all     =http('all');

# search form
$what = array(
	array('configID', '',$configID, TEXT_ROW,'configID(s)'),
	array('all','',$all,CHECKBOX,'(Incl. matching RPMs)')
);
print html_search_form('rpms.php',$what);

# split $configID and filter out existing configIDs
$splitted = explode(',',$configID);
$configIDs=array();
$errors=array();
foreach($splitted as $id)	{
	if( is_numeric($id) && rpms_num($id)>0 )
		$configIDs[]=$id;
	else
		$errors[]=$id;
}
$cnt = count($configIDs);

# non-existing configIDs
if( count($errors) )
	print html_error("No such configID(s): " . join(', ',$errors));

# header, referers
if( $cnt )	{
	print '<h2>'. ($cnt==1 ? 'RPM info for configID' : 'Diff configIDs') . ' ';
	print join(', ',$configIDs);
	print "</h2>\n";

	print '<div class="screen allresults">References :';
	foreach( $configIDs as $id )
		printf("\t%s\n",html_text_button($id,"submission.php?configID=$id&search=1"));
	print "</div>\n";
}


# print results
if( $cnt == 1 )
{
	# simple list
	print html_table(rpms_fetch($configID,1,null),array('id'=>'rpmlist','sort'=>'ss','total'=>true));
}
else if( $cnt > 1 )
{	
	# diff mode
	$data = rpms_diff(null,$all,$configIDs);
	print html_table($data,array('id'=>'rpmdiff','sort'=>'sss','total'=>true));
}

# page footer
print html_footer();

?>
