<?php
require_once("qadb.php");


$submissionID=$submissionID_got=http('submissionID');
$testsuiteID=http('testsuiteID');
$tcfID=http('tcfID');
$search=http('search');
$pager=pager_fill_from_http();

common_header(array('title'=>'test results'));

if( $tcfID && !$submissionID )
	$submissionID = tcf_get_submission($tcfID);

# submissionID search form
$what=array(
	array('submissionID','',$submissionID_got,TEXT_ROW),
	array('testsuiteID',enum_list_id_val('testsuites'),$testsuiteID,MULTI_SELECT),
	array('tcfID','',$tcfID,TEXT_ROW)
);
$pager['what'] = $what;

print html_search_form('results.php',$what);

if( $submissionID )
{
	if( $testsuiteID )
	{
		$ts=enum_get_val_array('testsuites',$testsuiteID);
		echo "<h2>Results from submissionID $submissionID for testsuite(s) ".join(',',$ts)."</h2>\n";
	}
	else if( $tcfID )
		echo "<h2>Results for tcfID $tcfID</h2>\n";
	else
		echo "<h2>All results from submissionID $submissionID</h2>\n";
	echo "<span class=\"screen\">".html_link('View submission details',"submission.php?submissionID=$submissionID")."</span>";

	# submission details
	$sub_info=print_submission_details($submissionID);
	echo "<br/>\n";

	# results
	$transl=array();
	$args=array(
		'submissionID'=>$submissionID_got,
		'testsuiteID'=>$testsuiteID, 
		'tcfID'=>$tcfID, 
	);
	$data  = search_submissions_results( 0, $args, $transl, $pager );
	results_process_print($data,$sub_info,$transl,$pager,'reslist');
}
else if($search && $testsuiteID)
	print html_error('NOTE: At least one of "SubmissionID" and "TcfID" must be set.');

print html_footer();
exit();


?>
