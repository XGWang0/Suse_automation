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
$page_base = 'index.php';
$page = "$page_base?go=qa_netconf";


#print common_header(array('title'=>'QA config','header'=>false,'session'=>false));
$desc=http('desc','');
$body=http('body','');
$wtoken=http('wtoken');
$submit=http('submit');
$id=http('id');
$a_machines=http('a_machines');
$qaconf=http('qaconf');
$group=http('group');

if( token_read($wtoken) )	{
	if( $submit=='new' && $desc )	{
		transaction();
		update_result( qaconf_insert_unparsed($desc,$body), 1 );
		commit();
	}
	else if( $submit=='update' && $desc )	{
		transaction();
		update_result( qaconf_replace_unparsed($id,$desc,$body) );
		commit();
	}
	else if( $submit=='set_machine' && $a_machines )	{
		$m=array();
		$notfound=array();
		$succ=array();
		$fail=array();
		foreach($a_machines as $machine)	{
			$m1=Machine::get_by_id($machine);
			if( $m1 )
				$m[]=$m1;
			else
				$notfound=$m1;
		}
		if( count($m) )	{
			transaction();
			for( $i=0; $i<count($m); $i++ )	{
				if( $m[$i]->set('qaconf_id',$qaconf) )
					$succ[]=$m[$i];
				else
					$fail[]=$m[$i];
			}
			commit();
		}
		$msg='';
		if( count($notfound) )
			$msg .= "Could not find machine(s) ".join(',',$notfound)."<br/>\n";
		if( count($fail) )
			$msg .= "Update failed for machine(s) ".join(',',$fail)."<br/>\n";
		if( $msg )
			print html_error($msg);
		if( $succ )
			print html_success( "Successfully updated machine(s) ".join(',',$succ) );
	}
	else if( $submit=='set_group' && $group )	{
		if( !($g=Group::get_by_name($group)) )
			print html_error("No such group: $group");
		else	{
			transaction();
			update_result($g->set_qaconf_id($qaconf));
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
);
print steps("$page&step=",$steps,$step,$steps_alt);


if( $step=='e' )	{
	# edit config
	$body=qaconf_get_file($id);
	$desc=qaconf_get_desc($id);
}

$what=array(
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
else if( $step=='v' )	{
	# view details
	$data=qaconf_get_rows_translated($id);
	print html_table($data,array('id'=>'qaconf_view','sort'=>'sss'));
}
else if( $a_machines || $group )	{
	$qaconf=array_merge(array(array('null','')),enum_list_id_val('qaconf'));
	$w=array(
		array('go','','qa_netconf',HIDDEN),
		array('qaconf',$qaconf,'',SINGLE_SELECT,''),
		array('wtoken','',token_generate(),HIDDEN),
	);
	if( $a_machines )	{
		$m=array();
		foreach($a_machines as $machine)	{
			$m1=Machine::get_by_id($machine);
			if( $m1 )
				$m[]=$m1;
		}
		if( count($m) )	{
			print "<h3>Select config for machine(s) ".join(',',$m)."</h3>\n";
			$what=$w;
			$what[]=array('a_machines','',$a_machines,HIDDEN);
			$what[]=array('submit','','set_machine',HIDDEN);
			print html_search_form('',$what,array('submit'=>'Set'));
		}
		else
			print html_error("Machine(s) ".join(',',$a_machines)." not found");
	}
	else	{ # group
		$g=Group::get_by_name($group);
		if( $g )	{
			print "<h3>Select config for group $group</h3>\n";
			$what=$w;
			$what[]=array('group','',$group,HIDDEN);
			$what[]=array('submit','','set_group',HIDDEN);
			print html_search_form('',$what,array('submit'=>'Set'));
		}
		else
			print html_error("Group $group not found");
	}

	
}
else	{
	# view configuration
	$data=qaconf_list();
	table_translate($data,array(
		'links'=>array('qaconf_id'=>"$page&step=v&id="),
		'ctrls'=>array('edit'=>"$page&step=e&id="),
	));
	print html_table($data,array('total'=>1,'id'=>'qaconf_list','sort'=>'is'));
}


?>
