<?php
require_once('qadb.php');
require_once('defs.php');
$pager  = pager_fill_from_http();
common_header(array(
    'title'=>'QADB submissions',
    'id'=>'sub_html',
    'calendar'=>1
));

# read main CGI variables
$submissionID=http('submissionID');
$mode_got=http('submission_type',null);
$search = http('search');
$action = http('action');
$submit = http('submit');
$tcfID  = http('tcfID');
$step   = http('step');
$what0   = array();

# commit changes
if( token_read(http('wtoken')) )
{	
	if( $submit=='delete_tcf' && $tcfID )
	{
		transaction();
		update_result( tcf_delete($submissionID,$tcfID) ); 
		commit();
	}
	else if( $submit=='delete_submission' && $submissionID )
	{
		transaction();
		update_result( submission_delete($submissionID) ); 
		commit();
		$submissionID=null;
		$search=null;
	}
	else if( $submit=='comment' && $submissionID )
	{
		$active =http('active') ? 1:0;
		$related=http('related');
		$related=$related ? $related:null;
		$comment=http('comment');
		if( $related  && !search_submissions_results(1,array('submissionID'=>$related,'only_id'=>1,'header'=>0)))
		{	
			print html_error("No such submissionID: $related");	
			$related=null;
		}
		update_result( submission_set_details($submissionID,$active,$related,$comment) ); 
	}
	else if( $submit=='link' && $tcfID )
	{
		$url=http('url');
		update_result( tcf_set_url($tcfID, set($url) ? $url:null) );
	}
}

if(!$submissionID)
{	# main search form & results
	$products  =enum_list_id_val('products'); 
	$releases  =enum_list_id_val('releases');
	$archs     =enum_list_id_val('architectures'); 
	$hosts	   =enum_list_id_val('hosts');
	$testers   =enum_list_id_val('testers');
	$products_got    =http('products');
	$releases_got    =http('releases');
	$archs_got       =http('architectures');
	$testsuites_got  =http('testsuites');
	$hosts_got       =http('hosts');
	$date_from_got   =http('date_from');
	$date_to_got     =http('date_to');
	$testcases_got   =http('testcases');
	$active_got      =http('active');
	$testers_got     =http('testers');
	$comment_got     =http('comment');
	$configID_got    =http('configID');
	$hwinfoID_got    =http('hwinfoID');
	$submissionID_got=http('submissionID');

	# create the form
	$what=array(
		array('products',$products,$products_got,MULTI_SELECT),
		array('releases',$releases,$releases_got,MULTI_SELECT),
		array('architectures',$archs,$archs_got,MULTI_SELECT),
#		array('testsuites',$testsuites,$testsuites_got,MULTI_SELECT),
		array('hosts',$hosts,$hosts_got,MULTI_SELECT),
		array('testers',$testers,$testers_got,MULTI_SELECT),
		array('date_from','',$date_from_got,TEXT_ROW),
		array('date_to','',$date_to_got,TEXT_ROW),
		array('active','',$active_got,TEXT_ROW),
		array('comment','',$comment_got,TEXT_ROW,'comment [%]'),
		array('submissionID','',$submissionID_got,TEXT_ROW),
	);
	$what0=$what;

	# modes for submission select
	$modes=array(
		array( 1, "just submissions"),
		array( 3, "kotd"), 
		array( 4, "Product Testing"), 
		array( 2, "Maintenance Testing"), 
		array( 5, "Any")
	);

	# card-dependent form fields
	if( $step=='tcf' )
		array_splice($what,5,0,array(
			array('testsuites',enum_list_id_val('testsuites'),$testsuites_got,MULTI_SELECT),
			array('testcases','',$testcases_got,TEXT_ROW,'testcase(s) (slow) [%]'),
		));
	else if( $step=='bench' )
	{
		array_splice($what,5,0,array(
			array('testsuites',bench_list_testsuites(),$testsuites_got,MULTI_SELECT),
		));
		$pager = null; # cannot use pager as the whole table is a form
	}
	else
		$what[]=array('submission_type',$modes,$mode_got,SINGLE_SELECT,'submission type');
}

# cardset
$mode=0;
$steps=array(
	array('submissions','sub'),
	array('TCFs','tcf'),
	array('benchmarks','bench')
);
for( $i=0; $i<count($steps); $i++ )
{
	if( $steps[$i][1] == $step )
		$mode=$i;
#	$steps[$i][1]='submission.php?step='.$steps[$i][1];
}
print steps(form_to_url('submission.php',$what0,0).'&amp;step=',$steps,$mode);

# main content
if(!$submissionID)
{
	# main search form
	$what[] = array('step','',$step,HIDDEN);
	print html_search_form('submission.php',$what);

	# print search results
	echo '<div class="data">'."\n";
	if( $search )
	{
		$pager['what'] = $what;
		$testcases= field_split($testcases_got);
		if(! ($mode_got>=2 && $mode_got<=5) )
			$mode_got=1;
		if( $step=='tcf' )  $mode_got=8;
		if( $step=='bench') $mode_got=9;
		if( $testcases && $testcases[0] )    $mode_got=10;
		$transl=array();
		$data=search_submissions_results($mode_got,array(
			'archID'      =>$archs_got,
			'productID'   =>$products_got,
			'releaseID'   =>$releases_got,
			'hostID'      =>$hosts_got,
			'date_from'   =>$date_from_got,
			'date_to'     =>$date_to_got,
			'testsuiteID' =>$testsuites_got,
			'testcase'    =>$testcases,
			'active'      =>$active_got,
			'testerID'    =>$testers_got,
			'comment'     =>$comment_got,
			'configID'    =>$configID_got,
			'hwinfoID'    =>$hwinfoID_got,
			'submissionID'=>$submissionID_got,
			'order_nr'    =>-1
		),$transl,$pager);
		$sort='sssssssis'.str_repeat('s',count($data[0])-9);
		$class='tbl';
		if( $step=='bench' )
		{
			table_add_checkboxes($data,'tests[]','tcfID',1,'bench_form',1);
			if( count($data)>1 )
				print '<form action="benchmarks.php" method="get" name="bench_form">'."\n";
			$class.=' controls';
		}
		table_translate($data,$transl); 
		if( $mode_got==3 ) # KOTD external links
			table_translate($data,array('links'=>array('branchID'=>'http://kerncvs.suse.de/kernel-overview/?b=')));
		print html_table($data,array('id'=>'submission','sort'=>$sort,'total'=>true,'class'=>$class,'pager'=>$pager));
		if( $step=='bench' && count($data)>1 )
		{
			$legend=array( array(0,'in the graph'), array(1,'next to the graph') );
			$fontsize=array( array(1,1),array(2,2),array(3,3),array(4,4),array(5,5) );
			$what=array(
				array('group_by',$group_by,http('group_by',0),SINGLE_SELECT),
				array('graph_x','',http('graph_x',$bench_def_width),TEXT_ROW,'graph width'),
				array('graph_y','',http('graph_y',$bench_def_height),TEXT_ROW,'graph height'),
				array('legend_pos',$legend,http('legend_pos',$bench_def_pos),SINGLE_SELECT),
				array('font_size',$fontsize,http('font_size',$bench_def_font),SINGLE_SELECT),
			);
			print html_search_form(null,$what,array('form'=>false,'submit'=>'Graphs','div'=>'screen'));
			print "</form>\n";
		}
	}
	echo "</div>\n";
}
else if( $action=='edit' )
{	# detail edit form
	$detail=print_submission_details($submissionID);
	if( count($detail) > 1 )
	{
		$comment=$detail[1]['comment'];
		$related=$detail[1]['related'];
		$active=$detail[1]['active'];
		$what=array(
			array('active','',$active,CHECK_BOX),
			array('comment','',$comment,TEXT_AREA),
			array('related','',$related,TEXT_ROW),
			array('submissionID','',$submissionID,HIDDEN),
			array('submit','','comment',HIDDEN),
			array('wtoken','',token_generate(),HIDDEN)
		);
		print "<h2>Editing submission $submissionID</h2>\n";
		print html_search_form('submission.php',$what);
	}
#	print "<h3>
}
else if( $action=='edit_link' && $submissionID && $tcfID )
{
	# edit link to logs
	echo "<h3>Submission details</h3>\n";
	$detail1=print_submission_details($submissionID);
	echo "<h3>TCF details</h3>\n";
	$detail2=print_tcf_details($tcfID);
	$what=array(
		array('url','',$detail2[1]['logs_url'],TEXT_ROW),
		array('submissionID','',$submissionID,HIDDEN),
		array('tcfID','',$tcfID,HIDDEN),
		array('submit','','link',HIDDEN),
		array('wtoken','',token_generate(),HIDDEN),
	);
	print "<h2>Editing link to logs</h2>\n";
	print html_search_form('submission.php',$what);
}
else if( $submissionID)
{	# detail list
	echo "<h1>Details for submission $submissionID</h1>\n";
	$detail1=print_submission_details($submissionID);
	if( count($detail1) > 1 )
	{
		echo "<div class=\"screen allresults\">&rarr; See ";
		$base1="results.php?submissionID=$submissionID&search=1";
		$base2="confirm.php?submissionID=$submissionID";
		$base3="submission.php?submissionID=$submissionID";
		echo html_text_button('all results',$base1);
		echo html_text_button('RPM list',"rpms.php?configID=".$detail1[1]['configID']);
		echo html_text_button('hwinfo',"hwinfo.php?hwinfoID=".$detail1[1]['hwinfoID']);
		echo "</div>\n";
		echo "<div class=\"screen\">\n";
		echo "<div class=\"controls\">Controls :";
		echo html_text_button('edit comment/active/related',"$base3&action=edit");
		echo html_text_button('delete submission',"$base2&confirm=s");
		echo "</div>\n</div>\n";
		echo "<h2>Included testsuites</h2>\n";
		$data=tcf_details($submissionID,0);
		table_translate($data,array(
			'ctrls'=>array(
				'delete'=>"$base2&confirm=sd&tcfID=",
				'edit log URL'=>"$base3&action=edit_link&tcfID=",
			),
			'links'=>array(
				'tcfID'=>"$base1&tcfID=",
				'testsuiteID'=>"$base1&testsuiteID=",
			),
			'urls'=>array( 'logs_url'=>'logs' ),
			'enums'=>array('testsuiteID'=>'testsuites'),
		));
		print html_table($data,array('id'=>'tcf','sort'=>'hhiiiiiiih','class'=>'tbl controls'));
	}
}
print "</div>\n";
print html_footer();
exit;










?>
