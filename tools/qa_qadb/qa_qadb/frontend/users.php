<?php
require_once('qadb.php');

$action=http('action');
$tester_id=http('tester_id');
$wtoken=http('wtoken');

common_header(array('title'=>'Edit user roles'));

if( $tester_id && token_read($wtoken) )	{
	if( !is_admin() )	{
		print html_error("Only admin may do this");
	}
	else	{
		transaction();
		if( $action=='confirm' )
			update_result(tester_set_confirmed($tester_id,1), false, "User confirmed.");
		else if( $action=='unconfirm' )
			update_result(tester_set_confirmed($tester_id,0), false, "User unconfirmed.");
		else if( $action=='admin' )
			update_result(tester_set_admin($tester_id,1), false, "Set to admin.");
		else if( $action=='user' )
			update_result(tester_set_admin($tester_id,0), false, "Set to regular user.");
#		else if( $action=='delete' )
#			update_result(tester_delete($tester_id), false, "User deleted.");
#		TODO: for deleting, need to solve foreign key constraints
		commit();
	}
}

$tester_got=http('tester');
$name_got=http('name');
$email_got=http('email');
$ext_ident_got=http('ext_ident');
$is_confirmed_got=http('is_confirmed','');
$is_admin_got=http('is_admin','');

$threestate=array(
	array("",""),
	array("1","yes"),
	array("0","no"),
);

$what=array(
	array('tester','',$tester_got,TEXT_ROW,'tester [%]'),
	array('name','',$name_got,TEXT_ROW,'name [%]'),
	array('email','',$email_got,TEXT_ROW,'email [%]'),
	array('ext_ident','',$ext_ident_got,TEXT_ROW,'identity [%]'),
	array('is_confirmed',$threestate,$is_confirmed_got,SINGLE_SELECT,'confirmed'),
	array('is_admin',$threestate,$is_admin_got,SINGLE_SELECT,'admin'),
);
print html_search_form('users.php',$what);
$attrs=array(
	'tester'	=>$tester_got,
	'name'		=>$name_got,
	'email'		=>$email_got,
	'ext_ident'	=>$ext_ident_got,
	'is_admin'	=>$is_admin_got,
	'is_confirmed'	=>$is_confirmed_got,
);
$data = tester_search($attrs);
$wtoken = token_generate();
for($i=1; $i<count($data); $i++)	{
	$tester_id=$data[$i]['tester_id'];
#	$ctrls=array('delete');
	$ctrls=array();
	if( $data[$i]['is_confirmed'] )
		$ctrls[]='unconfirm';
	else
		$ctrls[]='confirm';
	if( $data[$i]['is_admin'] )
		$ctrls[]='user';
	else
		$ctrls[]='admin';
	$c='';
	foreach($ctrls as $ctrl)
		$c.=html_admin_button($ctrl,'users.php?tester_id='.$data[$i]['tester_id']."&wtoken=$wtoken&action=$ctrl").' ';
	$data[$i]['ctrl']=$c;
}
$data[0]['ctrl']='controls';
print html_table($data,array('id'=>'users','sort'=>'issssii'));
print html_footer();
?>
