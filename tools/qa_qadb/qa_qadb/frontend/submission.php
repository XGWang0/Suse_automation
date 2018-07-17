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

?>
<script type="text/javascript">
	var from_cal, to_cal;
	addEventListener('load',function() {
		from_cal = new Epoch('epoch_popup','popup',document.getElementsByName('date_from')[0]);
		to_cal   = new Epoch('epoch_popup','popup',document.getElementsByName('date_to')[0]);
	},false);
</script> <?php

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

	# products and releases  get alphanumerically sorted
	usort($product,'compare_alnum');
	usort($release,'compare_alnum');

	$nothing=array( null, '' );
	array_unshift($status,$nothing);
	array_unshift($kernel_version,$nothing);
	array_unshift($kernel_branch,$nothing);
	array_unshift($kernel_flavor,$nothing);
	$product_got		=http('product');
	$release_got		=http('release');
	$arch_got		=http('arch');
	$testsuite_got		=http('testsuite');
	$testsuite_ex_got	=http('testsuite_ex');
	$host_got		=http('host');
	$date_from_got		=http('date_from');
	$date_to_got		=http('date_to');
	$testcase_got		=http('testcase');
	$tester_got		=http('tester');
	$comment_got		=http('comment');
	$rpm_config_id_got	=http('rpm_config_id');
	$hwinfo_id_got		=http('hwinfo_id');
	$status_got		=http('status');
	$md5sum_got		=http('md5sum');
	$patch_id_got		=http('patch_id');
	$issuer_id_got		=http('issuer_id');
	$issue_id_got		=http('issue_id');
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

	$issuer_id=array(
		array( "","" ),
		array( "SUSE", "SUSE" ),
		array( "openSUSE", "openSUSE"),
	);

	# create the form
	$what=array(
		array('product',$product,$product_got,MULTI_SELECT),
		array('release',$release,$release_got,MULTI_SELECT),
		array('arch',$arch,$arch_got,MULTI_SELECT),
		array('host',$host,$host_got,MULTI_SELECT),
		array('tester',$tester,$tester_got,MULTI_SELECT),
		array('date_from','',$date_from_got,TEXT_ROW),
		array('date_to','',$date_to_got,TEXT_ROW),
		array('comment','',$comment_got,TEXT_ROW,'comment [%]','For comments begining XXX, use&#10;XXX%&#10;For comments containing XXX anywhere inside, use&#10;%XXX%'),
		array('submission_id','',$submission_id,TEXT_ROW),
		array('issuer_id',$issuer_id,$issuer_id_got,SINGLE_SELECT),
		array('issue_id','',$issue_id_got,TEXT_ROW),
		array('md5sum','',$md5sum_got,TEXT_ROW,'MD5sum / request ID'),
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
		array_splice($what,5,0,array(
			array('testcase','',$testcase_got,TEXT_ROW,'testcase(s) (slow) [%]','For testcases beginning XXX, use&#10;XXX%&#10;NOTE: using this filter causes much more data to be processed, and may make your system busy for some time.'),
		));
	else if( $step=='bench' )
	{
		array_splice($what,5,0,array(
			array('testsuite',bench_list_testsuite(),$testsuite_got,MULTI_SELECT)
			));
		$pager = null; # cannot use pager as the whole table is a form
	}
	else if( $step=='reg' )
	{
		$group_by_y_got = http('group_by_y',2);
		$group_by_x_got = http('group_by_x',1);
		$reg_method_got = http('reg_method',3);
		$cell_text_got	= http('cell_text',2);
		$cell_color_got = http('cell_color',1);
		$no_footer_got	= http('no_footer');

		$group_by_y = array(
			array(2,'testsuite'),
			array(1,'testsuite + testcase'),
			/* array(3,'submission'), - not implemented */
		);
		$group_by_x = array(
			array(1,'product + release'),
			array(2,'submission'),
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
		$what[]=array('group_by_y',$group_by_y,$group_by_y_got,SINGLE_SELECT,'rows');
		$what[]=array('group_by_x',$group_by_x,$group_by_x_got,SINGLE_SELECT,'columns');
		$what[]=array('reg_method',$reg_method,$reg_method_got,SINGLE_SELECT,'regression method');
		$what[]=array('cell_text',$cell_text,$cell_text_got,SINGLE_SELECT);
		$what[]=array('cell_color',$cell_color,$cell_color_got,SINGLE_SELECT);
		$what[]=array('no_footer','',$no_footer_got,CHECKBOX);
	}
	else	{
		$what[]=array('submission_type',$modes,$mode_got,SINGLE_SELECT,'submission type');
		array_splice($what,5,0,array(
			array('testsuite_ex',enum_list_id_val('testsuite'),$testsuite_ex_got,MULTI_SELECT,'testsuite')
			));
	}
	if( $step=='tcf' || $step=='reg' )	{
		array_splice($what,5,0,array(
			array('testsuite',enum_list_id_val('testsuite'),$testsuite_got,MULTI_SELECT)
			));

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
	print steps(form_to_url($dir.'submission.php',$what0,0).'&amp;step=',$steps,$step);
}

# main content
if(!$submission_id)
{
	# main search form
	$what[] = array('step','',$step,HIDDEN);
	print html_search_form($dir.'submission.php',$what);

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
			'testsuite_eid'		=>$testsuite_ex_got,
			'testcase'		=>$testcase,
			'tester_id'		=>$tester_got,
			'comment'		=>$comment_got,
			'rpm_config_id'		=>$rpm_config_id_got,
			'hwinfo_id'		=>$hwinfo_id_got,
			'submission_id'		=>$submission_id,
			'status_id'		=>$status_got,
			'md5sum'		=>$md5sum_got,
			'patch_id'		=>$patch_id_got,
			'issuer_id'		=>$issuer_id_got,
			'issue_id'		=>$issue_id_got,
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
			$is_tc=($group_by_y_got!=2);
			$group_submissions=($group_by_x_got==2);
			$footer=($no_footer_got ? null: array());
			$data = extended_regression($is_tc,$group_submissions,$reg_method_got,$attrs,$footer,$transl,$pager);
			$sort=str_repeat('s',($is_tc ? 2:1));
			if( count($data) > 1 )	{
				$sort.=str_repeat(($cell_text_got==2 ? 'i':'s'),count($data[0])-strlen($sort));
			}
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
				print '<form action="'.$dir.'benchmarks.php" method="get" name="bench_form">'."\n";
			$class.=' controls';
		}
		table_translate($data,$transl); 
		if( $mode_got==3 ) # KOTD external links, linked by value instead of ID, need translating here
			table_translate($data,array('links'=>array('kernel_branch_id'=>'http://kerncvs.suse.de/kernel-overview/?b=')));

		if( isset($footer) )
			$data=array_merge($data,$footer);
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
	if(1)	{
		# help pages here
		if( $step=='reg' )	{
			print "This is an aggreagated overview over multiple data submissions.<br/>\n";
			print "<b>Rows</b>: whole testsuites, or individual testcases<br/>\n";
			print "<b>Columns</b>: product/release, or individual submissions<br/>\n";
			print "<b>Regression method</b>: rows to show - with differences, with errors, or all<br/>\n";
			print "<b>Cell text/color</b>: methods showing how many test runs succeeded/failed<br/>\n";
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
		print html_search_form($dir.'submission.php',$what);
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
	print html_search_form($dir.'submission.php',$what);
}
else if( $submission_id)
{	# detail list
	echo "<h1>Details for submission $submission_id</h1>\n";
	$detail1=print_submission_details($submission_id);
	if( count($detail1) > 1 )
	{
		echo "<div class=\"screen allresults\">&rarr; See ";
		$base1=$dir."result.php?submission_id=$submission_id&search=1";
		$base2=$dir."confirm.php?submission_id=$submission_id";
		$base3=$dir."submission.php?submission_id=$submission_id";
		echo html_text_button('all results',$base1);
		echo html_text_button('RPM list',$dir."rpms.php?rpm_config_id=".$detail1[1]['rpm_config_id']);
		echo html_text_button('hwinfo',$dir."hwinfo.php?hwinfo_id=".$detail1[1]['hwinfo_id']);
		echo "</div>\n";
		echo "<div class=\"screen\">\n";
		echo "<div class=\"controls\">Controls :";
		echo html_user_button('edit comment/status/related/ref',"$base3&action=edit");
		echo html_user_button('delete submission',"$base2&confirm=s");
		echo "</div>\n</div>\n";
		echo "<h2>Included testsuites</h2>\n";
		$data=tcf_details($submission_id,0);
		table_translate($data,array(
			'user_ctrls'=>array(
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

/**
  * To be called by usort()
  * @param $p1,$p2 : array( id, name )
  * @return -1,0,1 for $p1 <,==,> $p2
  **/
function compare_alnum($p1,$p2)
{
	$n1=preg_replace('/-/','',$p1[1]);
	$n2=preg_replace('/-/','',$p2[1]);
	return -strnatcasecmp($n1,$n2);
}


?>
