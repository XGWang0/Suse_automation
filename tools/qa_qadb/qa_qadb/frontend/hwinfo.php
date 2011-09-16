<?php

require_once("qadb.php");
common_header(array('title'=>'HWinfo'));

$hwinfoID=http('hwinfoID');

# search form
$what = array(
	array('hwinfoID', '', $hwinfoID, TEXT_ROW, 'HWinfoID(s)')
);
print html_search_form('hwinfo.php',$what);

# split $hwinfoID, fetch existing 
$splitted = explode(',',$hwinfoID);
$hwinfos=array();
$errors=array();
foreach( $splitted as $id )	{
	if( !is_numeric($id) )
		continue;
	$hwinfo = hwinfo_get($id);
	if( $hwinfo )
		$hwinfos[$id] = $hwinfo;
	else
		$errors[]=$id;
}
$cnt = count($hwinfos);
$val=array_values($hwinfos);

# non-existing hwinfoIDs
if( count($errors) )
	print html_error("No such hwinfoID(s): " . join(', ',$errors));

# header, referers
if( $cnt )	{
	print '<h2>'. ($cnt==1 ? 'HWinfo for ID' : 'Diff hwinfoIDs') . ' ';
	print join(', ',array_keys($hwinfos));
	print "</h2>\n";

	print '<div class="screen allresults">References :';
	foreach( array_keys($hwinfos) as $id )
		printf("\t%s\n",html_text_button($id,"submission.php?hwinfoID=$id&search=1"));
	print "</div>\n";
}

# print results
if( $cnt == 1 )
{
	# simple print
	print "<pre>".$val[0]."</pre>\n";
}
else
{
	$trees=array();
	foreach($hwinfos as $id=>$hwinfo)	{
		$pos=0;
		$trees[$id] = parse_tree(split("\n",$hwinfo),$pos,0);
	}
	compare_trees($trees);
}

print html_footer();

# converts hwinfo text into a memory tree
function parse_tree($data,&$pos,$depth)
{
	$nodes=array();
	$last=null;
	for(; $pos<count($data); $pos++)	{
		$row = ltrim($data[$pos]);

		# ignore empty rows
		if( !strlen($row) )
			continue;
		
		# depth
		$adepth = ( strlen($data[$pos])-strlen($row) ) / 2;

		# depth decreased - return from recursion
		if( $adepth < $depth )	{
			$pos--;
			break;
		}

		# split row by last ': ' or '#', providing they aren't duplicated
		$left=$row;
		$right=null;
		$parts=preg_split('/: /',$row);
		if( count($parts) != 2 )
			$parts=preg_split('/#/',$row);
		if( count($parts) == 2 )	{
			$left=$parts[0];
			$right=$parts[1];
		}
		
		# process row / subtree
		if( $adepth==$depth )
			$nodes[$left] = $right;
		else	{
			$subtree = parse_tree($data,$pos,$adepth);
			if( $last )	{
				if( !is_null($nodes[$last]) )	{
					# re-merge splitted row
					assert(!is_array($nodes[$last]));
					$l = $last.': '.$nodes[$last];
					unset($nodes[$last]);
					$last = $l;
				} 
				$nodes[$last] = $subtree;
			} else {
				$nodes = $subtree;
			}
		}
		$last = $left;
	}
	return $nodes;
}

function compare_trees($trees)
{
	$header=array('path'=>'path');
	foreach( $trees as $id=>$hwinfo )
		$header[$id] = $id;
	$ret = compare_trees_step(array(),$trees);
	$data = array_merge(array($header),$ret);
	print html_table($data,array());
}

function compare_trees_step($path,$trees)
{
	$ret=array();
	foreach( get_key_union($trees) as $key )	{
		$strings=array();
		$arrays=array();
		$missing=array();
		foreach( $trees as $id=>$hwinfo )	{
			if( is_null($hwinfo) || !array_key_exists($key,$hwinfo) ) /* missing */
				$missing[$id] = 1;
			else if( !is_array($hwinfo[$key]) ) /* string */
				$strings[$hwinfo[$key]][] = $id;
			else /* subtree */ {
				$arrays[] = $id;
			}
		}

		# strings & equal - skip
		if( count($arrays)==0 && count($missing)==0 && count($strings)==1  )
			continue;

		# prepare hash of subtrees
		$args=array();
		foreach( $trees as $id=>$hwinfo )
			$args[$id] = (array_key_exists($key,$hwinfo) ? $hwinfo[$key] : null);

		# all subtrees - recursion
		if( count($strings)==0 && count($missing)==0 )
		{
			# recursion
			if( $ret_row = compare_trees_step(array_merge($path,array($key)),$args) )
				$ret = array_merge($ret,$ret_row);
		} else {
			# mixed
			
			# at least two of $strings, $arrays, $missing should be nonempty here
			assert(count($strings) + (count($arrays)?1:0) + (count($missing)?1:0) >1);

			$ret_row = dump_trees('',$args);
			foreach($ret_row as $k=>$v)
				$ret_row[$k] = join('<br/>',$v);
			foreach( $strings as $k=>$vals )
			{
				$kb = breakable($k);
				foreach($vals as $v)
					$ret_row[$v] = preg_replace('/,/',',<wbr/>',$kb);
			}
			if( count($missing) )
				foreach($ret_row as $id=>$v)
					if( !array_key_exists($id,$missing) )
						$ret_row[$id]=$key.($v? ": $v":'');
			$ret_row['path']=$path;
			if( !count($missing) )
				$ret_row['path'][] = $key;
			$ret_row['path']=join(' / ',array_map(create_function('$a','return "<nobr>$a</nobr>";'),$ret_row['path']));
			$ret[]=$ret_row;
		}
	}
	return $ret;
}

function breakable($string)
{
	return preg_replace('/,/',',<wbr/>',$string);
}

function dump_trees($prefix,$trees)
{
	# create empty dump arrays
	$dumps = array_combine( array_keys($trees), array_fill(0,count($trees),array()) );

	# process all the tree nodes
	foreach( get_key_union($trees) as $key )	{

		# check different node types
		$subtrees=array();
		foreach( $trees as $id=>$hwinfo )	{
			# compare keys
			if( is_null($hwinfo) || !array_key_exists($key,$hwinfo) ) /* missing */
			;
#				$dumps[$id][]='';
			else if( !is_array($hwinfo[$key]) ) /* string */
				$dumps[$id][]=$key.($hwinfo[$key] ? ': '.breakable($hwinfo[$key]) : '');
			else /* subtree */
				$subtrees[$id]=$hwinfo[$key];

			# set missing subtrees to null
			if( !array_key_exists($id,$subtrees) )
				$subtrees[$id] = null;
		}

		# dump subtrees
		if( $subtrees )	{
			$sub = dump_trees($prefix.'  ',$subtrees);
			foreach( $sub as $id=>$dump )
				$dumps[$id] = array_merge($dumps[$id],$sub[$id]);
		}
	}

	return $dumps;
}

# returns array of keys in the top level of all $trees
function get_key_union($trees)
{
	$key_hash=array();
	foreach( $trees as $id=>$hwinfo )
		if( is_array($hwinfo) )
			$key_hash = array_merge($key_hash,$hwinfo);
	return array_keys($key_hash);
}
?>
