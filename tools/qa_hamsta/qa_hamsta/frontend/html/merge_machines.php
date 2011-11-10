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
		print "<td>$val</td>";
	}
	# print merge column
	if(is_array($ret) || $is_enum)	{
		# enums and 'S' (one-of) produce a select
		print "<td><select name=\"$key\">";
		if( $is_enum )	{
			if( is_array($ret) ) # enum, different values -> select one of them
				$enum = Machine::enumerate($key,$ret);
			else # enum, same values -> preselected, alternatives listed
				$enum = Machine::enumerate($key);

			# print the options
			foreach( $enum as $k=>$v )	{
				$selected = ((!is_array($ret) && $k==$ret) || (is_array($ret) && $k==$vals[$key][0]) ? 'selected="yes"' : '');
				printf('<option value="%s"%s>%s</option>',htmlspecialchars($k),$selected,htmlspecialchars($v));
			}
		}
		else	{
			# non-enums, one-of('S'), different values -> just print them
			foreach( $ret as $r )	{
				$r=htmlspecialchars($r);
				printf('<option value="%s">%s</option>',$r,$r);
			}
		}
		print "</select></td>";
	}
	else # non-enums, same values or concatenation('s') -> text box
		printf("<td><input name=\"%s\" type=\"text\" %s value=\"%s\"/></td>",$key,(strlen($ret)>20 ? 'size="'.strlen($ret).'"' : ''),$ret);
	print "</tr>\n";
}
print "</table>\n";
foreach($ids as $id)
	print '<input type="hidden" name="a_machines[]" value="'.$id."\"/>\n";
print '<input type="submit" name="submit" value="Merge!"/>'."\n";
print "</form>\n";

# function to merge and concatenate strings ( 's' type )
function merge_strings($s,&$ret,&$flag)	{
	$s=array_unique($s);
	$ret=$s[0];
	$flag=0;
	for( $i=1; $i<count($s); $i++ )	{
		if( !isset($s[$i]) || !strlen($s[$i]) )
			continue;
		if( strlen($ret) )	{
			$ret = $ret . ', ' . $s[$i];
			$flag=1;
		}
		else
			$ret = $s[$i];
	}
}

# function to merge (type 'S', one-of)
function merge_unique($s,&$ret,&$flag)	{
	$ret=array_unique($s);
	for( $i=0; $i<count($ret); $i++ )	{
		if( isset($ret[$i]) )
			rtrim($ret[$i]);
		if( !isset($ret[$i]) || strlen($s[$i])==0 )
			array_splice($ret,$i,1);
	}
	$flag = (count($ret)>1 ? 1:0);
	if( !$flag )
		$ret=(count($ret) ? $ret[0] : '');
}

?>
