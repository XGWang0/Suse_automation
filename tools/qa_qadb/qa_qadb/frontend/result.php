<?php
require_once("qadb.php");


$submission_id=$submission_id_got=http('submission_id');
$testsuite_id=http('testsuite_id');
$tcf_id=http('tcf_id');
$search=http('search');
$pager=pager_fill_from_http();
$status_got=http('status');

common_header(array('title'=>'test results'));

if( $tcf_id && !$submission_id )
	$submission_id = tcf_get_submission($tcf_id);

$status=array(
	array('','all'),
	array(1,'fail+interr+skip'),
	array(2,'success'),
	array(3,'fail'),
	array(4,'interr'),
	array(5,'skip'),
);

# submission_id search form
$what0=$what=array(
	array('submission_id','',$submission_id_got,TEXT_ROW),
	array('testsuite_id',enum_list_id_val('testsuite'),$testsuite_id,MULTI_SELECT),
	array('tcf_id','',$tcf_id,TEXT_ROW),
);
$what[]=array('status',$status,$status_got,SINGLE_SELECT);
$pager['what'] = $what;

print html_search_form('result.php',$what);

if( $submission_id )
{
	if( $testsuite_id )
	{
		$ts=enum_get_val_array('testsuite',$testsuite_id);
		echo "<h2>Results from submission_id $submission_id for testsuite(s) ".join(',',$ts)."</h2>\n";
	}
	else if( $tcf_id )
		echo "<h2>Results for tcf_id $tcf_id</h2>\n";
	else
		echo "<h2>All results from submission_id $submission_id</h2>\n";
	echo "<span class=\"screen\">".html_link('View submission details',"submission.php?submission_id=$submission_id")."</span>";

	# submission details
	$sub_info=print_submission_details($submission_id);
	echo "<br/>\n";

	$transl=array();

	# base arguments
	$args_base=array(
		'submission_id'=>$submission_id_got,
		'testsuite_id'=>$testsuite_id, 
		'tcf_id'=>$tcf_id, 
	);

	# status argumetns
	$args_status=array(
		'has_nosucc'=>($status_got==1),
		'has_succ'=>($status_got==2),
		'has_fail'=>($status_got==3),
		'has_interr'=>($status_got==4),
		'has_skip'=>($status_got==5),
		'order_by'=>'result_id',
	);
	
	# legend
	$url=form_to_url('?',$what0);
	$legend=array(
		'all'=>array('',''),
		'succ'=>array(2,'i'),
		'fail'=>array(3,'failed'),
		'interr'=>array(4,'internalerr'),
		'skip'=>array(5,'skipped')
	);
	print 'Status counts: <table class="tbl">'."\n\t<tr>";
	foreach($legend as $status=>$v)	{
		list($val,$style)=$v;
		$key='has_'.$status;
		$args=$args_base;
		$args['count']=1;
		if( $val )
			$args[$key]=1;
		$cnt = search_submission_result( 0, $args );
		print '<td class="'.$style.'">'.html_link("$status: $cnt","$url&status=$val")."</td>";
	}
	print "</tr>\n</table>\n";

	# main data
	$args=array_merge($args_base,$args_status);
	$data  = search_submission_result( 0, $args, $transl, $pager );
	result_process_print($data,$sub_info,$transl,$pager,'reslist');

}
else if($search && $testsuite_id)
	print html_error('NOTE: At least one of "Submission_id" and "Tcf_id" must be set.');

print html_footer();
exit();


?>
