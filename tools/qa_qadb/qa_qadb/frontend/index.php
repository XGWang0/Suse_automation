<?php
require_once('qadb.php');
if( !preg_match('/\.php/',$_SERVER['REQUEST_URI']) )    {
	header('Location: submission.php?search=1');
	exit;
}
common_header(array('title'=>'Welcome to the QA database'));
print "<center><h2>Welcome to the QA database</h2>\n";

if( !$auth->hasIdentity() )
	printf("you are currently not loged in<br/><br/>\n");
else	{
	printf("you are currently loged in as <i>%s</i><br/><br/>\n", $auth->getIdentity() );

	if( is_confirmed() )
		printf("you can modify / delete data (including other people's data, be careful)<br/><br/>\n");
	else
		printf("you cannot modify data yet, until admins confirm you<br/><br/>\n");

	if( is_admin() )
		printf("you are QADB administrator<br/><br/>\n");
}
$last_sub=row_query("SELECT submission_id, submission_date FROM submission ORDER BY submission_date DESC");
$num_tr=scalar_query("SELECT MAX(result_id) FROM result");
$num_prod=scalar_query("SELECT COUNT(distinct product_id, release_id) FROM submission;");
$num_sub=scalar_query("SELECT COUNT(*) FROM submission;");
$num_testsuites=enum_count('testsuite');
$num_testcases =enum_count('testcase');
$schema_version=schema_get_version();

$tbl=array(
	array('we currently serve',''),
	array($num_tr,'results records on'),
	array($num_sub,'submissions for'),
	array($num_prod,'products'),
	array($num_testsuites,'testsuites'),
	array($num_testcases,'testcases'),
	array('Last submission:',$last_sub['submission_date']." ID=".$last_sub['submission_id']),
	array('DB schema version:',$schema_version),
);
print html_table($tbl,array('class'=>'overview','header'=>0,'evenodd'=>false));

print "</center>\n";
?>
</body>
</html>

