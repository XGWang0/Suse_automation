<?php
/* ****************************************************************************
  Copyright (c) 2011 Unpublished Work of SUSE. All Rights Reserved.

  THIS IS AN UNPUBLISHED WORK OF SUSE.  IT CONTAINS SUSE'S
  CONFIDENTIAL, PROPRIETARY, AND TRADE SECRET INFORMATION.  SUSE
  RESTRICTS THIS WORK TO SUSE EMPLOYEES WHO NEED THE WORK TO PERFORM
  THEIR ASSIGNMENTS AND TO THIRD PARTIES AUTHORIZED BY SUSE IN WRITING.
  THIS WORK IS SUBJECT TO U.S. AND INTERNATIONAL COPYRIGHT LAWS AND
  TREATIES. IT MAY NOT BE USED, COPIED, DISTRIBUTED, DISCLOSED, ADAPTED,
  PERFORMED, DISPLAYED, COLLECTED, COMPILED, OR LINKED WITHOUT SUSE'S
  PRIOR WRITTEN CONSENT. USE OR EXPLOITATION OF THIS WORK WITHOUT
  AUTHORIZATION COULD SUBJECT THE PERPETRATOR TO CRIMINAL AND  CIVIL
  LIABILITY.

  SUSE PROVIDES THE WORK 'AS IS,' WITHOUT ANY EXPRESS OR IMPLIED
  WARRANTY, INCLUDING WITHOUT THE IMPLIED WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE, AND NON-INFRINGEMENT. SUSE, THE
  AUTHORS OF THE WORK, AND THE OWNERS OF COPYRIGHT IN THE WORK ARE NOT
  LIABLE FOR ANY CLAIM, DAMAGES, OR OTHER LIABILITY, WHETHER IN AN ACTION
  OF CONTRACT, TORT, OR OTHERWISE, ARISING FROM, OUT OF, OR IN CONNECTION
  WITH THE WORK OR THE USE OR OTHER DEALINGS IN THE WORK.
  ****************************************************************************
 */

  /* This page uses TBLib heavily which is quite unusual to see in
   * Hamsta code. We have decided to use TBLib for this page because
   * of the maintenance relief for the page having the same
   * functionality in Hamsta and QADB.
   *
   * Unfortunatelly this brings also all backsides of the mutual code
   * like model dependency issues, need for more careful edits and
   * many custom changes to the TBLib. If ever moving to more flexible
   * Zend framework and MVC architecture these dependecies should be
   * dropped completely.
   */


/* Name of the page to redirect to. */
$page_base = $dir.'index.php';
$page = "$page_base?go=machine_config";


#print common_header(array('title'=>'QA config','header'=>false,'session'=>false));
$desc=http('desc','');
$body=http('body','');
$wtoken=http('wtoken');
$a_machines=http('a_machines');
$qaconf=http('qaconf');
$group=http('group');

if( token_read($wtoken) )	{
	if( ($submit=='new' && $desc) || $submit=='set' )	{
		transaction();
		if( $submit=='new' )
		update_result( ($id=qaconf_insert_unparsed($desc,$body)), 1 );

		if( $id && $a_machines )	{
			foreach( $a_machines as $machine_id )
				update_result(machine_set_qaconf_id($machine_id,$id));
			}
		if( $id && $group )	{
			update_result(group_set_qaconf_id_by_name($group,$id));
		}
		commit();
	}
	else if( $submit=='update' && $desc )	{
		transaction();
		update_result( qaconf_replace_unparsed($id,$desc,$body) );
		commit();
	}
	else if( $submit=='sync_url' && $id )	{
		if( capable('master_administration') )	{
		transaction();
		update_result(qaconf_set_sync_url($id,http('sync_url')));
		commit();
	}
		else
			print html_error("Insufficent privileges, need to be logged in and be administrator");
	}
	else if( $submit=='delete' && $id )	{
		$usage=qaconf_usage_count($id);
		if( !$usage )
			print html_error("No such configuration: $id");
		else if( $usage['machines'] || $usage['groups'] )
			print html_error("Configuration in use, please detach first");
		else	{
			transaction();
			update_result(qaconf_delete($id));
			commit();
		}
	}
}

$steps=array(
	'l'=>'list',
	'n'=>'new',
);
$steps_alt=array(
	'e'=>'edit',
	'v'=>'view',
	'm'=>'merge',
	'eu'=>'edit URL',
	'd'=>'delete',
);
print steps("$page&step=",$steps,$step,$steps_alt);

if( $step=='e' )	{
	# edit config
	$body=qaconf_get_file($id);
	$desc=qaconf_get_desc($id);
}

$what=array(
	array('go','','machine_config',HIDDEN),
	array('desc','',$desc,TEXT_ROW),
	array('body','',$body,TEXT_AREA),
);

if( $step=='m' )	{
	# config merge
	print "<pre>".qaconf_format_data(qaconf_merge(array(13,14)))."</pre>\n";
}
else if( $step=='e' || $step=='n' )	{
	# new config
	$edit=($step=='e');
	$what[]=array('wtoken','',token_generate(),HIDDEN);
	$what[]=array('submit','',($edit ? 'update':'new'),HIDDEN);
	if( $edit )
		$what[]=array('id','',$id,HIDDEN);
	print "<form method=\"post\" action=\"$page_base\" class=\"input\" id=\"qaconf_edit\">\n";
	print html_search_form('',$what,array('form'=>0,'submit'=>($edit ? 'Update':'Insert')));
	print "</form>\n";
}
else if( $step=='eu' && $id )	{
	$sync_url=qaconf_get_sync_url($id);
	$what=array(
		array('sync_url','',http('sync_url',$sync_url),TEXT_ROW),
		array('id','',$id,HIDDEN),
		array('wtoken','',token_generate(),HIDDEN),
		array('submit','','sync_url',HIDDEN),
		array('go','','machine_config',HIDDEN),
	);
	print html_search_form('',$what,array('submit'=>'Update'));
}
else if( $step=='v' )	{
	# view details
	$data=qaconf_get_rows_translated($id);
	print html_table($data,array('id'=>'qaconf_view','sort'=>'sss','class'=>'list text-main tbl'));
}
else if( $step=='d' && $id )	{
	$desc=qaconf_get_desc($id);
	if( $desc )	{
		print "<h3>Delete configuration $desc ($id) ?</h3>\n";
	$what=array(
		array('id','',$id,HIDDEN),
		array('wtoken','',token_generate(),HIDDEN),
			array('submit','','delete',HIDDEN),
			array('go','','machine_config',HIDDEN),
	);
		print html_search_form('',$what,array('submit'=>'Confirm delete','hr'=>false));
	print html_text_button('Go back',$page);
	}
	else
		html_error("No such configuration: $id");
}
else if( $a_machines )	{
	$m=array();
	$names=array();
	foreach( $a_machines as $machine_id )	{
		if(( $name=machine_get_name($machine_id) ))	{
			$names[]=$name;
			$m[]=$machine_id;
		}
	}
	if( count($m) )	{
		$id=machine_get_qaconf_id($m[0]);
#		print "ID=$id<br/>\n";
		view_delete_create_assign('Config for '.join(',',$names),$id,$m,null);
		foreach(group_machine_list_group($m[0]) as $group_id)	{
			$g=group_get_details($group_id);
			if( $g )
				view_delete_create_assign('Config for group '.$g['group'],$g['qaconf_id'],null,$g['group']);
	}
	print_global_configs();
	}
	else	{
		print html_error("No such machine(s).");
	}
}
else if( $group )	{
	$id=group_get_qaconf_id_by_name($group);
	view_delete_create_assign('Config for '.$group,$id,null,$group);
	print_global_configs();
}
else	{
	# view configuration
	$data=qaconf_list();
	# FIXME: store ID into another field, so that it won't be HTML-formatted
	for( $i=1; $i<count($data); $i++ )	{
		$data[$i]['id']=$data[$i]['qaconf_id'];
	}
	table_translate($data,array(
		'links'=>array('qaconf_id'=>"$page&step=v&id="),
		'ctrls'=>array('edit'=>"$page&step=e&id="),
	));
	for( $i=1; $i<count($data); $i++ )	{
		$row=$data[$i];
		if( !($row['groups'] || $row['machines'] && isset($row[0]) /*FIXME*/ ) )
			$data[$i][0].=' '.html_text_button('delete',"$page&step=d&id=".$row['id']);
	}
	print html_table($data,array('total'=>1,'id'=>'qaconf_list','sort'=>'isss','class'=>'list text-main tbl'));
}

function print_global_configs()	{
	view_delete_create_assign('Master configuration',QACONF_MASTER,0,0);
	view_delete_create_assign('Site configuration',QACONF_SITE,0,0);
	view_delete_create_assign('Country configuration',QACONF_COUNTRY,0,0);
	view_delete_create_assign('Global configuration',QACONF_GLOBAL,0,0);
}

function view_delete_create_assign($title,$id,$machine_id,$group)	{
	global $page;
	print "<h3>$title</h3>\n";
	print "<div class=\"qaconf\">\n";
	if( $id && ($conf=qaconf_get_details($id) ))	{
		$data=qaconf_get_rows_translated($id);
		print html_table($data,array('total'=>0,'id'=>'qaconf_'.$title,'sort'=>'iss','class'=>'list text-main tbl'));
#		print "<pre>"; print_r($conf); print "</pre>\n";
		if( isset($conf['sync_url']) )	{
			print html_text_button('sync',"$page&submit=sync&id=$id")."\n";
			print html_text_button('edit URL',"$page&step=eu&id=$id")."\n";
		}
		else	{
			print html_text_button('edit',"$page&step=e&id=$id")."\n";
#			if( $id>QACONF_MAX_SYS_ID )
#				print html_text_button('delete',"$page&step=d&id=$id")."\n";
		}
	}
	else	{
		$w=array(
			array('wtoken','',token_generate(),HIDDEN),
			array('go','','machine_config',HIDDEN),
		);
		if( $machine_id )
			$w[]=array('a_machines','',$machine_id,HIDDEN);
		if( $group )
			$w[]=array('group','',$group,HIDDEN);
		$what=array_merge($w,array(
			array('desc','',http('desc'),TEXT_ROW),
			array('body','',http('body'),TEXT_AREA),
			array('submit','','new',HIDDEN),
		));
		print html_search_form('',$what,array('submit'=>'Insert','hr'=>false));
		$qaconf=array_merge(array(array('null','')),enum_list_id_val('qaconf'));
		$what=array_merge($w,array(
			array('id',$qaconf,'',SINGLE_SELECT,'another config'),
			array('submit','','set',HIDDEN),
		));
		print html_search_form('',$what,array('submit'=>'Set','hr'=>false));
	}
	print "</div>\n";
}


?>
