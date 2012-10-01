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

/**
 * Content of the <tt>about</tt> page.
 */

if (!defined('HAMSTA_FRONTEND')) {
	$go = 'merge_machines';
	return require("index.php");
}

/* First check if the user has privileges to run this functionality. */
if ( $config->authentication->use )
  {
    if ( User::isLogged () && User::isRegistered (User::getIdent (), $config) )
      {
        $user = User::getInstance ($config);
        if ( ! $user->isAllowed ('machine_merge')
             && ! $user->isAllowed ('machine_merge_reserved') )
          {
            Notificator::setErrorMessage ("You do not have privileges to merge machines.");
            header ("Location: index.php");
            exit ();
          }
      }
    else
      {
        Notificator::setErrorMessage ("You have to logged in and registered to merge machines.");
        header ("Location: index.php");
        exit ();
      }
  }

$ids = request_array("a_machines");
if( count($ids)<2 )	{
  Notificator::setErrorMessage ('Need at least 2 machines to merge.');
	header('Location: index.php');
	exit();
}

sort($ids,SORT_NUMERIC);
$ids = array_reverse($ids);

# 's' means a string type with concatenation possible (e.g. comments)
# 'S' means a string type with one-of selection (e.g. MAC address)
# 'n' means non-implemented attrs
# words longer than 1 mean enums
$fields = array(
	'name' => 'S', # generic
	'ip' => 'S', # generic
	'product_id' => 'product', # generic
	'release_id' => 'release', # generic
	'product_arch_id' => 'arch', # generic
	'arch_id' => 'arch', # generic
	'last_used' => 'S', # generic
	'unique_id' => 'S', # generic
	'powerswitch' => 'S',
	'serialconsole' => 'S',
	'consoledevice' => 'S',
	'consolespeed' => 'S',
	'consolesetdefault' => 'S',
	'default_option' => 'S',
	'machine_status_id' => 'machine_status',
	'maintainer_id' => 's',
	'usedby' => 'i',
	'usage' => 's',
	'expires' => 'S',
	'reserved' => 'S',
	'description' => 'S',
	'affiliation' => 's', 
	'anomaly' => 's', 
	'role' => 's', # generic
	'type' => 'S', # generic
	'vh_id' => 'S', # generic
);

if( request_str('submit') )	{
	$primary_machine_id=request_str('primary_machine_id');
	$primary_machine = Machine::get_by_id($primary_machine_id);
	if( $primary_machine )	{
		$ret = true;

		# update table 'machine'
		foreach(array_keys($fields) as $field)	{
			$val = request_str($field);
			$ret = $ret and $primary_machine->set($field,$val);
		}
		if( $ret )	{
			# merge other machines' related info (group, jobs, logs, config)
			# then delete the other machine
			foreach( $ids as $id )	{
				if( $id==$primary_machine_id )
					continue;
				$machine = Machine::get_by_id($id);
				if($machine)	{
					$ret = $ret && $primary_machine->merge_other_machine($id);
					if( !$ret ) break;
					$ret = $ret && $machine->del_machine();
					if( !$ret ) break;
				}
			}
		}
		# prepare result message
		if( $ret )	{
			$_SESSION['message']='Machines merged.';
			$_SESSION['mtype']='success';
		} else {
			$_SESSION['message']='Merge failed.';
			$_SESSION['mtype']='fail';
		}
		header('Location: index.php');
		exit();
	}
}

$html_title="Merge machines";
?>
