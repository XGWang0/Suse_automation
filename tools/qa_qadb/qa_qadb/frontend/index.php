<?php
require_once('qadb.php');
common_header(array('title'=>'Welcome to the QA database'));
print "<center><h2>Welcome to the QA database</h2>\n";

$update_link='';
if ( !isset($_SESSION['user'] ) )
	printf("you are currently not loged in<br><br>");
else
{
	printf("you are currently loged in as <i><b>%s</b></i><br/><br/>", $_SESSION['user']);
	$update_link='<div class="screen space"><a href="index.php?update_stats=1">Update testcase stats (takes a long time)</a></div>';
}
$last_sub=row_query(array(1), "SELECT submissionID, submission_date FROM submissions ORDER BY submission_date DESC");
$num_tr=scalar_query("SELECT MAX(resultsID) FROM results");
$num_prod=scalar_query("SELECT COUNT(distinct productID, releaseID) FROM submissions;");
$num_sub=scalar_query("SELECT COUNT(*) FROM submissions;");
$num_testsuites=enum_count('testsuites');
$num_testcases =enum_count('testcases');
$schema_version=schema_get_version();

$tbl=array(
	array('we currently serve',''),
	array($num_tr,'results records on'),
	array($num_sub,'submissions for'),
	array($num_prod,'products'),
	array($num_testsuites,'testsuites'),
	array($num_testcases,'testcases'),
	array('Last submission:',$last_sub[1]." ID=".$last_sub[0]),
	array('DB schema version:',$schema_version),
);
print html_table($tbl,array('class'=>'overview','header'=>0,'evenodd'=>false));

if( http('update_stats') )
{
	printf("Updating stats ...");
	update_result(update_test_statistics());
	printf("Done.");
}
else
	printf($update_link);

print "</center>\n";
?>
</body>
</html>

