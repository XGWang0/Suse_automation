<?php
require_once('userdb.php');

$page=basename($_SERVER['PHP_SELF']);

if (! isset ($page_url_extension))
  {
    $page_url_extension = '';
  }

print common_header(array('title'=>'user administration'));

$step=http('step','v');
$submit=http('submit');
$wtoken=http('wtoken');
$user_got=http('user_id');
$role_got=http('role_id');
$priv_got=http('priv_id');
$confirm=http('confirm');

if( $user_got )
	$user=user_list($user_got);
if( $role_got )
	$role=role_list($role_got);
if( $priv_got )
	$priv=privilege_read($priv_got);

if( token_read($wtoken) )	{
	if( $submit=='priv' && $priv_got )	{
		$privilege=http('privilege');
		$descr=http('descr');
		transaction();
		update_result( privilege_update($priv_got,$privilege,$descr) );
		commit();
		$step='p';
	}
	else if( $submit=='priv_new')	{
		$privilege=http('privilege');
		$descr=http('descr');
		transaction();
		update_result( privilege_insert($privilege,$descr), 1 );
		commit();
		$step='p';
	}
	else if( $submit=='priv_del' && $priv_got)	{
		transaction();
		update_result( role_privilege_delete_privilege($priv_got) );
		update_result( privilege_delete($priv_got) );
		commit();
	}
	else if( $submit=='roles' )	{
		$checked=http('checked');
		transaction();
		update_result( user_in_role_delete_user($user_got) );
		update_result( user_in_role_insert_all($user_got,$checked) );
		commit();
	}
	else if( $submit=='usermod' && $user )	{
		$login=http('login');
		$name=http('name');
		$email=http('email');
		$extern_id=http('extern_id');
		transaction();
		update_result( user_update($user_got,$login,$name,$email,$extern_id) );
		commit();
	}
	else if( $submit=='useradd' )	{
		$login=http('login');
		$name=http('name');
		$email=http('email');
		$extern_id=http('extern_id');
		transaction();
		update_result( user_insert($login,$name,$email,$extern_id), 1 );
		commit();
	}
	else if( $submit=='userdel' && $user )	{
		transaction();
		update_result( user_in_role_delete_user($user_got) );
		update_result( user_delete($user_got) );
		commit();
	}
	else if( $submit=='passwd' && $user )	{
		$pwd1=http('pwd1');
		$pwd2=http('pwd2');
		if( strcmp($pwd1,$pwd2)	)	{
			print html_error('Passwords do not match');
			$step='up';
		}
		else	{
			transaction();
			update_result( user_set_password($user_got,$pwd1) );
			commit();
		}
	}
	else if( $submit=='role_priv' && $role )	{
		$checked=http('checked');
		$valid_until=array();
		if( $checked )	{
			foreach( $checked as $c )	{
				$valid_until[$c]=http('date_'.$c);
			}
		}
		transaction();
		update_result( role_privilege_delete_role($role_got) );
		update_result( role_privilege_insert_all($role_got,$valid_until) );
		commit();
	}
	else if( $submit=='role_update' && $role )	{
		$role_name=http('role');
		$descr=http('descr');
		transaction();
		update_result( role_update($role_got,$role_name,$descr) );
		commit();
	}
	else if( $submit=='role_insert' )	{
		$role_name=http('role');
		$descr=http('descr');
		transaction();
		update_result( role_insert($role_name,$descr), 1 );
		commit();
	}
	else if( $submit=='role_del' && $role )	{
		transaction();
		update_result( user_in_role_delete_role($role_got) );
		update_result( role_privilege_delete_role($role_got) );
		update_result( role_delete($role_got) );
		commit();
	}

}


$steps=array(
	'v'=>'overview',
	'p'=>'privileges',
);
$steps_alt=array(
	'ue'=>'edit user',
	'un'=>'new user',
	'ur'=>'user roles',
	're'=>'edit role',
	'rn'=>'new role',
	'rp'=>'role privileges',
	'pe'=>'edit privilege',
	'pn'=>'new privilege',
);

print steps("$page?$page_url_extension&step=",$steps,$step,$steps_alt);

if( $confirm=='priv_del' && $priv )	{
	# confirm privilege delete
	$fields=array(
		'submit'=>$confirm,
		'priv_id'=>$priv_got,
		'step'=>'p',
	);
	print html_confirm('Are you sure to delete privilege '.$priv[1]['privilege'].' ?',$fields,$page);
}
else if( $confirm=='userdel' && $user )	{
	# confirm user delete
	$fields=array(
		'submit'=>$confirm,
		'user_id'=>$user_got,
	);
	print html_confirm('Are you sure to delete user '.$user[1]['name'].' ?',$fields,$page);
}
else if( $confirm=='role_del' && $role )	{
	# confirm role delete
	$fields=array(
		'submit'=>$confirm,
		'role_id'=>$role_got,
	);
	print html_confirm('Are you sure to delete role '.$role[1]['role'].' ?',$fields,$page);
}
else if( $step=='ur' )	{
	# user roles
	print html_table($user);
	print "<hr/>";
	$roles=user_role_list($user_got);
	table_add_checkboxes($roles,'checked[]','role_id',1,'role_form','checked');
	if(count($roles)>1)
		print '<form action="'.$page.'" method="post" name="role_form">'."\n";
	unset($roles[0]['checked']);
	print html_table($roles);
	$what=array(
		array('user_id','',$user_got,HIDDEN),
		array('submit','','roles',HIDDEN),
		array('wtoken','',token_generate(),HIDDEN),
	);
	print html_search_form($page,$what,array('form'=>false,'submit'=>'update'));
	print "</form>\n";
}
else if( $step=='ue' && $user )	{
	# edit user
	$what=array(
		array('login','',$user[1]['login'],TEXT_ROW),
		array('name','',$user[1]['name'],TEXT_ROW),
		array('email','',$user[1]['email'],TEXT_ROW),
		array('extern_id','',$user[1]['extern_id'],TEXT_AREA),
		array('user_id','',$user_got,HIDDEN),
		array('submit','','usermod',HIDDEN),
		array('wtoken','',token_generate(),HIDDEN),
	);
	print html_search_form($page,$what);
}
else if( $step=='un' )	{
	# new user
	$what=array(
		array('login','','',TEXT_ROW),
		array('name','','',TEXT_ROW),
		array('email','','',TEXT_ROW),
		array('extern_id','','',TEXT_AREA),
		array('submit','','useradd',HIDDEN),
		array('wtoken','',token_generate(),HIDDEN),
	);
	print html_search_form($page,$what);
}
else if( $step=='up' && $user )	{
	# user password
	print '<h3>Changing password for '.$user[1]['name']."</h3>\n";
	print html_table($user);
	$what=array(
		array('pwd1','','',PASSWORD,'New password'),
		array('pwd2','','',PASSWORD,'Confirm new password'),
		array('user_id','',$user[1]['user_id'],HIDDEN),
		array('submit','','passwd',HIDDEN),
		array('wtoken','',token_generate(),HIDDEN),
	);
	print html_search_form($page,$what);
}
else if( $step=='re' && $role )	{
	# edit role
	$what=array(
		array('role','',$role[1]['role'],TEXT_ROW),
		array('descr','',$role[1]['descr'],TEXT_AREA,'Description'),
		array('role_id','',$role_got,HIDDEN),
		array('submit','','role_update',HIDDEN),
		array('wtoken','',token_generate(),HIDDEN),
	);
	print html_search_form($page,$what);
}
else if( $step=='rn' )	{
	# new role
	$what=array(
		array('role','','',TEXT_ROW),
		array('descr','','',TEXT_AREA,'Description'),
		array('submit','','role_insert',HIDDEN),
		array('wtoken','',token_generate(),HIDDEN),
	);
	print html_search_form($page,$what);
}
else if( $step=='rp' && $role_got )	{
	# role privileges
	$data=role_privilege_list($role_got);
	table_add_checkboxes($data,'checked[]','privilege_id',1,'priv_form','checked');
	foreach(array_keys($data) as $i)	{
		$id=$data[$i]['privilege_id'];
		unset($data[$i]['privilege_id']);
		unset($data[$i]['checked']);
		if( $i==0 )
			continue;
		$data[$i]['valid_until']='<input type="text" value="'.$data[$i]['valid_until'];
		$data[$i]['valid_until'].='" name="date_'.$id.'"/>';
	}
	print '<form action="'.$page.'" method="post" name="priv_form">'."\n";
	$what=array(
		array('role_id','',$role_got,HIDDEN),
		array('submit','','role_priv',HIDDEN),
		array('wtoken','',token_generate(),HIDDEN),
	);
	print html_table($data);
	print html_search_form($page,$what,array('form'=>false,'submit'=>'update'));
	print "</form>\n";
}
else if( $step=='pe' )	{
	# edit privilege
	if( $priv )	{
		$what=array(
			array('privilege','',$priv[1]['privilege'],TEXT_ROW),
			array('descr','',$priv[1]['descr'],TEXT_AREA,'Description'),
			array('priv_id','',$priv[1]['privilege_id'],HIDDEN),
			array('submit','','priv',HIDDEN),
			array('wtoken','',token_generate(),HIDDEN),
		);
		print html_search_form($page,$what);
	}
	else
		print html_error("No such privilege");
}
else if( $step=='pn' )	{
	# new privilege
	$what=array(
		array('privilege','','',TEXT_ROW),
		array('descr','','',TEXT_AREA,'Description'),
		array('submit','','priv_new',HIDDEN),
		array('wtoken','',token_generate(),HIDDEN),
	);
	print html_search_form($page,$what);
}
else if( $step=='p' )	{
	# list privileges
	print "<h3>Privileges</h3>\n";
	$data=privilege_list();
	table_translate($data,array(
		'links'=>array(
			"$page?$page_url_extension&step=pe&priv_id=",
		),
		'ctrls'=>array(
			'edit'=>"$page?$page_url_extension&step=pe&priv_id=",
			'delete'=>"$page?$page_url_extension&confirm=priv_del&priv_id=",
		),
	));
	print html_table($data,array(
		'total'=>1,
		'id'=>'priv',
		'sort'=>'isss'
	));
	print html_text_button('new priv',"$page?$page_url_extension&step=pn");
}
else	{
	# view users + roles
	print "<h3>Users</h3>\n";
	$data=user_list();
	table_translate($data,array(
		'links'=>array(
			'user_id'=>"$page?$page_url_extension&step=ue&user_id=",
		),
		'ctrls'=>array(
			'roles'=>"$page?$page_url_extension&step=ur&user_id=",
			'edit'=>"$page?$page_url_extension&step=ue&user_id=",
			'delete'=>"$page?$page_url_extension&confirm=userdel&user_id=",
			'passwd'=>"$page?$page_url_extension&step=up&user_id=",
		),
	));
	print html_table($data,array(
		'total'=>1,
		'id'=>'users',
		'sort'=>'issssss',
	));
	print html_text_button('new user',"$page?$page_url_extension&step=un");


	print "<h3>Roles</h3>\n";
	$data=role_list();
	table_translate($data,array(
		'links'=>array(
			'role_id'=>"$page?$page_url_extension&step=re&role_id=",
		),
		'ctrls'=>array(
			'privileges'=>"$page?$page_url_extension&step=rp&role_id=",
			'edit'=>"$page?$page_url_extension&step=re&role_id=",
			'delete'=>"$page?$page_url_extension&confirm=role_del&role_id=",
		),
	));
	print html_table($data,array(
		'total'=>1,
		'id'=>'roles',
		'sort'=>'isss',
	));
	print html_text_button('new role',"$page?$page_url_extension&step=rn");
}

print html_footer();

?>
