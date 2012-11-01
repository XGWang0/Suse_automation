<?php
require_once('qadb.php');
require_once('defs.php');
$embed=http('embed');
$pager  = pager_fill_from_http();
common_header(array(
    'title'=>'QADB submissions',
    'id'=>'sub_html',
    'calendar'=>1,
    'embed'=>$embed,
));

define('AGR_MAX_RES','15000');

# read main CGI variables
$submission_id=http('submission_id');
$mode_got=http('submission_type',null);
$search = http('search');
$action = http('action');
$submit = http('submit');
$tcf_id  = http('tcf_id');
$step   = http('step','sub');
$what0   = array();

# commit changes
if( token_read(http('wtoken')) )
{	
	if( $submit=='delete_tcf' && $tcf_id )
	{
		transaction();
		update_result( tcf_delete($submission_id,$tcf_id) ); 
		commit();
	}
	else if( $submit=='delete_submission' && $submission_id )
	{
		transaction();
		update_result( submission_delete($submission_id) ); 
		commit();
		$submission_id=null;
		$search=null;
	}
	else if( $submit=='comment' && $submission_id )
	{
		$status_id=http('status');
		$related=http('related');
		$related=$related ? $related:null;
		$comment=http('comment');
		$ref=http('ref') ? 'R' : '';
		if( $related  && !search_submission_result(1,array('submission_id'=>$related,'only_id'=>1,'header'=>0)))
		{	
			print html_error("No such submission_id: $related");	
			$related=null;
		}
		update_result( submission_set_details($submission_id,$status_id,$related,$comment,$ref) ); 
	}
	else if( $submit=='link' && $tcf_id )
	{
		$url=http('url');
		update_result( tcf_set_url($tcf_id, set($url) ? $url:null) );
	}
}

if(!$submission_id)
{	# main search form & results
	$product	=enum_list_id_val('product'); 
	$release	=enum_list_id_val('release');
	$arch		=enum_list_id_val('arch'); 
	$host		=enum_list_id_val('host');
	$tester		=enum_list_id_val('tester');
	$status		=enum_list_id_val('status');
	$kernel_version	=enum_list_id_val('kernel_version');
	$kernel_branch	=enum_list_id_val('kernel_branch');
	$kernel_flavor	=enum_list_id_val('kernel_flavor');
	$nothing=array( null, '' );
	array_unshift($status,$nothing);
	array_unshift($kernel_version,$nothing);
	array_unshift($kernel_branch,$nothing);
	array_unshift($kernel_flavor,$nothing);
	$product_got		=http('product');
	$release_got		=http('release');
	$arch_got		=http('arch');
	$testsuite_got		=http('testsuite');
	$host_got		=http('host');
	$date_from_got		=http('date_from');
	$date_to_got		=http('date_to');
	$testcase_got		=http('testcase');
	$tester_got		=http('tester');
	$comment_got		=http('comment');
	$rpm_config_id_got	=http('rpm_config_id');
	$hwinfo_id_got		=http('hwinfo_id');
	$submission_id_got	=http('submission_id');
	$status_got		=http('status');
	$md5sum_got		=http('md5sum');
	$patch_id_got		=http('patch_id');
	$kernel_version_got	=http('kernel_version');
	$kernel_branch_got	=http('kernel_branch');
	$kernel_flavor_got	=http('kernel_flavor');
	$refhost_got		=http('refhost');
	$ref_got		=http('ref');

	# modes for submission select
	$modes=array(
		array( 1, "just submissions"),
		array( 3, "kotd"), 
		array( 4, "Product Testing"), 
		array( 2, "Maintenance Testing"), 
		array( 5, "Any")
	);

	# create the form
	$what=array(
		array('product',$product,$product_got,MULTI_SELECT),
		array('release',$release,$release_got,MULTI_SELECT),
		array('arch',$arch,$arch_got,MULTI_SELECT),
#		array('testsuite',$testsuite,$testsuite_got,MULTI_SELECT),
		array('host',$host,$host_got,MULTI_SELECT),
		array('tester',$tester,$tester_got,MULTI_SELECT),
		array('testsuite',enum_list_id_val('testsuite'),$testsuite_got,MULTI_SELECT),
		array('date_from','',$date_from_got,TEXT_ROW),
		array('date_to','',$date_to_got,TEXT_ROW),
		array('comment','',$comment_got,TEXT_ROW,'comment [%]'),
		array('submission_id','',$submission_id_got,TEXT_ROW),
		array('md5sum','',$md5sum_got,TEXT_ROW),
		array('patch_id','',$patch_id_got,TEXT_ROW),
		array('status',$status,$status_got,SINGLE_SELECT),
		array('kernel_version',$kernel_version,$kernel_version_got,SINGLE_SELECT),
		array('kernel_branch',$kernel_branch,$kernel_branch_got,SINGLE_SELECT),
		array('kernel_flavor',$kernel_flavor,$kernel_flavor_got,SINGLE_SELECT),
		array('refhost','',$refhost_got,CHECKBOX,'ref. host'),
		array('ref','',$ref_got,CHECKBOX,'ref. data'),
	);
	$what0=$what;

	# card-dependent form fields
	if( $step=='tcf' )
		array_splice($what,6,0,array(
			array('testcase','',$testcase_got,TEXT_ROW,'testcase(s) (slow) [%]'),
		));
	else if( $step=='bench' )
	{
		$what[5]=array('testsuite',bench_list_testsuite(),$testsuite_got,MULTI_SELECT);
		$pager = null; # cannot use pager as the whole table is a form
	}
	else if( $step=='reg' )
	{
		$group_by_got = http('group_by',2);
		$reg_method_got = http('reg_method',1);
		$cell_text_got = http('cell_text',1);
		$cell_color_got = http('cell_color',1);

		$group_by = array(
			array(2,'testsuite'),
			array(1,'testsuite + testcase'),
		);
		$reg_method = array(
			array(1,'different status'),
			array(2,'fail+interr'),
			array(3,'all'),
		);
		$cell_text = array(
			array(1,'status'),
			array(2,'% pass'),
			array(3,'numbers'),
			array(4,'X'),
			array(5,'')
		);
		$cell_color = array(
			array(1,'status'),
			array(2,'RGB'),
			array(3,'grayscale'),
			array(4,''),
		);
		$what[]=array('group_by',$group_by,$group_by_got,SINGLE_SELECT);
		$what[]=array('reg_method',$reg_method,$reg_method_got,SINGLE_SELECT,'regression method');
		$what[]=array('cell_text',$cell_text,$cell_text_got,SINGLE_SELECT);
		$what[]=array('cell_color',$cell_color,$cell_color_got,SINGLE_SELECT);
	}
	else	{
		$what[]=array('submission_type',$modes,$mode_got,SINGLE_SELECT,'submission type');
		array_splice($what,5,1); # TODO: fix testsuites in this tab too
	}
}

# cardset
$mode=0;
if( !$embed )	{
	$steps=array(
		'sub'=>'submissions',
		'tcf'=>'TCFs',
		'bench'=>'benchmarks',
		'reg'=>'ext. regressions'
	);
	print steps(form_to_url('submission.php',$what0,0).'&amp;step=',$steps,$step);
}

# main content
if(!$submission_id)
{
	# main search form
	$what[] = array('step','',$step,HIDDEN);
	print html_search_form('submission.php',$what);

	# print search results
	echo '<div class="data">'."\n";
	if( $search )
	{
		$pager['what'] = $what;
		$testcase= field_split($testcase_got);
		if(! ($mode_got>=2 && $mode_got<=5) )
			$mode_got=1;
		if( $step=='tcf' )  $mode_got=8;
		if( $step=='bench') $mode_got=9;
		if( $testcase && $testcase[0] )    $mode_got=10;
		$transl=array();
		$attrs=array(
			'arch_id'		=>$arch_got,
			'product_id'		=>$product_got,
			'release_id'		=>$release_got,
			'host_id'		=>$host_got,
			'date_from'		=>$date_from_got,
			'date_to'		=>$date_to_got,
			'testsuite_id'		=>$testsuite_got,
			'testcase'		=>$testcase,
			'tester_id'		=>$tester_got,
			'comment'		=>$comment_got,
			'rpm_config_id'		=>$rpm_config_id_got,
			'hwinfo_id'		=>$hwinfo_id_got,
			'submission_id'		=>$submission_id_got,
			'status_id'		=>$status_got,
			'md5sum'		=>$md5sum_got,
			'patch_id'		=>$patch_id_got,
			'kernel_version'	=>$kernel_version_got,
			'kernel_branch'		=>$kernel_branch_got,
			'kernel_flavor'		=>$kernel_flavor_got,
			'order_nr'		=>-1,
		);
		if( $refhost_got )
			$attrs['refhost']=1;
		if( $ref_got )
			$attrs['ref']=1;
		if( $step=='reg' )	{
			unset($attrs['order_nr']);
			$attrs['cell_color']=$cell_color_got;
			$attrs['cell_text']=$cell_text_got;
			$is_tc=($group_by_got!=2);
			$data = extended_regression($is_tc,$reg_method_got,$attrs,$transl,$pager);
			$sort=str_repeat('s',($is_tc ? 2:1));
			$sort.=str_repeat(($cell_text_got==2 ? 'i':'s'),count($data[0])-strlen($sort));
		}
		else	{
			$data=search_submission_result($mode_got,$attrs,$transl,$pager);
			$sort='sssssssis'.str_repeat('s',count($data[0])-9);
		}
		$class='tbl';
		if( $mode_got==10 )
			$transl['enums']['testcase_id']='testcase';
		if( $step=='bench' )
		{
			table_add_checkboxes($data,'tests[]','tcf_id',1,'bench_form',1);
			if( count($data)>1 )
				print '<form action="benchmarks.php" method="get" name="bench_form">'."\n";
			$class.=' controls';
		}
		table_translate($data,$transl); 
		if( $mode_got==3 ) # KOTD external links, linked by value instead of ID, need translating here
			table_translate($data,array('links'=>array('kernel_branch_id'=>'http://kerncvs.suse.de/kernel-overview/?b=')));
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
	$detail=print_submission_details($submission_id);
	if( count($detail) > 1 )
	{
		$row=$detail[1];
		$status=enum_list_id_val('status');
		array_unshift($status,array('null',''));
		$what=array(
			array('status',$status,$row['status_id'],SINGLE_SELECT),
			array('comment','',$row['comment'],TEXT_AREA),
			array('related','',$row['related'],TEXT_ROW),
			array('ref','',$row['ref'],CHECKBOX,'ref. data'),
			array('submission_id','',$submission_id,HIDDEN),
			array('submit','','comment',HIDDEN),
			array('wtoken','',token_generate(),HIDDEN)
		);
		print "<h2>Editing submission $submission_id</h2>\n";
		print html_search_form('submission.php',$what);
	}
#	print "<h3>
}
else if( $action=='edit_link' && $submission_id && $tcf_id )
{
	# edit link to logs
	echo "<h3>Submission details</h3>\n";
	$detail1=print_submission_details($submission_id);
	echo "<h3>TCF details</h3>\n";
	$detail2=print_tcf_details($tcf_id);
	$what=array(
		array('url','',$detail2[1]['log_url'],TEXT_ROW),
		array('submission_id','',$submission_id,HIDDEN),
		array('tcf_id','',$tcf_id,HIDDEN),
		array('submit','','link',HIDDEN),
		array('wtoken','',token_generate(),HIDDEN),
	);
	print "<h2>Editing link to logs</h2>\n";
	print html_search_form('submission.php',$what);
}
else if( $submission_id)
{	# detail list
	echo "<h1>Details for submission $submission_id</h1>\n";
	$detail1=print_submission_details($submission_id);
	if( count($detail1) > 1 )
	{
		echo "<div class=\"screen allresults\">&rarr; See ";
		$base1="result.php?submission_id=$submission_id&search=1";
		$base2="confirm.php?submission_id=$submission_id";
		$base3="submission.php?submission_id=$submission_id";
		echo html_text_button('all results',$base1);
		echo html_text_button('RPM list',"rpms.php?rpm_config_id=".$detail1[1]['rpm_config_id']);
		echo html_text_button('hwinfo',"hwinfo.php?hwinfo_id=".$detail1[1]['hwinfo_id']);
		echo "</div>\n";
		echo "<div class=\"screen\">\n";
		echo "<div class=\"controls\">Controls :";
		echo html_text_button('edit comment/status/related/ref',"$base3&action=edit");
		echo html_text_button('delete submission',"$base2&confirm=s");
		echo "</div>\n</div>\n";
		echo "<h2>Included testsuites</h2>\n";
		$data=tcf_details($submission_id,0);
		table_translate($data,array(
			'ctrls'=>array(
				'delete'=>"$base2&confirm=sd&tcf_id=",
				'edit log URL'=>"$base3&action=edit_link&tcf_id=",
			),
			'links'=>array(
				'tcf_id'=>"$base1&tcf_id=",
				'testsuite_id'=>"$base1&testsuite_id=",
			),
			'urls'=>array( 'log_url'=>'logs' ),
			'enums'=>array('testsuite_id'=>'testsuite'),
		));
		print html_table($data,array('id'=>'tcf','sort'=>'hhiiiiiiih','class'=>'tbl controls','callback'=>'colorize_detail'));
	}
}
if( !$embed )	{
	print "</div>\n";
	print html_footer();
}
else
	print "</body></html>\n";
exit;

function colorize_detail($tcf_id,$testsuite,$testcase,$succ,$fail,$interr,$skip,$runs,$time,$url)	{
	if( $fail )
		return ' failed';
	if( $interr )
		return ' internalerr';
	if( $skip )
		return ' skipped';
	if( $succ )
		return ' i';
}


?>
