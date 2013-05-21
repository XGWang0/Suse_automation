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
   * When implementing something better, following dependencies may be dropped:
   * - tblib_db: could be replaced by Zend DB
   * - tblib_html: feasible replacement so far unknown
   *
   * It is also possible to better keep the MVC model and move the
   * update code from top of this file to the ../inc/ directory.
   * This was not done yet, as there was no need to redirecting after updates.
   * If doing that, replace TBlib's result reporting by Hamsta's native.
   */


/* Name of the page to redirect to. */
$page_base = 'index.php';
$page = "$page_base?go=machine_config";


$desc=http('desc','');
$body=http('body','');
$wtoken=http('wtoken');
$group=http('group');
$id_defined=array_key_exists('id',$_REQUEST);

if( token_read($wtoken) )	{
	if( ($submit=='new' && $desc) || $submit=='set' )	{
		check_perm_redirect();
		transaction();
		if( $submit=='new' )	{
			update_result( ($id=qaconf_insert_unparsed($desc,$body)), 1 );
			$id_defined=$id;
		}

		if( $id_defined && $a_machines )	{
			foreach( $a_machines as $machine_id )
				update_result(machine_set_qaconf_id($machine_id,$id));
			}
		if( $id_defined && $group )	{
			update_result(group_set_qaconf_id_by_name($group,$id));
		}
		commit();
	}
	else if( $submit=='update' && $desc )	{
		check_perm_redirect($id);
		transaction();
		update_result( qaconf_replace_unparsed($id,$desc,$body) );
		commit();
	}
	else if( $submit=='sync_url' && $id )	{
		check_perm_redirect(0);
		transaction();
		update_result(qaconf_set_sync_url($id,http('sync_url')));
		commit();
	}
	else if( $submit=='detach' && $id )	{
		check_perm_redirect($id);
		$usage=qaconf_usage_count($id);
		transaction();
		if( $usage['machines'] )
			update_result(qaconf_detach_machine($id));
		if( $usage['groups'] )
			update_result(qaconf_detach_group($id));
		commit();
	}
	else if( $submit=='delete' && $id )	{
		check_perm_redirect($id);
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
	$step='l';
}

$steps=array(
	'l'=>'list all',
	'n'=>'new config',
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
	print "<pre>".qaconf_format_data(qaconf_merge(array(5,6)))."</pre>\n";
}
else if( $step=='e' || $step=='n' )	{
	# new config
	$edit=($step=='e');
	$what[]=array('wtoken','',token_generate(),HIDDEN);
	$what[]=array('submit','',($edit ? 'update':'new'),HIDDEN);
	if( $edit )
		$what[]=array('id','',$id,HIDDEN);
	if( $group )	{
		$what[]=array('group','',$group,HIDDEN);
		print html_div('list group',"group: $group");
	}
	if( $a_machines )	{
		$what[]=array('a_machines','',$a_machines,HIDDEN);
		print html_div('list machines',"machines: ".join(' ',array_map('machine_get_name',$a_machines)));
	}
	print "<form method=\"post\" action=\"$page_base\" class=\"input\" id=\"qaconf_edit\">\n";
	print html_search_form('',$what,array('form'=>0,'submit'=>($edit ? 'Update':'Insert')));
	print "</form>\n";
}
else if( $step=='eu' && $id )	{
	# edit URL
	print html_table(qaconf_list(array($id)),array('class'=>'list text-main tbl'));
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
else if( ($step=='d'||$step=='t') && $id )	{
	# confirm delete
	$desc=qaconf_get_desc($id);
	if( $desc )	{
		print '<h3>'.($step=='d' ? 'Delete':'Detach')." configuration $desc ($id) ?</h3>\n";
	$what=array(
		array('id','',$id,HIDDEN),
		array('wtoken','',token_generate(),HIDDEN),
		array('submit','',($step=='d' ? 'delete':'detach'),HIDDEN),
		array('go','','machine_config',HIDDEN),
	);
		print html_search_form('',$what,array('submit'=>'Confirm '.($step=='d' ? 'delete':'detach'),'hr'=>false));
	print html_text_button('Go back',$page);
	}
	else
		html_error("No such configuration: $id");
}
else if( $a_machines )	{
	# machine config + group configs + globals
	$confs=qaconfs_for_machines($a_machines);
	$gconfs=$mconfs=array();
	for($i=1; $i<count($confs); $i++)	{
		$row=$confs[$i];
		$mconfs[$row['machine_qaconf_id']][]=$row;
		if( is_numeric($row['group_id']) )
			$gconfs[$row['group_qaconf_id']][]=$row;
	}

	# highlighted config ID
	$id=( count($mconfs)==1 ? array_first_key($mconfs) : 
		(count($gconfs)==1 ? array_first_key($gconfs) : null ) );

	# related config IDs
	$ids=array_unique(array_merge(qaconfs_global(),array_keys($mconfs),array_keys($gconfs)));

	# merged data
	if( count(array_keys($mconfs))<=1 && count(array_keys($gconfs))<=1 )	{
		print_qaconf_merge($ids,$id,'Highlighting current machine\'s configuration.');
	}

	# machine configs
	print "<h3>Machine configuration</h3>\n";
	foreach( $mconfs as $id=>$r )	{
		$names=join(', ',array_unique(my_array_column($r,'machine')));
		print_config_changer("Configuration for machine(s) <i>$names</i>",$id,array_unique(my_array_column($r,'machine_id')),null);
	}
	print html_div('list info','Source for the merge: machine configuration has highest priority. You can (re)assign existing configurations, or create a new one if none is assigned.');

	# group configs
	print "<h3>Group configuration</h3>\n";
	if( count($gconfs)>1 || array_first_key($gconfs) ) 	{
		foreach( $gconfs as $id=>$r )	{
			$names=join(', ',array_unique(my_array_column($r,'group')));
			if(( $members=groups_list_machine_names(my_array_column($r,'group_id')) ))
				$names .= ' ('.join(', ',$members).')';
			print_config_changer("Configuration for group(s) <i>$names</i>",$id,null,array_unique(my_array_column($r,'group')));
		}
		print html_div('list info','Group configuration is used for all machines in the group.');
	}
	else
		print "<p>Machine(s) not in a group.</p>\n";

	# configurations involved
	print_conf_list($ids,$id);

}
else if( $group )	{
	# group config
	$ids=qaconfs_global();
	if(($id=group_get_qaconf_id_by_name($group)))
		$ids[]=$id;

	# merged data
	print_qaconf_merge($ids,$id,'Highlighting current group\'s configuration.');

	print "<h3>Group configuration</h3>\n";
	print_config_changer("Configuration for group <i>$group</i>",$id,array(),$group);
	print html_div('list info','Configuration used for all machines in the group. Can be overriden by machines\' own one(s), and merges with system configs, before sent to machines. You can (re)assign it here, or create a new one if none is assigned.');

	# configurations involved
	print_conf_list($ids,$id);
}
else	{
	# config list
	print_conf_list();
}

function perm($id)
{
	global $perm_machines,$perm_system;
	return ( !is_null($id) && is_numeric($id) && $id<=QACONF_MAX_SYS_ID ? $perm_system : $perm_machines );
}

function check_perm_redirect($id=null)
{
	if( !perm($id) )
		redirect(array('url'=>$page));
}

function print_conf_list($ids=array(),$id_active=null)
{
	$admin=capable('master_administration');
	$logged=capable();
	$data=qaconf_list($ids,1,null);
	for( $i=1; $i<count($data); $i++ )	{
		$row=&$data[$i];
		$id=$row['qaconf_id'];
		$base="?go=machine_config&id=$id&step=";
		$local=!$row['sync_url'];
		$nonsys=($id>QACONF_MAX_SYS_ID);
		$local_nonsys=($local && $nonsys);
		$attached=(isset($row['groups']) || isset($row['machines']));
		$ctrl=array(
			'rows'=>array('url'=>$base.'v','enbl'=>true,'fullname'=>'content show','allowed'=>true),
			'edit'=>array('url'=>$base.'e','enbl'=>!$row['sync_url'],'err_noavail'=>'remote configurations cannot be edited, delete sync_URL first'),
			'net' =>array('url'=>$base.'eu','enbl'=>!($local&&$row['rows']),'fullname'=>'URL edit','err_noavail'=>'local configurations cannot be changed to remotes, delete rows first'),
			'sync'=>array('url'=>$base.'sync','enbl'=>!$local,'allowed'=>true,'err_noavail'=>'sync_url not set'),
#			'change'=>array('url'=>$base.'h'),
			'detach'=>array('url'=>$base.'t','enbl'=>$attached,'err_noavail'=>'cannot detach - not attached to groups/machines, or is system configuration'),
			'delete'=>array('url'=>$base.'d','enbl'=>($local && $nonsys && !$attached),'err_noavail'=>'deleting only possible for detached local non-system configurations'),
		);
		$row['ctrls']='';
		$defaults=array('enbl'=>$local_nonsys);
		foreach( array_keys($ctrl) as $c )
			$row['ctrls'].=task_icon(array_merge(array('type'=>$c,'allowed'=>($nonsys ? $logged : $admin)),$defaults,$ctrl[$c]));
		$row['cls']=(isset($id_active) && $id==$id_active ? 'search_result': ($id<=QACONF_MAX_SYS_ID ? 'system':'') );
	}
	$data[0]['ctrls']='controls';
	$data[0]['qaconf_id']='id';

	print "<h3>Configurations involved</h3>\n";
	print html_table($data,array('id'=>'qaconf_list','sort'=>'isisss','class'=>'list text-main tbl','callback'=>'colorize'));
	print html_div('list info','The table contains a listing of relevant configurations. Blue ones are system configs.');
	print html_div('list info','Configuration can be local (editable) or remote (syncable), depending if it has <i>sync_url</i> set, or rows in the local database. Before deleting a configuration, you need to detach it from all its machines and groups.');
}

function print_qaconf_merge($ids,$id_active,$desc_add='')
{
	$data=qaconf_merge($ids);
	for( $i=1; $i<count($data); $i++ )
		$data[$i]['cls']=( $data[$i]['qaconf_id']==$id_active ? 'search_result' : '' );
	$data[0]['src']='src';

	print "<h3>Data sent to machine(s)</h3>\n";
	print html_table($data,array('class'=>'list text-main tbl','callback'=>'colorize','id'=>'qaconf_result','sort'=>'ssss'));
	print html_div('list info','Resulting merged data, as sent to machines. The lines come from machine\'s configuration, group configuration, and system configurations (master, site, country, global). '.($id_active ? $desc_add : ''));
}

function print_config_changer($desc,$id=null,$a_machines=array(),$group=null)
{
	global $qaconf_lists;
	if( !isset($qaconf_lists) )
		$qaconf_lists=qaconf_list_for_select();
	$what1=array(
		array('submit','','set',HIDDEN),
		array('go','','machine_config',HIDDEN),
		array('wtoken','',token_generate(),HIDDEN),
		array('id',$qaconf_lists,$id,SINGLE_SELECT,$desc),
	);
	$what2=array();
	if( $group )
		$what2[]=array('group','',$group,HIDDEN);
	if( $a_machines )
		foreach($a_machines as $m)
			$what2[]=array('a_machines[]','',$m,HIDDEN);
	$what=array_merge($what1,$what2);
	print html_search_form('',$what,array('submit'=>'Set','hr'=>false));
	if( !$id )
		print html_link('Create new config',form_to_url("?go=machine_config&step=n",$what2));
}

# converts list from conf=>array(machine) to printable array(array(conf_desc,machine_names))
function sumarize_machine_list($list,$desc)
{
	$ret=array(array('desc'=>'config','names'=>$desc.'(s)'));	
	foreach( array_keys($list) as $k )
		$ret[]=array(
			'desc'=>($k ? qaconf_get_desc($k):'(none)'),
			'names'=>join(' ',array_map($desc.'_get_name',$list[$k])),
			'id'=>$k,
			'involved'=>$list[$k],
		);
	return $ret;
}

function my_array_column($array,$column) {
	foreach($array as &$value)
		$value = $value[$column];
	return $array;
}

function array_first_key($array)	{
	$keys=array_keys($array);
	return ( count($keys)>0 ? $keys[0] : null );
}

# returns last argument
function colorize()
{
	$data=func_get_args();
		if(is_array($data) && $data[count($data)-1] )
			return ' '.$data[count($data)-1];
}

?>
