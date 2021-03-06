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

$waiver_id=http('waiver_id')+0;
$waiver_testcase_id=http('waiver_testcase_id')+0;

$submit=http('submit');
$view  =http('view','sw');
$search=http('search');
$wtoken=http('wtoken');
$detail=http('detail');

# view modes:
# 'sw': search waivers
# 'sd': search waiver details
# 'nw'/'ew': new waiver / edit waiver
# 'nd'/'ed': new detail / edit detail 
# 'nwd' : new waiver + detail

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
		if( $waiver_id )
			update_result( waiver_update($waiver_id,$testcase_got,$bugs_got,$expl_got) );
		else
			update_result( $waiver_id=waiver_new($testcase_got,$bugs_got,$expl_got), true );
		commit();
	}
	if( $submit=='waiver_detail' || ($submit=='both' && $detail) )
	{	# insert / update a waiver detail - DB code
		get_detail();
		
		transaction();
		if( $waiver_testcase_id )
			update_result( waiver_update_detail($waiver_testcase_id,$product_got,$release_got,$arch_got,$match_got) );
		else
			update_result( waiver_new_detail($waiver_id,$product_got,$release_got,$arch_got,$match_got), true );
		commit();
	}
	else if( $submit=='delete_waiver' )
	{	# delete waiver record
		transaction();
		update_result( waiver_delete($waiver_id) );
		commit();
	}
	else if( $submit=='delete_detail' )
	{
		transaction();
		update_result( waiver_delete_detail($waiver_testcase_id) );
		commit();
	}
}

# display the cards
$steps = array( 'sw'=>'search waiver', 'sd'=>'search detail' );
if( $view!='ew' && $auth->hasIdentity() )
	$steps['nw'] = 'new waiver';
$steps_alt = array('ew'=>'edit waiver','vw'=>'view waiver','ed'=>'edit detail','nd'=>'new detail','nwd'=>'new waiver+detail');
print steps('waiver.php?view=',$steps,$view,$steps_alt);

# display the main contents
if( $view=='sw' || ($view=='vw' && !$waiver_id) )
{	# waiver search & list	
	$view='sw';
	get_waiver();
	$tc=($tcname_got ? $tcname_got: ($testcase_got ? enum_get_val('testcase',$testcase_got):''));
	$what=array(
		array('tcname','',$tc,TEXT_ROW,'testcase'),
		array('explanation','',$expl_got,TEXT_ROW),
		array('bug_id','',$bugs_got,TEXT_ROW),
		array('view','',$view,HIDDEN)
	);
	print html_search_form('waiver.php',$what);

# For convenience, search even with no data.
# Uncomment when having too many waivers.
#	if( $search )
	{
		if( $tcname_got )
			$testcase_got=enum_get_id_wildcard('testcase',$tcname_got);
		$data=search_waiver(0,array('testcase_id'=>$testcase_got,'explanation'=>$expl_got,'bug_id'=>$bugs_got));
		table_htmlspecialchars($data);
		table_translate($data,array(
			'enums'=>array('testcase_id'=>'testcase'),
			'links'=>array('waiver_id'=>'waiver.php?view=vw&waiver_id='),
			'user_ctrls'=>array(
				'edit'=>'waiver.php?view=ew&waiver_id=',
				'delete'=>"confirm.php?confirm=w&view=sw&waiver_id="
			)
		));
		print html_table($data,array('id'=>'waiver','sort'=>'ssss','class'=>'tbl controls'));
	}
}
else if( $view=='sd' )
{	# waiver details search & list
	get_detail();
	array_unshift($match,array('null','&lt;any&gt;'));
	$what=array(
		array('product',$product,$product_got,MULTI_SELECT),
		array('release',$release,$release_got,MULTI_SELECT),
		array('arch',$arch,$arch_got,MULTI_SELECT),
		array('matchtype',$match,$match_got,SINGLE_SELECT),
		array('view','',$view,HIDDEN)
	);
	print html_search_form('waiver.php',$what);

	if( $search )
	{
		$data=search_waiver(1,array('product_id'=>$product_got,'release_id'=>$release_got,'arch_id'=>$arch_got,'matchtype'=>$match_got));
		table_translate($data,array(
			'links'=>array(
				'waiver_testcase_id'=>'waiver.php?view=ed&waiver_testcase_id=',
				'waiver_id'=>'waiver.php?view=vw&waiver_id='
			),
			'enums'=>array(
				'testcase_id'=>'testcase',
				'product_id'=>'product',
				'release_id'=>'release',
				'arch_id'=>'arch'
			),
			'user_ctrls'=>make_detail_controls()
		));
		print html_table($data,array('id'=>'details','sort'=>'ssisssi','class'=>'tbl controls'));
	}

}
else if( $view=='nw' || $view=='ew' )
{	# insert /  update a waiver - form
	get_waiver();
	if( $waiver_id )
	{
		$data=search_waiver(0,array('waiver_id'=>$waiver_id,'header'=>0));
		if( count($data) )
		{
			$testcase_got=$data[0]['testcase_id'];
			$bugs_got=$data[0]['bug_id'];
			$expl_got=$data[0]['explanation'];
			$tcse=$testcase_got;
		}
	}
	$testcase=enum_list_id_val('testcase');
	$wtoken=token_generate();
	$what=array(
		array('waiver_id','',$waiver_id,HIDDEN),
		array('testcase',$testcase,$testcase_got,SINGLE_SELECT),
		array('bug_id','',$bugs_got,TEXT_ROW,'bug ID'),
		array('explanation','',$expl_got,TEXT_AREA,'explanation'),
		array('submit','','waiver',HIDDEN),
		array('view','','vw',HIDDEN),
		array('wtoken','',$wtoken,HIDDEN)
	);
	print html_search_form('waiver.php',$what);
}
else if( $view=='vw' )
{	# print waiver info, list details
	if( $waiver_id )
	{
		print "<h3>Waiver info</h3>\n";
		print_waiver_info($waiver_id);
		print "<h3>Details</h3>\n";
		$data=search_waiver(2,array('waiver_id'=>$waiver_id));
		table_translate($data,array(
			'enums'=>array(
				'product_id'=>'product',
				'release_id'=>'release',
				'arch_id'=>'arch'
			),
			'user_ctrls'=>make_detail_controls()
		));
		print html_table($data,array('id'=>'details','sort'=>'isssi','class'=>'tbl controls'));
		print '<p><a class="btn" href="waiver.php?view=nd&amp;waiver_id='.$waiver_id.'">add detail</a></p>'."\n";
	}
	else
		print "Wrong input data.<br/>\n";
}
else if( $view=='nd' || $view=='ed' )
{	# insert / update a waiver detail - form
	get_detail();
	array_unshift($arch,array('null','&lt;any&gt;'));
	$match_got='problem';
	if( $waiver_testcase_id )
	{
		$waiver_id=waiver_get_master($waiver_testcase_id);
		$data=search_waiver(1,array('waiver_testcase_id'=>$waiver_testcase_id,'header'=>0));
		if( count($data) )
		{
			$product_got=$data[0]['product_id'];
			$release_got=$data[0]['release_id'];
			$arch_got=$data[0]['arch_id'];
			$match_got=$data[0]['matchtype'];
		}
	}
	$wtoken=token_generate();
	$what=array(
		array('product',$product,$product_got,SINGLE_SELECT),
		array('release',$release,$release_got,SINGLE_SELECT),
		array('arch',$arch,$arch_got,SINGLE_SELECT),
		array('matchtype',$match,$match_got,SINGLE_SELECT),
		array('waiver_id','',$waiver_id,HIDDEN),
		array('waiver_testcase_id','',$waiver_testcase_id,HIDDEN),
		array('submit','','waiver_detail',HIDDEN),
		array('view','','vw',HIDDEN),
		array('wtoken','',$wtoken,HIDDEN)
	);
	print html_search_form('waiver.php',$what);

	print "<br/>\n";
	print_waiver_info($waiver_id);
}
else if( $view=='nwd' )
{
	get_waiver();
	get_detail();
	$wtoken=token_generate();
	$testcase=enum_list_id_val('testcase');
	if( is_null($detail_got) )
		$detail_got=1;
	if( is_null($match_got) )
		$match_got='problem';
	$what=array(
		array('testcase',$testcase,$testcase_got,SINGLE_SELECT),
		array('bug_id','',$bugs_got,TEXT_ROW,'bug ID'),
		array('explanation','',$expl_got,TEXT_AREA,'explanation'),
		array('','','',HR),
		array('detail','',$detail_got,CHECKBOX),
		array('product',$product,$product_got,SINGLE_SELECT),
		array('release',$release,$release_got,SINGLE_SELECT),
		array('arch',$arch,$arch_got,SINGLE_SELECT),
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
	global $bugs_got,$expl_got,$testcase_got,$tcname_got;
	$bugs_got=http('bug_id');
	$bugs_got=($bugs_got ? 0+$bugs_got : $bugs_got);
	$expl_got=http('explanation');
	$testcase_got=http('testcase');
	$tcname_got=http('tcname');
	if( $tcname_got && !$testcase_got )
		$testcase_got=enum_get_id('testcase',$tcname_got);
}

function get_detail()
{
	global $product_got,$release_got,$arch_got,$match_got,$detail_got;
	global $product,$release,$arch,$match;
	$product_got=http('product');
	$release_got=http('release');
	$arch_got=http('arch');
	$match_got=http('matchtype');
	$detail_got=http('detail');

	$product=enum_list_id_val('product');
	$release=enum_list_id_val('release');
	$arch=enum_list_id_val('arch');
#	array_unshift($arch,array('','<any>'));
	$match=array(array('no problem','no problem'),array('problem','problem'));
}

function print_waiver_info($waiver_id)
{
	$data=search_waiver(0,array('waiver_id'=>$waiver_id));
	enum_translate_table($data,array('testcase_id'=>'testcase'));
	print html_table($data,array());
}

function make_detail_controls()
{
	global $view,$waiver_id;
	return array(
		'edit'=>'waiver.php?view=ed&waiver_testcase_id=',
		'delete'=>"confirm.php?confirm=wd&view=$view&waiver_testcase_id="
	);
}
?>
