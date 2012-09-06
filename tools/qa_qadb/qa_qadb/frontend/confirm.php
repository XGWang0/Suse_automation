<?php

require_once('qadb.php');
common_header(array('title'=>'confirm'));

$confirm=http('confirm');
unset( $_REQUEST['confirm'] );
unset( $_REQUEST['PHPSESSID'] );

$what=array();

$msg='Are you sure ';
if( $confirm=='w' )
	$msg.='to delete waiver with ID='.http('waiver_id').' and all its details';
else if( $confirm=='wd' )
{
	$waiver_testcase_id=http('waiver_testcase_id');
	$waiver_id=waiver_get_master($waiver_testcase_id);
	$_REQUEST['waiver_id']=$waiver_id;
	$msg.="to delete waiver detail with tc_id=$waiver_testcase_id of waiver ID=$waiver_id";
	$what[]=array('waiver_id','',$waiver_id,HIDDEN);
}
else if( $confirm=='s' )
	$msg.='to delete submission_id '.http('submission_id').' and all its results';
else if( $confirm=='sd' )
	$msg.='to delete all results for tcf_id '.http('tcf_id').' from submission '.http('submission_id');
else if( $confirm=='rh' )	{
	$reference = reference_host_search(array('reference_host_id'=>http('reference_host_id')));
	if( $reference )	{
		table_translate($reference,array('enums'=>array('host_id'=>'host','arch_id'=>'arch','product_id'=>'product')));
		$msg.='to remove reference '.$reference[1]['host_id'].' / '.$reference[1]['arch_id'].' / '.$reference[1]['product_id'];
	}
}
$msg.=' ?';

# The script is controlled by the variable 'confirm', which is used as key for following fields.

# For 'Yes', write token (variable 'wtoken') is created

# For 'Yes', the script sets a variable 'submit' with following value :
$submit=array( 'b'=>'delete_board', 'w'=>'delete_waiver', 'wd'=>'delete_detail', 's'=>'delete_submission', 'sd'=>'delete_tcf', 'rh'=>'delete_ref' );

# For 'Yes', all $_REQUEST[] variables are copied
# For 'No', following are copied:
$cancel=array(
	'b'=>array(),
	'w'=>array('view'),
	'wd'=>array('view','waiver_id'),
	's'=>array('submission_id'),
	'sd'=>array('submission_id'),
	'rh'=>array('reference_host_id'),
);

# Page to go back (both 'Yes' and 'No')
$back=array(
	'b'=>'board.php',
	'w'=>'waiver.php',
	'wd'=>'waiver.php',
	's'=>'submission.php',
	'sd'=>'submission.php',
	'rh'=>'reference.php',
);

foreach( array_merge($_GET,$_POST) as $key=>$val )
	$what[]=array($key,'',$val,HIDDEN);
if( $submit[$confirm] )
	$what[]=array('submit','',$submit[$confirm],HIDDEN);
$what[]=array('wtoken','',token_generate(),HIDDEN);
$cancel_what=array();
if( $cancel[$confirm] )
	foreach( $cancel[$confirm] as $id )
		if( isset($_REQUEST[$id]) )
			$cancel_what[]=array($id,'',$_REQUEST[$id],5);

print "<h2>Confirm</h2>\n<div class=\"confirm\"><div class=\"message\">$msg</div>\n";
print html_search_form($back[$confirm],$what,array('submit'=>'Yes','hr'=>false));
print html_search_form($back[$confirm],$cancel_what,array('submit'=>'No','hr'=>false,'search'=>0));
print "</div>\n";
?>
</body>
</html>
