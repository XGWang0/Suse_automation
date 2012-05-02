<?php
require_once("qadb.php");


$submission_id=$submission_id_got=http('submission_id');
$testsuite_id=http('testsuite_id');
$tcf_id=http('tcf_id');
$search=http('search');
$pager=pager_fill_from_http();

common_header(array('title'=>'test results'));

if( $tcf_id && !$submission_id )
	$submission_id = tcf_get_submission($tcf_id);

# submission_id search form
$what=array(
	array('submission_id','',$submission_id_got,TEXT_ROW),
	array('testsuite_id',enum_list_id_val('testsuite'),$testsuite_id,MULTI_SELECT),
	array('tcf_id','',$tcf_id,TEXT_ROW)
);
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

	# results
	$transl=array();
	$args=array(
		'submission_id'=>$submission_id_got,
		'testsuite_id'=>$testsuite_id, 
		'tcf_id'=>$tcf_id, 
	);
	$data  = search_submission_result( 0, $args, $transl, $pager );
	result_process_print($data,$sub_info,$transl,$pager,'reslist');
}
else if($search && $testsuite_id)
	print html_error('NOTE: At least one of "Submission_id" and "Tcf_id" must be set.');

print html_footer();
exit();


?>
