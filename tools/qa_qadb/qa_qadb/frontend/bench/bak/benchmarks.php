<?php

$debug=false;

# 1. load GET/POST values
$tests = array();
if( !empty( $_REQUEST['tests'] ) )
	$tests = array_map(create_function('$a','return 0+$a;'),(array)$_REQUEST['tests']);

$group_by = $_REQUEST['group_by'];
if( ! preg_match( '/^[\w\s,\.]+$/', $group_by ) )
	$group_by = 'tcfID';

$group_attrs = split(',',$group_by);


# 2. redirect when missing basic form data
if( count($tests) == 0 )
{
	header( 'Location: search.php' );
	return;
}

# 3. load required libs, print header
//require_once($_SERVER['DOCUMENT_ROOT'].'/config.php');
require_once($_SERVER['DOCUMENT_ROOT'].'/bench/functions.php');
require_once($_SERVER['DOCUMENT_ROOT'].'/hrf/html_func.php');
#require_once($_SERVER['DOCUMENT_ROOT'].'/hrf/phplot/phplot.php');
#require_once($_SERVER['DOCUMENT_ROOT'].'/hrf/phplot/phplot_data.php');
require_once($_SERVER['DOCUMENT_ROOT'].'/bench/phplot/phplot.php');
require_once($_SERVER['DOCUMENT_ROOT'].'/bench/phplot/phplot_data.php');
require_once($_SERVER['DOCUMENT_ROOT'].'/bench/phplot_log.php');

# 4. print HTML header
?>
<html>
<head>
    <link href="style.css" rel="stylesheet" type="text/css">
</head>
<body>
<p>new search - <a href="search.php">in steps</a> | <a href="search.php?stage=all">at once</a></p>
<?php

# 5. connect to the database
connect_to_mydb();
mysql_select_db('qadb');


# 6. clear old images from the image directory
$imgdir_rel = '/output';
$imgdir = $_SERVER['DOCUMENT_ROOT'].$imgdir_rel;
if( $handle = opendir($imgdir) )
{
	while (false !== ($file = readdir($handle))) {
		if( $file=='.' || $file=='..' ) continue;

		$stat = stat( "$imgdir/$file" );
		if( time()-$stat['atime'] > 600 )
			unlink( "$imgdir/$file" );
	}
	closedir( $handle );
}
else
	echo "Warning: cannot open the directory '$imgdir'<br>\n";


# 7. set up the main data

$from     = 'bench_parts p,bench_data d,tcf_group g,tcf_results tr,submissions s,testsuites t,products pr,releases r';
$where    = 'd.partID=p.partID AND d.resultsID=tr.resultsID AND tr.tcfID=g.tcfID AND s.submissionID=g.submissionID AND g.tcfNameID=t.testsuiteID AND pr.productID=s.productID AND r.releaseID=s.releaseID';
$where   .= ' AND d.resultsID IN ('.join(',',$tests).')';

# here are specified the control attributes
# for every tree level
$lev_attrs = array (

	# p.part without the first field
	# better do not ask how the SQL would look
	# if the last field should also be stripped
	/* 1 */ array("ltrim(substr(p.part,1+instr(p.part,';')))"),

	/* 0 */ $group_attrs,

	# p.part - first field only
	/* 2 */ array("substring_index(part,';',1)"),
	
	/* 3 */ array('d.result')
);  // TODO: should be one level deeper

# when filled, a special WHERE clause is used for the attribute
# sprintf syntax is used, value is passed to the sprintf() call
$lev_wheres = array (
	/* 1 */ array("p.part like '%%%s'"),
	/* 0 */ array(),
	/* 2 */ array("locate('%s;',p.part)=1"),
	/* 3 */ array()
);  // TODO: should be one level deeper

$separator=', ';

# colors for graph sequences
$colors=array( 'blue',
   'brown', 'cyan', 'red',  
   'purple', 'green', 
   'magenta', 'navy',
   'yellow', 'grey', 'pink', 'plum',
   'orange', 'orchid', 'wheat',
   'salmon', 'violet', 'gold'
   );

# 8. do the actual work
process_tree( 0, $where );

# 9. that's it!
?>
</body>
</html>
<?

return 0;
# and now - the functions !


# this function recursively processes the data
# and prints paragraphs / tables / graphs
# levels:
# 0 - prints paragraphs
# 1 - prints tables & graphs
# 2 - reads & returns X axis data
# 3 - reads & returns table cell data
// TODO: should be tree-processing instead of row-processing
function process_tree( $level, $where, $label='' )
{
	global $from, $lev_attrs, $separator, $group_by;
#	print date("H:i:s")."process_tree level=$level where=$where<br/>\n";
	assert( $level >=0 && $level<4 );

	# in level 1, prepare to print the table & graph
	if( $level==1 )
	{
		# labels, points, averages, dispersions, point counts
		$graph_data=array( array(), array(), array(), array(), array() );

		# X axis
		$x = process_tree( 2, $where );
		process_x_axis($x,$x_num);

		# print the table header
		print "<p><table border=\"1\" cellspacing=\"0\" style=\"empty-cells:show\">\n";
		$group = $group_by;
		$group = preg_replace('/\w+\./',' ',$group);
		print "\t<tr><th>$group</th>";
		foreach( $x as $xval )
			print '<th colspan="2">'.join($separator,$xval).'</th>';
		print "</tr>\n";
		$graph_data['graph']['x'] = $x;
		$graph_data['graph']['label'] = $label;
		$graph_data['graph']['xlabel'] = preg_replace('/=?\d+/','',join($separator,$x[0]));
		
		# try to get numbers from X values
#		$x_num = array();
#		for( $i=0; $i<count($x); $i++ )
#		{
#			$matches = array();
#			if( preg_match( '/\d+/', join($separator,$x[$i]), $matches ) )
#				$x_num[$i] = $matches[0];
#			else
#				$x_num[$i] = $i;
#		}
		$graph_data['graph']['x_num'] = $x_num;
	}

	# read the data from database
	$query = 'SELECT '.($level<3 ? 'DISTINCT ':'').join(',',$lev_attrs[$level])." FROM $from WHERE $where";
	$results = matrix_mysql_query($query,0);
	switch( $level )
	{
		case 2: return $results;
		case 3: return mkavg( $results );
	}

	# process the data in level 0 and 1
	for( $i=0; $i<count($results); $i++ )
	{
		$row = $results[$i];
		$value = join($separator, $row);

		$mywhere = append_where($where,$level,$row);

		# level 0 - print a paragraph headline
		if( $level==0 )
		{
			print "<h1>$value</h1>\n";
			process_tree( $level+1, $mywhere, $value );
			continue;
		}

		# level 1 - print the table row
		assert( $level==1 );
		$data = array();
		foreach( $x as $xval )
		{
			$mywhere2 = append_where($mywhere,2,$xval);
			array_push($data,process_tree(3,$mywhere2));
		}
		print_row( $value, $data );
		graph_line( $graph_data, $value, $i, $data );

	}

	# level 1 - finish table & display graph
	if( $level==1 )
	{
		print "</table></p>\n";
		graph_draw( $graph_data );
	}
}

function process_x_axis( &$x_db, &$x_num )
{
	global $separator;
	$x_num=array();
	$x_pairs = array();
	$stat_num = 0;
	$stat_nonum = 0;
	for( $i=0; $i<count($x_db); $i++ )
	{
		if( preg_match( '/\d+/', join($separator,$x_db[$i]), $matches) )
		{
			$stat_num++;
			$x_pairs[] = array($matches[0],$x_db[$i]);
		}
		else
		{
			$stat_nonum++;
			$x_pairs[] = array(null,$x_db[$i]);
		}
	}
	if( $stat_nonum==0 && $stat_num>0 )
	{
		usort( $x_pairs, create_function('$a,$b','return $a[0]>$b[0]?1:($a[0]==$b[0]?0:-1);') );
		$x_num=array_map(create_function('$a','return $a[0];'),$x_pairs);
		$x_db =array_map(create_function('$a','return $a[1];'),$x_pairs); 
	}
	else
	{
#		$x_num=array_map(create_function('$a','global $separator;return join($separator,$a);'),$x_db);
		$x_num=range(1,count($x_db));
		# $x_db untouched
	}
}

# gets cell data, counts average & deviation
# returns them as [ [ data ], [ average, deviation ] ]
function mkavg( $data )
{
	# use only the first column (TODO)
	$mydata = array_map(create_function('$a','return $a[0];'),$data);
	if( count($mydata)==0 )
		return array( array(), array() );

	$avg = array_sum($mydata) / count($mydata);
	$var = 0;
	foreach( $mydata as $val )
		$var += ($val-$avg)*($val-$avg);
	$var /= count($mydata);
	return array(
		$mydata,
		count($mydata)>1 ?
		array(
			$avg,
			sqrt($var)
		)
		: array( $avg )
		);
}

# updates the SQL WHERE clause
# $data are values related to that level
# see $lev_attrs and $lev_wheres for more info
function append_where( $where, $level, $data )
{
	global $lev_attrs, $lev_wheres;
	for( $i=0; $i<count($lev_attrs[$level]); $i++ )
	{
		if( isset($lev_wheres[$level][$i]) )
			$where .= ' AND '.sprintf( $lev_wheres[$level][$i], $data[$i]);
		else
			$where .= ' AND '.$lev_attrs[$level][$i]."='".$data[$i]."'";
	}
#	print "where[$level]=\"$where\"<br/>\n";
	return $where;
}

# prints one HTML table row with data, average & deviation
function print_row( $header, $data )
{
	# count SPAN
	$span=0;
	foreach( $data as $column )
		$span = max( $span, count($column[0]) );

	# process and print the data
	for( $i=0; $i<$span; $i++ )
	{
		print "\t<tr>";

		# left table header
		if( $i==0 )
			print "<th rowspan=\"$span\">$header</th>";
		
		# for each X value, print the numbers
		$decimals=0;
		foreach( $data as $column )
		{
			# precision of average/deviation
			# should be the same as those of numbers
			if( isset($column[0][$i]) )
			{
				# handle exponential notation,
				# convert to normal for numbers
				# around 1e+6
				$delta=0;
				if( preg_match('/[+-]?(\d+)(\.\d+)?[eE]([+-]\d+)/',$column[0][$i],$matches) )
				{
					$delta=$matches[3];
					if( $delta>0 && $delta<10 )
						$column[0][$i] = sprintf('%.0f', $column[0][$i]);
				}
				print '<td>'.$column[0][$i].'</td>';

				# finds decimal point/comma
				$point=strpos($column[0][$i],'.');
				if(!$point)
					$point=strpos($column[0][$i],',');
				if($point)
					$decimals=max($decimals, -$delta+strlen($column[0][$i])-$point-1);
			}
			else
				print '<td></td>';

			# format the average / deviation
			if( $i==0 )
				if( count( $column[1] ) > 1 )
					printf('<td rowspan="'.$span.'">%.'.$decimals.'f &plusmn; %.'.$decimals.'f</td>', $column[1][0], $column[1][1]);
				else
					print "<td rowspan=\"$span\"></td>";
		}
		print "</tr>\n";
	}
}

# adds graph data from one table row (i.e. one series)
# $line is array of results from mkavg, i.e 
# [ [ data ], [ average, deviation ] ] or
# [ [ data ], [ average ] ]  (when only 1 data) or
# [ [], [] ]
function graph_line( &$graph_data, $name, $num, $line )
{
	# $graph_data[0] contains X axis
	# $graph_data[1] contains averages
	# $graph_data[2] contains deviations
	# $graph_data[3] contains the results themselves
	# $graph_data['graph']['x_num'] is array of X values
	# $graph_data['graph']['y_num'] is array of Y values
	global $separator;
	for( $i=0; $i<count($graph_data['graph']['x']); $i++ )
	{
		$xval = $graph_data['graph']['x_num'][$i];

		# PHPlot wants following structure:
		# [ label, xval, yval1, yval2, ... ]
		# here we initialize it
		for( $j=1; $j<3; $j++ )
			if( !isset($graph_data[$j][$i]) )
				$graph_data[$j][$i]=array('',$xval);
		$graph_data[1][$i][$num+2]='';
		array_splice($graph_data[2][$i],3*$num+2,3,array('','',''));
		if( !isset( $line[$i] ) )
			continue;

		$col = $line[$i];
		

		# averages
		if( count($col[1]) > 0 )
			$graph_data[1][$i][$num+2] = $col[1][0];

		# deviations - see PHPlot documentation for format
		if( count($col[1]) > 1 )
			array_splice($graph_data[2][$i], 3*$num+2, 3, array( $col[1][0], $col[1][1], $col[1][1]));

		# result points
		# to simplify things, one [ lbl, x, y1, .. yn ]
		# for every point (i.e. only one of y1..yn set)
		foreach( $col[0] as $yval )
		{
			#$nr = count($graph_data[1][0])-2;
			$mydata = array( '', $xval );
			for( $j=0; $j<$num; $j++ )
				$mydata[] = '';
			$mydata[$num+2] = $yval;
			$graph_data[3][] = $mydata;
			$graph_data['graph']['y_num'][] = $yval;
		}

	}

	# X axis
	$graph_data[0][$num] = $name;
}

# draws the prepared graph
function graph_draw( $graph_data )
{
	global $colors, $imgdir, $imgdir_rel, $debug;

	$plot =& new PHPlot_log(800,600);
#	$plot->SetCallback('debug_scale','callback');

	# filename
	$graph_name = 'img'.uniqid().'.png';
	$plot->SetOutputFile($imgdir.'/'.$graph_name);

	# not to STDOUT
	$plot->SetPrintImage(0);
	$plot->SetIsInline(1);

	# colors, styles, title
	$plot->SetDataColors($colors);
	$plot->SetErrorBarColors($colors);
	$plot->SetLineStyles('solid');
#	$plot->SetYTitle('Benchmark results');
	$plot->SetTitle($graph_data['graph']['label']);
	$plot->SetXTitle($graph_data['graph']['xlabel']);
	$plot->SetErrorBarShape('tee');  # Is default
	$plot->SetErrorBarSize(10);
	$plot->SetErrorBarLineWidth(1);
	$plot->SetDrawXGrid(True);
	$plot->SetDrawYGrid(True);  # Is default

	# count statisctics, set up axes
	$x_stats = graph_stats( $graph_data['graph']['x_num'], 1 );
	$y_stats = graph_stats( $graph_data['graph']['y_num'], 0 );

#	print "<pre>x_stats=";
#	print_r($x_stats);
#	print "\ny_stats=";
#	print_r($y_stats);
#	print "\ncall=";
#	print_r(array($x_stats['amin'], $y_stats['amin'], $x_stats['amax'], $y_stats['amax']));
#	print "</pre>\n";
	if( $debug )
	{
		print "<!--\nx_stats :";
		print_r($x_stats);
		print "\ny_stats :";
		print_r($y_stats);
		print "\ngrahp_data :";
		print_r($graph_data);
		print "\n-->\n";
	}
	# sets scales, ticks, limits
	$plot->SetXScaleType( $x_stats['type'] );
	$plot->SetYScaleType( $y_stats['type'] );
	if( isset($x_stats['ticks']) )
		$plot->SetXTicks( $x_stats['ticks'] );
	if( isset($y_stats['ticks']) )
		$plot->SetYTicks( $y_stats['ticks'] );
	$plot->SetPlotAreaWorld($x_stats['amin'], $y_stats['amin'], $x_stats['amax'], $y_stats['amax']);
	$plot->SetXTickIncrement($x_stats['inc']);
	$plot->SetYTickIncrement($y_stats['inc']);

#	error_reporting(85);

	# Graph 1 - data:
	$plot->SetPlotType('points');
	$plot->SetDataType('data-data');
	$plot->SetDataValues($graph_data[3]);
	$plot->SetPointSizes(10);
	$plot->DrawGraph();

	# Graph 2 - deviations:
	$plot->SetPlotType('points');
	$plot->SetDataType('data-data-error');
	$plot->SetDataValues($graph_data[2]);
	$plot->SetPointSizes(1);
	$plot->DrawGraph();

	# have a legend in the last graph
	$plot->SetLegend($graph_data[0]);

	# Graph 3 - mean values:
	$plot->SetPlotType('lines');
	$plot->SetDataType( 'data-data' );
	$plot->SetDataValues($graph_data[1]);
	$plot->SetPointSizes(1);
	$plot->DrawGraph();

#	print "data=<pre>\n";
#	print_r( $graph_data[0] );
#	print_r( $colors2 );
#	print "\n</pre>\n";

	# write the file
	$plot->PrintImage();

	# print HTML tag
	print "<p><img src=\"$imgdir_rel/$graph_name\" alt=\"Graph\"></p>\n\n";
}

# counts graph data statistics, type, limits, and axis marks
function graph_stats( $data, $allow_log=true )
{
	$stats = array();
	if( count($data)==0 )
		return $stats;
	
	$stats['min'] = min($data);
	$stats['max'] = max($data);
	$stats['mid'] = ($stats['max']+$stats['min'])/2;

	# log type if >75% of data are in the 1st half
	$stats['half'] = 0;
	foreach( $data as $x )
		if( $x < $stats['mid'] )
			$stats['half']++;

	if(!$allow_log || $stats['half']<.75*count($data) || $stats['min'] <= 0)
	{
		# linear graphs
		$stats['type'] = 'linear';
		if( $stats['min']==$stats['max'] )
			$stats['max'] = ($stats['min']==0 ? 1 : 2*$stats['min']);
		$stats['magnitude'] = pow(10,ceil(log10($stats['max']-$stats['min'])));
		$stats['inc'] = $stats['magnitude'] / 10;
        
		if(!$stats['inc'])
			$stats['inc'] = pow(10,round(log10($stats['min']) ) );
		$stats['amin'] = $stats['inc'] * floor( $stats['min'] / $stats['inc'] );
		$stats['amax'] = $stats['inc'] * ceil( $stats['max'] / $stats['inc'] );
	}
	else
	{
		# logarithmic graphs
		$stats['type'] = 'log';
		
		# test if it is 2^n or 10^n
		$delta=.05;
		$l02=0;
		$l10=0;
		foreach( $data as $x )
		{
			if( ispower( $x, 2 ) || ispower( $x*2/3, 2 ) )
				$l02++;
			if( ispower( $x, 10 ) )
				$l10++;
		}
		$base = ($l02 > $l10) ? 2 : 10;

		# just for backward compatibility
		$stats['magnitude'] = ceil(log($stats['max']-$stats['min'],$base));
		$stats['inc'] = pow($base, $stats['magnitude'] - ($base==10 ? 1 : 3 ) );

		# count axis marks
		$lmin = floor( log($stats['min'], $base ) );
		$lmax = ceil ( log($stats['max'], $base ) );
		$stats['ticks'] = array();
		for( $x=$lmin; $x<=$lmax; $x++ )
		{
			$b0 = pow($base,$x);
			if( $base==10 )
				array_push( $stats['ticks'], $b0, 2*$b0, 5*$b0 );
#				array_push( $stats['ticks'], $b0, 2*$b0, 3*$b0, 4*$b0, 5*$b0, 6*$b0, 7*$b0, 8*$b0, 9*$b0 );
			else
				array_push( $stats['ticks'], $b0 );
		}

		# remove unnecessary decimal marks
		while(  count($stats['ticks'])>1 &&
			$stats['ticks'][0]<=$stats['min'] && 
			$stats['ticks'][1]<=$stats['min'] )
			array_shift($stats['ticks']);
		while(  count($stats['ticks'])>1 &&
			$stats['ticks'][count($stats['ticks'])-1]>=$stats['max'] &&
			$stats['ticks'][count($stats['ticks'])-2]>=$stats['max'] )
			array_pop($stats['ticks']);

		# minimum and maximum from the marks
		$stats['amin'] = $stats['ticks'][0];
		$stats['amax'] = $stats['ticks'][count($stats['ticks'])-1];
	}
	return $stats;
}

# tests if $x is near a power of $base
function ispower( $x, $base )
{
	$delta = .05;
	if( $x<=0 || $base<=0 )
		return false;
	return ( abs( $x - pow( $base, round( log( $x, $base ) ) ) ) < $delta );
}

# function to debug PHPlot
function callback($img, $what, $func, $data)
{
	print "Callback func=$func <pre>\n";
	print_r($data);
	print "</pre>\n";
}

?>
