<?php
/* ****************************************************************************
  Copyright (c) 2013 Unpublished Work of SUSE. All Rights Reserved.
  
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

	function genRefresh($pre_page)
	{
		$pre_value="init";
		$GLOBALS['xml_norefresh'] = "";
		if(request_int("page")){ $GLOBALS['refresh_page'] = "&amp;page=".request_int("page");}else{$GLOBALS['refresh_page']="";};
		if(request_int("machine")){ $GLOBALS['refresh_machine'] = "&amp;machine=".request_int("machine");}else{$GLOBALS['refresh_machine']="";};
		if(request_str("interval") && !preg_match("/^[0-9]+$/", request_str("interval")))
		{
			$pre_value = request_int("pre_value");
                        Notificator::setErrorMessage ('The refresh interval must be a positive number!');
		};

		if(request_int("interval")&&(request_int("interval")>0))
		{
			$GLOBALS['refresh_interval'] = "&amp;interval=".request_int("interval");
			$GLOBALS['html_refresh_interval'] = request_int("interval");
			if($pre_page == "jobruns"){ $GLOBALS['html_refresh_uri'] = "index.php?go=jobruns".$GLOBALS['refresh_page'].$GLOBALS['refresh_machine'].$GLOBALS['refresh_interval'];};
			if($pre_page == "job_details"){$GLOBALS['html_refresh_uri'] = "index.php?go=job_details&amp;id=".$GLOBALS['job']->get_id()."&amp;d_return=".$GLOBALS['d_return']."&amp;d_job=".$GLOBALS['d_job'].$GLOBALS['refresh_interval'];};
		} else {
			$GLOBALS['html_refresh_interval'] = 30;
			$GLOBALS['refresh_interval'] = "";
			if($pre_value != "init")
			{	
				$GLOBALS['html_refresh_interval'] = $pre_value;
				$GLOBALS['refresh_interval'] = "&amp;interval=".$pre_value;
			}

			if($pre_page == "jobruns"){ $GLOBALS['html_refresh_uri'] = "index.php?go=jobruns".$GLOBALS['refresh_page'].$GLOBALS['refresh_machine'].$GLOBALS['refresh_interval'];};
			if($pre_page == "job_details"){ $GLOBALS['html_refresh_uri'] = "index.php?go=job_details&amp;id=".$GLOBALS['job']->get_id()."&amp;d_return=".$GLOBALS['d_return']."&amp;d_job=".$GLOBALS['d_job'].$GLOBALS['refresh_interval'];};
		};
		if(request_int("norefresh") || request_int("page") > 0 || ( isset($GLOBALS['job']) && $GLOBALS['job']->get_status_string() != "running" ) )
		{
			unset($GLOBALS['html_refresh_interval']);
			unset($GLOBALS['html_refresh_uri']);
			$GLOBALS['refresh_interval']="";
			$GLOBALS['xml_norefresh'] = "&amp;norefresh=1";
		}


	}

	function TrimArray($Input) {
		if (!is_array($Input))
			return trim($Input);
		return array_map('TrimArray', $Input);
	}

	function profiler_init()	{
		global $prof_begin;
		$prof_begin=microtime(true);
	}

	function profiler_print($where=null)	{
		global $prof_begin;
		$now=microtime(true);
		if( $where )
			print("$where : ");
		printf("%f us<br/>\n",1000000*($now-$prof_begin));
	}

/**
 * Merge and concatenate strings (type 's').
 *
 * @param string[] $s Array of strings to merge.
 * @param string $ret String where strings will be merged to.
 * @param boolena $flag True if there were differences.
 */
function merge_strings ($s, &$ret, &$flag)
{
  $s = array_unique ($s);
  $ret = $s[0];
  $flag = 0;
  $i = 1;

  for ( ; $i < count ($s); $i++ )
    {
       if ( ! isset ($s[$i]) )
         continue;

       if ( strlen ($ret) )
         {
           $ret = $ret . ', ' . $s[$i];
         }
       else
         {
           $ret = $s[$i];
         }
    }

  $flag = $i - 1;
}

/**
 * Merge arrays (type 'S', one-of).
 *
 * @param array $s Array of values to merge.
 * @param array $ret Array in which the result will be merged.
 * @param boolean $flag True if there were differences.
 */
function merge_unique ($s, &$ret, &$flag)
{
  $ret = array_unique ($s);
  for ( $i = 0; $i < count ($ret); $i++ )
    {
      if ( isset ($ret[$i]) )
        rtrim ($ret[$i]);

      if ( ! isset ($ret[$i]) || strlen ($s[$i]) == 0 )
        array_splice ($ret, $i, 1);
    }

  $flag = (count ($ret) > 1) ? 1 : 0;

  if ( ! $flag )
    $ret = (count ($ret)) ? $ret[0] : '';
}

function act_menu($args)
{
	$conf = ConfigFactory::build ();
print "<div id='cssmenu'>";
print "<ul>";
print "<li class='active'><img src=\"" . $args['start']['src']  . "\" alt=\"power\"/>";
print "<ul>";
print "<li><a href=\"" . $args['start']['href'] . "\"><img src=\"" . $args['start']['src']  . "\"/>Start</a></li>";
print "<li><a href=\"" . $args['restart']['href'] . "\"><img src=\"" . $args['restart']['src']  . "\"/>Restart</a></li>";
print "<li><a href=\"" . $args['stop']['href'] . "\"><img src=\"" . $args['stop']['src']  . "\"/>Stop</a></li>";
print "</ul></li>";
print "<li class='has-sub'><img src=\"" . $args['send-job']['src']. "\" alt=\"jobs\"/>";
print "<ul>";
print "<li class='has-sub'><a href=\"" . $args['send-job']['href'] . "\"><img src=\"" . $args['send-job']['src']. "\"/>Send job</a>";
print "<ul>";
print "<li><a href=\"" . $args['send-job']['href'] . "#predefined\"><img src=\"" . $args['send-job']['src']. "\"/>Pre-defined job</a></li>";
print "<li><a href=\"" . $args['send-job']['href'] . "#qapackage\"><img src=\"" . $args['send-job']['src']. "\"/>QA package job</a></li>";
print "<li><a href=\"" . $args['send-job']['href'] . "#multimachine\"><img src=\"" . $args['send-job']['src']. "\"/>Multi-machine job</a></li>";
print "<li><a href=\"" . $args['send-job']['href'] . "#customjob\"><img src=\"" . $args['send-job']['src']. "\"/>Custom job</a></li>";
print "</ul></li>";
print "<li><a href=\"" . $args['reinstall']['href'] . "\"><img src=\"" . $args['reinstall']['src']  . "\"/>Reinstall</a></li>";
print "<li><a href=\"" . $args['free']['href'] . "\"><img src=\"" . $args['free']['src']  . "\"/>Free</a></li>";
print "</ul></li>";
print "<li><img src=\"" . $args['edit']['src']  . "\" alt=\"edit/reserve\"/>";
print "<ul>";
print "<li><a href=\"" . $args['edit']['href'] . "\"><img src=\"" . $args['edit']['src']  . "\"/>Edit</a></li>";
print "<li><a href=\"" . $args['config']['href'] . "\"><img src=\"" . $args['config']['src']  . "\"/>Configure</a></li>";
print "<li><a href=\"" . $args['delete']['href'] . "\"><img src=\"" . $args['delete']['src']  . "\"/>Delete</a></li>";
print "</ul></li>";
print "<li class='last'><img src=\"" . $args['vnc']['src']  . "\" alt=\"console\"/>";
print "<ul>";
print "<li><a href=\"" . $args['vnc']['href'] . "\"><img src=\"" . $args['vnc']['src']  . "\"/>VNC</a></li>";
/* Show serial console icon only if the server is properly configured. */
if (! empty ($conf->cscreen->console->server)) {
	print "<li><a href=\"" . $args['console']['href'] . "\"><img src=\"" . $args['console']['src']  . "\"/>Console</a></li>";
}
print "</ul></li>";
print "</ul>";
print "</div>";

}


function icon($args)	
{
	$args['border']=0;
	$args['width']=20;
	if( !isset($args['class']) )
		$args['class']='machine_actions icon-small';
	return html_tag('img',null,$args);
}

# Prints a control icon.
# Supported named arguments:
# - 'pwr': true if it is a powerswitch button
# - 'url': URL of the link
# - 'allowed': condition to know if button is allowed
# - 'link': true if it is link even for non-allowed buttons (to be solved in the target)
# - 'enbl': condition to know if button is enabled
# - 'confirm': if it has a javascript confirmation on click
# - 'object': name of machine or group where the button's action is executed
# - 'type': short action name, base of icons' name
# - 'fullname': long action name for tooltips
# - 'err_noperm' : tooltip message if action not permitted
# - 'err_noavail': tooltip message if action not available
# - 'size': size of the icon (directory where icon lives, default value is '27')
function task_icon($a,$ref=0)
{
	$a=array_merge(array( # merge with default values
		'url'=>'','allowed'=>true,'link'=>false,'enbl'=>true,'confirm'=>false,'object'=>'',
		'size'=>'27'),$a);
	$fullname=hash_get($a,'fullname',$a['type']);
	$size = ($a['size'] > 0 ? $a['size'] . '/' : '');
	$imgurl='images/'.$size.'icon-'.$a['type'];
	$err_noperm=hash_get($a,'err_noperm',"Cannot $fullname ".$a['object']." unless you are logged in and have enough privileges and/or have reserved the machine");
	$err_noavail=hash_get($a,'err_noavail',preg_replace('/e?$/','ing ',$fullname,1).$a['object'].' is not supported');

	if( !$a['enbl'] || !$a['allowed'] ) {
		$err_msg=( $a['enbl'] ? $err_noperm : $err_noavail );
		$icon=array('src'=>"$imgurl-grey.png",'alt'=>$err_msg,'title'=>$err_msg);
		if(!$a['link'])	{
			 $icon['href']='#';
		}
	} else {
		$args=array('src'=>"$imgurl.png",'alt'=>"$fullname ".$a['object'],'title'=>"$fullname ".$a['object']);
		if( $a['confirm'] )	{
			$args['onclick']="return confirm('This will $fullname ".$a['object'].". Are you sure you want to continue?')\n";
		}
		$icon=$args;
	}

	if (! $ref) {
		$icon = html_tag('a', icon ($icon), array('href'=>$a['url']));
	} else {
		$icon['href']=$a['url'];
	}
	return $icon;
}

function machine_icons($machine,$user)
{
	global $config;
	if( !$machine )
		return "No such machine";
	$id=$machine->get_id();
	$ret='';
	$rh = new ReservationsHelper ();
	$users_machine = count ($rh->getForMachineUser ($machine, $user));
	$number_of_users = count ($rh->getForMachine ($machine));
	$has_pwr=(($machine->get_powerswitch()!=NULL) and ($machine->get_powertype()!=NULL) and $machine->check_powertype());
	$host=$machine->get_hostname();
	$ip=$machine->get_ip_address();
	$url_base="index.php?a_machines[]=$id";
	$auth=$config->authentication->use;

	# button definition, plus non-default attributes.
	# Default see below, description see above.
	# - 'pwr': true if it is a powerswitch button
	$btn=array(
		'start'=>array('pwr'=>true),
		'restart'=>array('pwr'=>true),
		'stop'=>array('pwr'=>true),
		'reinstall'=>array(),
		'edit'=>array('allowed'=>(!$auth || (($users_machine || !$number_of_users) ? capable('machine_edit','machine_edit_reserved') : capable('machine_edit_reserved'))),'link'=>true),
		'free'=>array('url'=>"$url_base&go=machine_edit&action=clear",'enbl'=>$users_machine,'err_noavail'=>"You cannot free $host because it is already free."),
		'send-job'=>array(),
		'vnc'=>array('url'=>"http://$ip:5801"),
		'console'=>array('url'=>'hamsta-cscreen:'.$config->cscreen->console->server."/$host"),
		'delete'=>array('enbl'=>!preg_match('/^vm\//',$machine->get_type())),
		'config'=>array('link'=>true),
	);

	foreach( array_keys($btn) as $act )	{
		$is_pwr = isset($btn[$act]['pwr']) ? $btn[$act]['pwr'] : false; # is power button ?
		$perm='machine_'.($is_pwr ? 'powerswitch' : str_replace('-','_',$act)); # permission name
		$permr=$perm.'_reserved';
		$b = array_merge( # we take defaults and overwrite them by $btn[$act]
			array( # default values for a button
				'url'=>$url_base.($is_pwr ? "&go=power&action=$act":"&go=$perm"),
				'allowed'=>(!$auth || ($users_machine ? capable($perm,$permr) : capable($permr))),
				'enbl'=>($is_pwr ? $has_pwr : true),
				'confirm'=>$is_pwr,
				'object'=>$host,
				'type'=>$act,
			),
			$btn[$act]);
		if( $is_pwr )
			$b['err_noavail']="No powerswitch configured for $host.";
		$ret[$act]=task_icon($b,1);
	}
	return act_menu($ret);
}

function group_icons($group,$user)
{
	global $config;
	$ret='';
	$gid=$group->get_id();
	$gname=$group->get_name();
	$url_base="index.php?group=$gname&id=$gid";
	$auth=$config->authentication->use;

	$btn=array(
		'list'=>array('url'=>"index.php?go=machines&group=$gname"),
		'edit'=>array('url'=>"$url_base&go=create_group&action=edit"),
		'add'=>array('url'=>"$url_base&go=create_group&action=addmachine"),
		'remove'=>array('url'=>"$url_base&go=del_group_machines"),
		'delete'=>array('url'=>"$url_base&go=del_group"),
		'config'=>array('url'=>"$url_base&go=machine_config",'link'=>true),
	);
	foreach( array_keys($btn) as $act )	{
		$b = array_merge(
			array( # default values
				'allowed'=>(!$auth || ($user!=null) || $act=='list'),
				'enbl'=>($gid>0 || $act=='list' || $act=='config'),
				'object'=>$gname,
				'type'=>$act,
			),
			$btn[$act]);
		$ret.=task_icon($b);
	}
	return $ret;
}

function virtual_machine_icons ($machine, $user)
{
	$ret = '';
	$conf = ConfigFactory::build ();
	$auth = $conf->authentication->use;

	$mid		= $machine->get_id ();
	$hostname	= $machine->get_hostname ();
	$ip		= $machine->get_ip_address();

	$rh		= new ReservationsHelper ();
	$users_machine	= count ($rh->getForMachineUser ($machine, $user));
	$number_of_users = count ($rh->getForMachine ($machine));
	$url_base	= 'index.php?a_machines[]=' . $mid;

	$icons = array (
		'edit'		=> array ('url' => $url_base . '&go=machine_edit',
					  'allowed' => ! $auth || $users_machine || ! $number_of_users,
					  'link' => true),
		'free'		=> array ('url' => $url_base . '&go=machine_edit&action=clear',
					  'enbl' => $users_machine),
		'send-job'	=> array ('url' => $url_base . '&go=machine_send_job'),
		'vnc'		=> array ('url' => 'http://' . $ip . ':5801'),
		'delete'	=> array ('url' => $url_base . '&go=del_virtual_machines',
					  'fullname' => 'Delete virtual machine and all related data of')
	);

	foreach (array_keys ($icons) as $icon) {
		$icon_def = array_merge (array (
				'type'	 => $icon,
				'object' => $hostname),
				$icons[$icon]);
		$ret .= task_icon ($icon_def);
	}
	return $ret;
}

function redirect($args=array())
{
	$errmsg=hash_get($args,'errmsg','You need to be logged in and/or have permissions ');
	$url=hash_get($args,'url','index.php');
	fail($errmsg);
	header("Location: $url");
	exit();
}

function disable($args=array())
{
	global $disabled_css;
	$errmsg=hash_get($args,'errmsg','You need to be logged in and/or have permissions to do any modifications here');
	fail($errmsg);
	$disabled_css=true;

	# FIXME: this prevents TBlib's update forms from updating, but is not a clean solution.
	unset($_REQUEST['wtoken']);
}

function success($msg)
{
	$_SESSION['message']=$msg;
	$_SESSION['mtype']='success';
}

function fail($msg)
{
	$_SESSION['message']=$msg;
	$_SESSION['mtype']='fail';
}

function get_machine_status_class ($status_id) {
	$class = '';
	switch ($status_id) {
	case 1:
		return 'machine_up';
		break;
	case 2:
		return 'machine_down';
		break;
	case 5:
		return 'machine_not_responding';
		break;
	case 6:
		return 'machine_unknown';
		break;
	default:
		// No default action here.
	}
	return $class;
}

?>
