<?php
require_once('userdb.php');


/* Concatenates an array of strings using glue and adds a line
 * break if the number of entries on that line reaches a
 * limit.
 *
 * @param string[] $strings_array Array of strings that will
 * be concatenated.
 *
 * @param string $glue String that is used to connect the
 * entries. Defaults to ', '.
 *
 * @param integer $max_entries_per_line The number of entries
 * per line. If the number of entries is greater, the line
 * break is added when the number of entries reaches this
 * value.
 *
 * @param string $line_break String designating a line break.
 *
 * @return string Concatenated array of strings glued together
 * and with line breaks.
 */
function break_line_by_entries ($strings_array, $glue = ", ", $max_entries_per_line = 5, $line_break = "<br />")
{
	$glued_entries = "";
	if (count ($strings_array) > $max_entries_per_line)
	  {
		for ($i = 0; $i < count ($strings_array); $i += $max_entries_per_line)
		  {
			$glued_entries .= implode ($glue, array_slice ($strings_array, $i, $max_entries_per_line)) . $line_break;
		  }
	  }
	else
	  {
		$glued_entries = implode ($glue, $strings_array) . $line_break;
	  }

	return $glued_entries;
}

if (! isset ($page))
{
	$page=basename($_SERVER['PHP_SELF']);
}

/* Name of the page to redirect to. */
$page_name = isset ($page_name) ? $page_name : '';

/* Add an extension to URL for all links on the page. Starts with a
 * '?' character. */
$page = isset ($page_url_extension) ? $page . $page_url_extension : '?';

/* Do not print out primary keys in tables. */
$no_table_id = isset ($no_table_id) ? $no_table_id : false;

print common_header($header_args);

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
		$descr=http('descr');
		transaction();
		update_result( privilege_update($priv_got,$descr) );
		commit();
		$step='p';
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
	'v'=>'Users overview',
	'p'=>'Privileges',
);
$steps_alt=array(
	'ue'=>'Edit User',
	'un'=>'New User',
	'ur'=>'User Roles',
	're'=>'Edit Role',
	'rn'=>'New Role',
	'rp'=>'Edit Privileges' . ( isset ($role) ? ' for ' . $role[1]['role'] : ''),
	'pe'=>'Edit Privilege' . ( isset ($priv) ? ' ' . $priv[1]['privilege'] : ''),
	'pn'=>'New Privilege',
);

print steps("$page&amp;step=",$steps,$step,$steps_alt);

if( $confirm=='userdel' && $user )	{
	# confirm user delete
	$fields=array(
		'submit'=>$confirm,
		'user_id'=>$user_got,
		'go' => $page_name
	);
	print html_confirm('Are you sure to delete user '.$user[1]['name'].' ?',$fields,$page);
}
else if( $confirm=='role_del' && $role )	{
	# confirm role delete
	$fields=array(
		'submit'=>$confirm,
		'role_id'=>$role_got,
		'go' => $page_name
	);
	print html_confirm('Are you sure to delete role '.$role[1]['role'].' ?',$fields,$page);
}
else if( $step=='ur' )	{
	# user roles
	print html_table($user, array ('class'=>'list text-main tbl'));
	print "<hr/>";
	$roles=user_role_list($user_got);
	table_add_checkboxes($roles,'checked[]','role_id',1,'role_form','checked');
	if(count($roles)>1)
		print '<form action="'.$page.'" method="post" name="role_form">'."\n";
	unset($roles[0]['checked']);
	print html_table($roles, array ('class'=>'list text-main tbl'));
	$what=array(
		array('user_id','',$user_got,HIDDEN),
		array('submit','','roles',HIDDEN),
		array('wtoken','',token_generate(),HIDDEN),
		(isset ($page_name) ? array('go', '', $page_name, HIDDEN): null)
	);
	print html_search_form($page,$what,array('form'=>false,'submit'=>'Update'));
	print "</form>\n";
}
else if( $step=='ue' && $user )	{
	# edit user
	$what=array(
		array('login','',$user[1]['login'],TEXT_ROW, 'Login'),
		array('name','',$user[1]['name'],TEXT_ROW, 'Name'),
		array('email','',$user[1]['email'],TEXT_ROW, 'E-mail'),
		array('extern_id','',$user[1]['extern_id'],TEXT_AREA, 'External identifier'),
		array('user_id','',$user_got,HIDDEN),
		array('submit','','usermod',HIDDEN),
		array('wtoken','',token_generate(),HIDDEN),
		(isset ($page_name) ? array('go', '', $page_name, HIDDEN): null)
	);
	print html_search_form($page,$what);
}
else if( $step=='un' )	{
	# new user
	$what=array(
		array('login','','',TEXT_ROW, 'Login'),
		array('name','','',TEXT_ROW, 'Name'),
		array('email','','',TEXT_ROW, 'E-mail'),
		array('extern_id','','',TEXT_AREA, 'External identifier'),
		array('submit','','useradd',HIDDEN),
		array('wtoken','',token_generate(),HIDDEN),
		(isset ($page_name) ? array('go', '', $page_name, HIDDEN): null)
	);
	print html_search_form($page,$what);
}
else if( $step=='up' && $user )	{
	# user password
	print '<h3>Changing password for '.$user[1]['name']."</h3>\n";
	$what=array(
		array('pwd1','','',PASSWORD,'New password'),
		array('pwd2','','',PASSWORD,'Confirm new password'),
		array('user_id','',$user[1]['user_id'],HIDDEN),
		array('submit','','passwd',HIDDEN),
		array('wtoken','',token_generate(),HIDDEN),
		(isset ($page_name) ? array('go', '', $page_name, HIDDEN): null)
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
		(isset ($page_name) ? array('go', '', $page_name, HIDDEN): null)
	);
	print html_search_form($page,$what);
}
else if( $step=='rn' )	{
	# new role
	$what=array(
		array('role','','',TEXT_ROW, 'Role name'),
		array('descr','','',TEXT_AREA,'Description'),
		array('submit','','role_insert',HIDDEN),
		array('wtoken','',token_generate(),HIDDEN),
		(isset ($page_name) ? array('go', '', $page_name, HIDDEN): null)
	);
	print html_search_form($page,$what);
}
else if( $step=='rp' && $role_got )	{
	# role privileges
	$data=role_privilege_list($role_got);
	$data[0]['privilege'] = 'Privilege name';
	$data[0]['descr'] = 'Description';
	$data[0]['valid_until'] = 'Valid until';

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
		(isset ($page_name) ? array('go', '', $page_name, HIDDEN): null)
	);
	print html_table($data, array ('class' => 'list text-main tbl'));
	print html_search_form($page,$what,array('form'=>false,'submit'=>'Update'));
	print "</form>\n";
}
else if( $step=='pe' )	{
	# edit privilege
	if( isset ($priv) )	{
		$what=array(
			array('descr','',$priv[1]['descr'],TEXT_AREA,'Description'),
			array('priv_id','',$priv[1]['privilege_id'],HIDDEN),
			array('submit','','priv',HIDDEN),
			array('wtoken','',token_generate(),HIDDEN),
			(isset ($page_name) ? array('go', '', $page_name, HIDDEN): null)
		);
		print html_search_form($page,$what);
	}
	else
		print html_error("No such privilege");
}
else if( $step=='p' )	{
	# list privileges
	print "<h3>Privileges</h3>\n";
	$data=privilege_list();
	$data[0]['privilege'] = 'Privilege name';
	$data[0]['descr'] = 'Description';
	$data[0]['roles'] = 'Roles having this privilege';

	table_translate($data,array(
		'links'=>($no_table_id
			  ? null
			  : array("$page&step=pe&priv_id=")),
		'ctrls'=>array(
			'Edit'=>"$page&step=pe&priv_id="
		),
	));

	if ($no_table_id)
	{
		unset ($data[0]['privilege_id']);
	}

	print html_table($data,array(
		'total'=>0,
		'id'=>'priv',
		'class'=>'list text-main tbl',
		'sort'=>($no_table_id ? 'sss' : 'isss')
	));
}
else	{
	# view users + roles
	print "<h3>Users</h3>\n";
	$data=user_list();
	$data[0]['login'] = 'Login';
	$data[0]['name'] = 'Name';
	$data[0]['email'] = 'E-mail';
	$data[0]['roles'] = 'Roles';
	$data[0]['pwd'] = 'Password set';
	$data[0]['extern_id'] = 'External identifier';

	table_translate($data,array(
		'links'=> ($no_table_id
			   ? null
			   : array('user_id'=>"$page&step=ue&user_id=")),
		'ctrls'=>array(
			'Roles'=>"$page&step=ur&user_id=",
			'Edit'=>"$page&step=ue&user_id=",
			'Delete'=>"$page&confirm=userdel&user_id=",
			'Change password'=>"$page&step=up&user_id=",
		),
	));

	if ($no_table_id)
	{
		unset ($data[0]['user_id']);
	}

	print html_table($data,array(
		'total'=>0,
		'id'=>'users',
		'class'=>'list text-main tbl',
		'sort'=>($no_table_id ? 'ssssss' : 'issssss')
	));
	print html_text_button('New User',"$page&step=un");

	print "<h3>Roles</h3>\n";
	$data=role_list();
	$data[0]['role'] = 'Role name';
	$data[0]['descr'] = 'Role description';
	$data[0]['users'] = 'Users in role';

	/* The users in the role can be many. So we need to print them
	 * on multiple lines. */
	for ($i = 1; $i < count ($data); $i++)
	  {
	    $users = '';
	    if (isset ($data[$i]['users']))
	      {
		$users_array = explode (',', $data[$i]['users']);

		$data[$i]['users'] = break_line_by_entries ($users_array, ", ", 10);
	      }
	  }

	table_translate($data,array(
		'links'=>($no_table_id
			  ? null
			  : array('role_id'=>"$page&step=re&role_id=")),
		'ctrls'=>array(
			'Privileges'=>"$page&step=rp&role_id=",
			'Edit'=>"$page&step=re&role_id=",
			'Delete'=>"$page&confirm=role_del&role_id=",
		),
	));

	if ($no_table_id)
	{
		unset ($data[0]['role_id']);
	}

	print html_table($data,array(
		'total'=>0,
		'id'=>'roles',
		'class'=>'list text-main tbl',
		'sort'=>($no_table_id ? 'sss' : 'isss')
	));
	print html_text_button('New Role',"$page&step=rn");
}

print '</div>';

if (isset ($print_footer) && ! empty ($print_footer))
  print html_footer();

?>
