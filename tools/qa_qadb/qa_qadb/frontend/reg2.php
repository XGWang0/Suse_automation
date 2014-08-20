<?php
require_once('qadb.php');
common_header(array(
	'title'=>'QADB regression experiment',
));

$from='submission join tcf_group using(submission_id) join result using(tcf_id) join testcase using(testcase_id) join testsuite using(testsuite_id)';
$sel=array(
	'testsuite',
	'testcase',
	'product_id',
	'release_id',
	'sum(times_run) as runs',
	'sum(succeeded) as succ',
	'sum(failed) as fail',
	'sum(internal_error) as interr',
	'sum(skipped) as skip',
	'sum(test_time) as time'
);
$attrs_known=array(
	'submission_id'=>array('submission_id=?','i'),
	'testsuite'=>array('testsuite=?','s')
);
$attrs=array(
	'submission_id'=>array(11039,10450,11201),
#	'testsuite'=>'commands',
	'order_by'=>array('testsuite','testcase','product_id','release_id'),
	'group_by'=>array('testsuite','testcase','product_id','release_id'),
	'limit'=>array(100000)
);
$data=search_common($sel,$from,$attrs,$attrs_known);
table_translate($data,array(
	'enums'=>array(
#		'testcase_id'=>'testcase',
		'product_id'=>'product',
		'release_id'=>'release'
	)
));
print "<pre>\n";
$ret=html_grouped_table($data,array('product_id','release_id'),array('testsuite','testcase'),1,array('runs','succ','fail','interr','skip','time'),'result','filter');
print "</pre>\n";
print $ret;

print html_footer();
exit;

function result( $runs, $succ, $fail, $interr, $skip, $time )
{
	$classes = array('failed'=>'r','interr'=>'wr','skipped'=>'m','success'=>'i');
	$ret['text'] = ( $fail ? 'failed' : ( $interr ? 'interr' : ( $skip ? 'skipped' : 'success' )));
	$ret['title'] = "fail:$fail interr:$interr skip:$skip success:$succ time:$time";
	$ret['class'] = $classes[$ret['text']];
	return $ret;
}

function filter($rows)
{

	$stat=array();
	foreach( $rows as $column )
		foreach( $column as $row )
			foreach( $row as $field )
				$stat[$field['class']]=1;
	return ( count($stat) > 1 );
}

function html_grouped_table($data,$group_x=array(),$group_y=array(),$header=0,$aggregate_fields=array(),$aggregate_func=null,$filter_func=null)
{
	# concatenated axis values, to be used as hash keys
	$keys=array( 'y'=>array(), 'x'=>array() );

	# groupping attributes
	$group=array( 'y'=>$group_y, 'x'=>$group_x, 'a'=>$aggregate_fields );

	# split the table data into parts
	foreach( $data as $num=>$row )	{
		$is_header = ( $num=='header' || ($num==0 && $header) );

		# key is the concatenated value, we define it here and just reuse later
		$key=array();

		foreach( array('y','x','a') as $i )	{

			# remove X/Y/aggregate fields from data
			$val[$i] = array();
			foreach( $group[$i] as $gkey )	{
				if( isset($row[$gkey]) )	{
					$val[$i][$gkey] = $row[$gkey];
					unset($row[$gkey]);
				}
			}

			# for X and Y, concatenate & make a key
			if( $i!='a' )	{
				$key[$i] = join('|',$val[$i]);
				if( !$is_header && !isset($keys[$i][$key[$i]]) )
					$keys[$i][$key[$i]] = $val[$i];
			}
		}

		# now replace the original data row
		$data[$num] = array( 
			'y_key'=>$key['y'],
			'x_key'=>$key['x']
		);
		$data[$num]['data'] = $row;

		# aggregation is made here
		if( $aggregate_func && count($aggregate_fields) )	{

			# data are prepared by the aggregation callback
			$data[$num]['data'][$aggregate_func] = call_user_func_array($aggregate_func,$val['a']);

			# original values go here, can be used e.g. by filtering
			$data[$num]['aggr'] = $val['a'];
		}
	}
#	print "keys[y]="; print_r($keys['y']);
#	print "keys[x]="; print_r($keys['x']);
#	print "data="; print_r($data);

	# let's sort the X axis in a natural order
	# TODO: some data types should be sorted differently
	uksort( $keys['x'], 'strnatcasecmp' );

	# keys for X / Y and their values (in hashes)
	$val_y = $keys['y'];
	$val_x = $keys['x'];

	# data column names
	$val_fields = array_keys($data[0]['data']);

#	print "data=";print_r($data);
#	print "val_y="; print_r($val_y);
#	print "val_x="; print_r($val_x);
#	print "val_fields=";print_r($val_fields);

	# let's start printing
	$ret='<table class="tbl"><tr>';

	# header can have 1 or 2 rows, 2 we have multiple data fields needing description
	$header_height = ( count($val_fields) > 1 ? 2 : 1 );
	foreach( $group_y as $y )
		$ret .= "<th rowspan=\"$header_height\">$y</th>";
	foreach( $val_x as $x )	{
		$ret.='<th colspan="'.(count($val_fields)).'">'.join('<br/>',$x)."</th>";
	}
	$ret.="</tr>\n";

	# 2nd header row, if we have it
	if( $header_height==2 )	{
		$ret .= '<tr>';
		foreach( $val_x as $x )
			foreach( $val_fields as $f )
				$ret .= "<th>$f</th>";
		$ret .= "</tr>\n";
	}
	$ret.="</tr>\n";

	# data have the same ordering as $val_y, we just scan $val_y and take coming values from $data
	$i=($header ? 1 : 0);
	foreach( array_keys($val_y) as $y )	{
#		print "y=$y\n";

		# $rows[X][row] is the structure holding data for one row, i.e. one Y value
		$rows=array();

		# number of fields in $rows columns can be different, this is the maximum
		$max_depth=0;

		# read all values from $data as long as they match Y, copy them into $rows
		for( ; isset($data[$i]) && $data[$i]['y_key']==$y; $i++ )	{
#			print "row="; print_r($data[$i]);
			$x_key = $data[$i]['x_key'];
			$num = (isset($rows[$x_key]) ? count($rows[$x_key]) : 0);
			$rows[$x_key][$num] = $data[$i]['data'];
			$max_depth = max( $max_depth, $num+1 );
		}
#		print "rows="; print_r($rows);
#		print "max_depth=$max_depth\n";

		# filtering: drop the row if it does not match the custom conditions
		if( $filter_func && !call_user_func($filter_func,$rows) )
			continue;

		# print the row as multiple rows with Y value spanned over all of them
		$trow = '<tr>';
		foreach($val_y[$y] as $y_part)
			$trow .= '<td rowspan="'.$max_depth.'">'.$y_part.'</td>';
		for( $j=0; $j<$max_depth; $j++ )	{
			foreach( array_keys($val_x) as $x_key )	{
				$field = ( isset($rows[$x_key]) && count($rows[$x_key]) > $j ? $rows[$x_key][$j] : '' );
#				print "field="; print_r($field);
				if( !is_array($field) )
					$field = array($field);
				foreach( $val_fields as $f )	{
					if( !isset($field[$f]) )
						$field[$f]='';

					# field can be either sting and printed directly, or hash holding td's attributes
					if( is_array($field[$f]) )	{
						$tdata = $field[$f]['text'];
						unset( $field[$f]['text'] );
						$trow .= '<td';
						foreach( $field[$f] as $key=>$val )
							$trow .= " $key=\"$val\"";
						$trow .= ">$tdata</td>";
					}
					else
						$trow .= '<td>' . (isset($field[$f]) ? $field[$f] : '') . '</td>';
				}
			}
		}
		$ret .= $trow . "</tr>\n";
	}
	return $ret."</table>\n";	
}

?>
