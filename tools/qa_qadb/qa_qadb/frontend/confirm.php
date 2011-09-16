<?php

require_once('qadb.php');
common_header(array('title'=>'confirm'));

$confirm=http('confirm');
unset( $_REQUEST['confirm'] );
unset( $_REQUEST['PHPSESSID'] );

$what=array();

$msg='Are you sure ';
if( $confirm=='w' )
	$msg.='to delete waiver with ID='.http('waiverID').' and all its details';
else if( $confirm=='wd' )
{
	$waiver_tcID=http('waiver_tcID');
	$waiverID=waiver_get_master($waiver_tcID);
	$_REQUEST['waiverID']=$waiverID;
	$msg.="to delete waiver detail with tcID=$waiver_tcID of waiver ID=$waiverID";
	$what[]=array('waiverID','',$waiverID,HIDDEN);
}
else if( $confirm=='s' )
	$msg.='to delete submissionID '.http('submissionID').' and all its results';
else if( $confirm=='sd' )
	$msg.='to delete all results for tcfID '.http('tcfID').' from submission '.http('submissionID');
$msg.=' ?';

# The script is controlled by the variable 'confirm', which is used as key for following fields.

# For 'Yes', write token (variable 'wtoken') is created

# For 'Yes', the script sets a variable 'submit' with following value :
$submit=array( 'b'=>'delete_board', 'w'=>'delete_waiver', 'wd'=>'delete_detail', 's'=>'delete_submission', 'sd'=>'delete_tcf' );

# For 'Yes', all $_REQUEST[] variables are copied
# For 'No', following are copied:
$cancel=array(
	'b'=>array(),
	'w'=>array('view'),
	'wd'=>array('view','waiverID'),
	's'=>array('submissionID'),
	'sd'=>array('submissionID')
);

# Page to go back (both 'Yes' and 'No')
$back=array(
	'b'=>'board.php',
	'w'=>'waiver.php',
	'wd'=>'waiver.php',
	's'=>'submission.php',
	'sd'=>'submission.php',
);

foreach( $_REQUEST as $key=>$val )
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
?>
</body>
</html>
