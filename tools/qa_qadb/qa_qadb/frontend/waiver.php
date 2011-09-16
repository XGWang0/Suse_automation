<?php
/**
  * page to display, search, modify, and delete waiver data
  * @package QADB
  * @subpackage waiver
  **/
#dl('apd.so');
#apd_set_pprof_trace();

require_once('qadb.php');
common_header(array('title'=>'waiver'));

$waiverID=http('waiverID')+0;
$waiver_tcID=http('waiver_tcID')+0;

$submit=http('submit');
$view  =http('view'  );
$search=http('search');
$wtoken=http('wtoken');
$detail=http('detail');

# modes:
# 1: search waivers
# 2: search waiver details
# 3: new / edit waiver
# 4: view waiver details / edit waiver detail 

# control vars:
# submit: what to submit
# view: what to show
# search: 1 for searching

# process the change requests, when the write token matches
if(token_read($wtoken))
{
	if( $submit=='waiver' || $submit=='both' )
	{	# insert / update a waiver - DB code
		get_waiver();
		transaction();
		if( $waiverID )
			update_result( waiver_update($waiverID,$testcases_got,$bugs_got,$expl_got) );
		else
			update_result( $waiverID=waiver_new($testcases_got,$bugs_got,$expl_got), true );
		commit();
	}
	if( $submit=='waiver_detail' || ($submit=='both' && $detail) )
	{	# insert / update a waiver detail - DB code
		get_detail();
		
		transaction();
		if( $waiver_tcID )
			update_result( waiver_update_detail($waiver_tcID,$products_got,$releases_got,$archs_got,$match_got) );
		else
			update_result( waiver_new_detail($waiverID,$products_got,$releases_got,$archs_got,$match_got), true );
		commit();
	}
	else if( $submit=='delete_waiver' )
	{	# delete waiver record
		transaction();
		update_result( waiver_delete($waiverID) );
		commit();
	}
	else if( $submit=='delete_detail' )
	{
		transaction();
		update_result( waiver_delete_detail($waiver_tcID) );
		commit();
	}
}

# display the cards
$v2m=array('search_waiver'=>0,'search_detail'=>1,'new_waiver'=>2,'edit_waiver'=>2,'view_waiver'=>3,'edit_detail'=>3,'new_detail'=>3);
$mode=1;
if(!$view) $view='search_waiver';
if( $view && isset($v2m[$view]) )
	$mode=$v2m[$view];
$steps=array();
foreach( $v2m as $key=>$val )
	if( !isset($steps[$val]) || $key==$view )
		$steps[$val]=array(str_replace('_',' ',$key), 'waiver.php?view='.$key);
if($mode==3)
	$steps[3][1]='';  # no tab clicking, would miss essential params
else
	unset($steps[3]); # no direct clicking to 4th tab
print steps('',$steps,$mode);

# display the main contents
if( $view=='search_waiver' || ($view=='view_waiver' && !$waiverID) )
{	# waiver search & list	
	get_waiver();
	$tc=($tcname_got ? $tcname_got: ($testcases_got ? enum_get_val('testcases',$testcases_got):''));
	$what=array(
		array('tcname','',$tc,TEXT_ROW,'testcase'),
		array('explanation','',$expl_got,TEXT_ROW),
		array('bug_id','',$bugs_got,TEXT_ROW),
		array('view','','search_waiver',HIDDEN)
	);
	print html_search_form('waiver.php',$what);

# For convenience, search even with no data.
# Uncomment when having too many waivers.
#	if( $search )
	{
		if( $tcname_got )
			$testcases_got=enum_get_id_wildcard('testcases',$tcname_got);
		$data=search_waiver(0,array('testcaseID'=>$testcases_got,'explanation'=>$expl_got,'bugID'=>$bugs_got));
		table_htmlspecialchars($data);
		table_translate($data,array(
			'enums'=>array('testcaseID'=>'testcases'),
			'links'=>array('waiverID'=>'waiver.php?view=view_waiver&waiverID='),
			'ctrls'=>array(
				'edit'=>'waiver.php?view=edit_waiver&waiverID=',
				'delete'=>"confirm.php?confirm=w&view=search_waiver&waiverID="
			)
		));
		print html_table($data,array('id'=>'waiver','sort'=>'ssss','class'=>'tbl controls'));
	}
}
else if( $view=='search_detail' )
{	# waiver details search & list
	get_detail();
	array_unshift($match,array('null','&lt;any&gt;'));
	$what=array(
		array('products',$products,$products_got,MULTI_SELECT),
		array('releases',$releases,$releases_got,MULTI_SELECT),
		array('architectures',$archs,$archs_got,MULTI_SELECT),
		array('matchtype',$match,$match_got,SINGLE_SELECT),
		array('view','','search_detail',HIDDEN)
	);
	print html_search_form('waiver.php',$what);

	if( $search )
	{
		$data=search_waiver(1,array('productID'=>$products_got,'releaseID'=>$releases_got,'archID'=>$archs_got,'matchtype'=>$match_got));
		table_translate($data,array(
			'links'=>array(
				'waiver_tcID'=>'waiver.php?view=edit_detail&waiver_tcID=',
				'waiverID'=>'waiver.php?view=view_waiver&waiverID='
			),
			'enums'=>array(
				'testcaseID'=>'testcases',
				'productID'=>'products',
				'releaseID'=>'releases',
				'archID'=>'architectures'
			),
			'ctrls'=>make_detail_controls()
		));
		print html_table($data,array('id'=>'details','sort'=>'ssisssi','class'=>'tbl controls'));
	}

}
else if( $view=='new_waiver' || $view=='edit_waiver' )
{	# insert /  update a waiver - form
	get_waiver();
	if( $waiverID )
	{
		$data=search_waiver(0,array('waiverID'=>$waiverID,'header'=>0));
		if( count($data) )
		{
			$testcases_got=$data[0][1];
			$bugs_got=$data[0][2];
			$expl_got=$data[0][3];
			$tcse=$data[0][1];
		}
	}
	$testcases=enum_list_id_val('testcases');
	$wtoken=token_generate();
	$what=array(
		array('waiverID','',$waiverID,HIDDEN),
		array('testcases',$testcases,$testcases_got,SINGLE_SELECT),
		array('bug_id','',$bugs_got,TEXT_ROW,'bug ID'),
		array('explanation','',$expl_got,TEXT_AREA,'explanation'),
		array('submit','','waiver',HIDDEN),
		array('view','','view_waiver',HIDDEN),
		array('wtoken','',$wtoken,HIDDEN)
	);
	print html_search_form('waiver.php',$what);
}
else if( $view=='view_waiver' )
{	# print waiver info, list details
	if( $waiverID )
	{
		print "<h3>Waiver info</h3>\n";
		print_waiver_info($waiverID);
		print "<h3>Details</h3>\n";
		$data=search_waiver(2,array('waiverID'=>$waiverID));
		table_translate($data,array(
			'enums'=>array(
				'productID'=>'products',
				'releaseID'=>'releases',
				'archID'=>'architectures'
			),
			'ctrls'=>make_detail_controls()
		));
		print html_table($data,array('id'=>'details','sort'=>'isssi','class'=>'tbl controls'));
		print '<p><a class="btn" href="waiver.php?view=new_detail&waiverID='.$waiverID.'">add detail</a></p>'."\n";
	}
	else
		print "Wrong input data.<br/>\n";
}
else if( $view=='new_detail' || $view=='edit_detail' )
{	# insert / update a waiver detail - form
	get_detail();
	array_unshift($archs,array('null','&lt;any&gt;'));
	$match_got='problem';
	if( $waiver_tcID )
	{
		$waiverID=waiver_get_master($waiver_tcID);
		$data=search_waiver(1,array('waiver_tcID'=>$waiver_tcID,'header'=>0));
		if( count($data) )
		{
			$products_got=$data[0]['productID'];
			$releases_got=$data[0]['releaseID'];
			$archs_got=$data[0]['archID'];
			$match_got=$data[0]['matchtype'];
		}
	}
#	print "<h2>".($view=='new_detail' ? 'New':'Edit')." detail</h2>\n";
	$wtoken=token_generate();
	$what=array(
		array('products',$products,$products_got,SINGLE_SELECT),
		array('releases',$releases,$releases_got,SINGLE_SELECT),
		array('architectures',$archs,$archs_got,SINGLE_SELECT),
		array('matchtype',$match,$match_got,SINGLE_SELECT),
		array('waiverID','',$waiverID,HIDDEN),
		array('waiver_tcID','',$waiver_tcID,HIDDEN),
		array('submit','','waiver_detail',HIDDEN),
		array('view','','view_waiver',HIDDEN),
		array('wtoken','',$wtoken,HIDDEN)
	);
	print html_search_form('waiver.php',$what);

	print "<br/>\n";
	print_waiver_info($waiverID);
}
else if( $view=='new_both' )
{
	get_waiver();
	get_detail();
	$wtoken=token_generate();
	$testcases=enum_list_id_val('testcases');
	if( is_null($detail_got) )
		$detail_got=1;
	if( is_null($match_got) )
		$match_got='problem';
	$what=array(
		array('testcases',$testcases,$testcases_got,SINGLE_SELECT),
		array('bug_id','',$bugs_got,TEXT_ROW,'bug ID'),
		array('explanation','',$expl_got,TEXT_AREA,'explanation'),
		array('','','',HR),
		array('detail','',$detail_got,CHECKBOX),
		array('products',$products,$products_got,SINGLE_SELECT),
		array('releases',$releases,$releases_got,SINGLE_SELECT),
		array('architectures',$archs,$archs_got,SINGLE_SELECT),
		array('matchtype',$match,$match_got,SINGLE_SELECT),
		array('view','','view_waiver',HIDDEN),
		array('wtoken','',$wtoken,HIDDEN),
		array('submit','','both',HIDDEN)
	);
	print html_search_form('waiver.php',$what);
}


print "</div>\n"; # close the card
print html_footer();

function get_waiver()
{
	global $bugs_got,$expl_got,$testcases_got,$tcname_got;
	$bugs_got=http('bug_id');
	$bugs_got=($bugs_got ? 0+$bugs_got : $bugs_got);
	$expl_got=http('explanation');
	$testcases_got=http('testcases');
	$tcname_got=http('tcname');
	if( $tcname_got && !$testcases_got )
		$testcases_got=enum_get_id('testcases',$tcname_got);
}

function get_detail()
{
	global $products_got,$releases_got,$archs_got,$match_got,$detail_got;
	global $products,$releases,$archs,$match;
	$products_got=http('products');
	$releases_got=http('releases');
	$archs_got=http('architectures');
	$match_got=http('matchtype');
	$detail_got=http('detail');

	$products=enum_list_id_val('products');
	$releases=enum_list_id_val('releases');
	$archs=enum_list_id_val('architectures');
#	array_unshift($archs,array('','<any>'));
	$match=array(array('no problem','no problem'),array('problem','problem'));
}

function print_waiver_info($waiverID)
{
	$data=search_waiver(0,array('waiverID'=>$waiverID));
	enum_translate_table($data,array('testcaseID'=>'testcases'));
	print html_table($data,array());
}

function make_detail_controls()
{
	global $view,$waiverID;
	return array(
		'edit'=>'waiver.php?view=edit_detail&waiver_tcID=',
		'delete'=>"confirm.php?confirm=wd&view=$view&waiver_tcID="
	);
}
?>
