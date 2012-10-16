<?php


/** library functions - common DB and HTML functions */
require_once($_SERVER['DOCUMENT_ROOT'].'/tblib/tblib.php');

if( !isset($enums) )
	$enums=array();

$enums = array_merge( $enums, array(
	'user'	=> array('user_id','user_login'),
	'user_role'	=> array('role_id','role'),
	'privilege'	=> array('privilege_id','privilege'),
));

/** logs into DB, checks user, prints header, prints navigation bar */
function common_header($args=null)
{
	global $conn_id,$glob_dest;
#	$is_production_server = ( $_SERVER['SERVER_ADDR'] == '10.10.3.155' );
	$defaults=array(
		'session'=>true,
		'connect'=>true,
		'icon'=>'icons/qadb_ico.png'
	);
	$args=args_defaults($args,$defaults);
	if( $args['session'] )
		session_start();
	if( $args['connect'] )
		$conn_id=connect_to_mydb();

	if (isset ($print_header) && ! empty ($print_header))
	  print html_header($args);
}

function user_list($user_id=null)	{
	$sql="SELECT user_id,login,name,email,GROUP_CONCAT(role) AS roles,IF(LENGTH(`password`)>0,'*','') AS pwd,extern_id FROM `user` LEFT JOIN user_in_role USING(user_id) LEFT JOIN user_role USING(role_id)";
	$group='GROUP BY user_id';
	if( $user_id )
		return mhash_query(1,null,"$sql WHERE user_id=? $group",'i',$user_id);
	else
		return mhash_query(1,null,"$sql $group");
}

function user_update($user_id,$login,$name,$email,$extern_id)	{
	return update_query('UPDATE `user` SET login=?,name=?,email=?,extern_id=? WHERE user_id=?','ssssi',$login,$name,$email,$extern_id,$user_id);
}

function user_insert($login,$name,$email,$extern_id)	{
	return insert_query('INSERT INTO `user`(login,name,email,extern_id) VALUES(?,?,?,?)','ssss',$login,$name,$email,$extern_id);
}

function user_delete($user_id)	{
	return update_query('DELETE FROM `user` WHERE user_id=?','i',$user_id);
}

function user_set_password($user_id,$pwd)	{
	return update_query('UPDATE `user` SET `password`=SHA1(?) WHERE user_id=?','si',($pwd ? $pwd:null),$user_id);
}

function user_role_list($user_id)	{
	return mhash_query(1,null,'SELECT user_role.*,EXISTS(SELECT * FROM user_in_role WHERE user_in_role.role_id=user_role.role_id AND user_id=?) AS checked FROM user_role','i',$user_id);
}

function user_in_role_delete_user($user_id)	{
	return update_query('DELETE FROM user_in_role WHERE user_id=?','i',$user_id);
}

function user_in_role_delete_role($role_id)	{
	return update_query('DELETE FROM user_in_role WHERE role_id=?','i',$role_id);
}

function user_in_role_insert_all($user_id,$roles)	{
	if( !count($roles) )
		return 0;
	$vals=array();
	$args=array();
	foreach($roles as $r)	{
		$vals[] = "(?,?)";
		$args[] = $user_id;
		$args[] = $r;
	}
	$a=array_merge(array('INSERT INTO user_in_role(user_id,role_id) VALUES '.join(',',$vals),str_repeat('ii',count($vals))),$args);
	return call_user_func_array('update_query',$a);
}

function role_list($role_id=null)	{
	$sql='SELECT role_id,role,descr,GROUP_CONCAT(login) AS users FROM user_role LEFT JOIN user_in_role USING(role_id) LEFT JOIN `user` USING(user_id)';
	$group='GROUP BY role_id';
	if( $role_id )
		return mhash_query(1,null,"$sql WHERE role_id=? $group",'i',$role_id);
	else
		return mhash_query(1,null,"$sql $group");
}

function role_update($role_id,$role,$descr)	{
	return update_query('UPDATE user_role SET `role`=?,descr=? WHERE role_id=?','ssi',$role,$descr,$role_id);
}

function role_insert($role,$descr)	{
	return insert_query('INSERT INTO user_role(`role`,descr) VALUES(?,?)','ss',$role,$descr);
}

function role_delete($role_id)	{
	return update_query('DELETE FROM user_role WHERE role_id=?','i',$role_id);
}

function role_privilege_list($role_id)	{
	return mhash_query(1,null,'SELECT p.privilege_id,p.privilege,p.descr,rp.valid_until,IF(rp.privilege_id,1,0) AS checked FROM privilege p LEFT JOIN (SELECT * FROM role_privilege WHERE role_id=?) rp USING(privilege_id) WHERE rp.role_id IS NULL OR rp.role_id=? ORDER BY privilege','ii',$role_id,$role_id);
}

function role_privilege_delete_role($role_id)	{
	return update_query('DELETE FROM role_privilege WHERE role_id=?','i',$role_id);
}

function role_privilege_delete_privilege($priv_id)	{
	return update_query('DELETE FROM role_privilege WHERE privilege_id=?','i',$priv_id);
}

function role_privilege_insert_all($role_id,$valid_until)	{
	if( !count($valid_until) )
		return 0;
	$vals=array();
	$args=array();
	foreach($valid_until as $k=>$v)	{
		$vals[]='(?,?,NOW(),?)';
		$args[]=$role_id;
		$args[]=$k;
		$args[]=($v ? $v:null);
	}
	$a=array_merge(array('INSERT INTO role_privilege(role_id,privilege_id,valid_since,valid_until) VALUES '.join(',',$vals),str_repeat('iid',count($vals))),$args);
	return call_user_func_array('update_query',$a);
}

function privilege_list()	{
	return mhash_query(1,null,'SELECT privilege.*,(SELECT GROUP_CONCAT(role) FROM role_privilege JOIN user_role USING(role_id) WHERE role_privilege.privilege_id=privilege.privilege_id) AS roles FROM privilege');
}

function privilege_read($privilege_id)	{
	return mhash_query(1,null,'SELECT * FROM privilege WHERE privilege_id=?','i',$privilege_id);
}

function privilege_update($privilege_id,$descr)	{
	return update_query('UPDATE privilege SET descr=? WHERE privilege_id=?','ssi',$descr,$privilege_id);
}

function privilege_insert($privilege,$descr)	{
	return insert_query('INSERT INTO privilege(privilege,descr) VALUES(?,?)','ss',$privilege,$descr);
}

function privilege_delete($privilege_id)	{
	return update_query('DELETE FROM privilege WHERE privilege_id=?','i',$privilege_id);
}


?>
