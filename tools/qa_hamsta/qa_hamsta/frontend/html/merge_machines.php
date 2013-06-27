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

$vals = array();
$machines = array();
foreach( $ids as $id )	{
	$machine = Machine::get_by_id($id);
	$machines[] = $machine;
	foreach( array_keys($fields) as $field )	{
		$vals[$field][] = $machine->get($field);
	}
}

# HTML form & table head
print '<form name="merge_machines" action="index.php?go=merge_machines" method="post">'."\n";
if( count($ids) )
	print '<input type="hidden" name="primary_machine_id" value="'.$ids[0]."\"/>\n";
print "<table class=\"list\">\n\t<tr><th>ID</th>";

# first row
foreach( $ids as $id )
	print "<th>$id</th>";
print "<th>merged</th></tr>\n";

# iterate over machine attributes
foreach( array_keys($vals) as $key )	{

	# merging type, enum flag
	$type = $fields[$key];
	$flag=0;
	if( $type!='s' )
		merge_unique($vals[$key],$ret,$flag);
	else
		merge_strings($vals[$key],$ret,$flag);
	$is_enum = ( strlen($type) > 1 );

	# row class ( for highlight )
	$class = ( $flag ? 'diff' : 'small"' );
	if( $type=='n' )
		$class.=" disabled";

	# print attr values
	print "\t<tr class=\"$class\"><th>$key</th>";
	foreach($vals[$key] as $val)	{
		if( $is_enum )
			$val = Machine::enumerate($key,$val);

                /* We need to display user name instead of user_id from db.  */
                if ( $key == 'usedby' )
                  {
		    $print_val = $val;
                    if ( $mach_user = User::getById ($val, $config) )
                      $print_val = $mach_user->getLogin ();
                  }
		else
		  {
		      $print_val = $val;
		  }

		print "<td>$print_val</td>";
	}

	# print merge column
	if(is_array($ret) || $is_enum || $key == 'usedby')	{
		# enums and 'S' (one-of) produce a select
		print "<td><select name=\"$key\">";
		if( $is_enum ) {
			if( is_array($ret) ) # enum, different values -> select one of them
				$enum = Machine::enumerate($key,$ret);
			else # enum, same values -> preselected, alternatives listed
				$enum = Machine::enumerate($key);

			# print the options
			foreach ( $enum as $k=>$v ) {
				$selected = ((!is_array($ret) && $k==$ret) || (is_array($ret) && $k==$vals[$key][0]) ? ' selected="yes"' : '');
				printf('<option value="%s"%s>%s</option>',htmlspecialchars($k),$selected,htmlspecialchars($v));
			}
		} else if (! strcmp ($key, 'usedby')) {
			# We need to print user login instead of number
			if (is_array ($ret)) {
				foreach ( $ret as $r ) {
					$ulogin = $r;
					if ( $mach_user = User::getById ($r, $config) ) {
					  $ulogin = $mach_user->getLogin ();
					}
					printf('<option value="%s">%s</option>', $r, htmlspecialchars ($ulogin));
				}
			} else {
				printf ('<option value=""></option>');
				$ulogin = $ret;
				if ( $mach_user = User::getById ($ulogin, $config) ) {
					$ulogin = $mach_user->getLogin ();
				}
				printf ('<option value="%s" selected="selected">%s</option>', $val, $ulogin);
			}
		}
		else {
			# non-enums, one-of('S'), different values -> just print them
			foreach ( $ret as $r )
                          {
			     printf('<option value="%s">%s</option>',$r,htmlspecialchars($r));
			  }
		}
		print "</select></td>\n";
	}
	else  # non-enums, same values or concatenation('s') -> text box
		printf("<td><input name=\"%s\" type=\"text\" %s value=\"%s\"/></td>",$key,(strlen($ret)>20 ? 'size="'.strlen($ret).'"' : ''),$ret);
	print "</tr>\n";
}
print "</table>\n";
foreach($ids as $id)
	print '<input type="hidden" name="a_machines[]" value="'.$id."\"/>\n";
print '<input type="submit" name="submit" value="Merge!"/>'."\n";
print "</form>\n";

?>
