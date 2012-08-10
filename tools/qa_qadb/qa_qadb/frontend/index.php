<?php
require_once('qadb.php');
common_header(array('title'=>'Welcome to the QA database'));
print "<center><h2>Welcome to the QA database</h2>\n";

if ( !isset($_SESSION['user'] ) )
	printf("you are currently not loged in<br><br>");
else
	printf("you are currently loged in as <i><b>%s</b></i><br/><br/>", $_SESSION['user'] == "qadb_user" ? $_SESSION['OPENID_AUTH'] : $_SESSION['user']);
$last_sub=row_query(array(1), "SELECT submission_id, submission_date FROM submission ORDER BY submission_date DESC");
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
	array('Last submission:',$last_sub[1]." ID=".$last_sub[0]),
	array('DB schema version:',$schema_version),
);
print html_table($tbl,array('class'=>'overview','header'=>0,'evenodd'=>false));

print "</center>\n";
?>
</body>
</html>

