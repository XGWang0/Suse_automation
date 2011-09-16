<?php

// vim :set ai si ts=4 et sw=4

//require_once('config.php');
//require_once('hrf/myconnect.inc.php');
require_once($_SERVER['DOCUMENT_ROOT'].'/hrf/html_func.php');
require_once($_SERVER['DOCUMENT_ROOT'].'/bench/functions.php');

$stage=1;
if( isset($_REQUEST['stage']) ) $stage=$_REQUEST['stage'];

$names = array( 'testsuiteName', 'dateFrom', 'dateTo', 'product', 'release', 'architecture', 'test_host' );
$stages = array( 1, 1, 1, 2, 3, 4, 5 );
$maxstage = 6;
$self='search.php';
$method='get';

?><!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
    "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html>
<head>
    <link href="/qa_db_frontend/style.css" rel="stylesheet" type="text/css">
<?php
if( $stage==1 )
{
?>
    <link rel="stylesheet" type="text/css" href="/bench/epoch/epoch_styles.css" />
    <script type="text/javascript" src="/bench/epoch/epoch_classes.js"></script>
    <script type="text/javascript">
    var from_cal, to_cal;
    window.onload = function() {
        from_cal = new Epoch('epoch_popup','popup',document.getElementById('dateFrom'));
        to_cal   = new Epoch('epoch_popup','popup',document.getElementById('dateTo'));
    };
    </script>
<?php
}
?>
</head>
<body>


<h1>Benchmark search tool</h1>
<?php
if( $stage=='all' || $stage==1 )
{
	print '<p><a href="'.$self.($stage==1 ? '?stage=all':'');
	print '">select '.($stage==1 ? 'at once': 'in steps');
	print "</a></p>\n";
}

if( $stage != 'all' && $stage>1 )
	print "<p><a href=\"$self\">new search</a></p>\n";

print	"<form action=\"".
	($stage==$maxstage ? 'benchmarks.php' : $self /*.'?stage='.(
		$stage=='all' ? $maxstage : $stage+1)*/).
	'" method="'.$method.'" name="benchForm">';

print "\n".'<input type="hidden" name="stage" value="'.($stage=='all' ? $maxstage : $stage+1).'"/>'."\n";

connect_to_mydb();
mysql_select_db('qadb');

// WHERE <- $where <- $wvals
$where   = array();

$hiddens = array();
$rnr     = 0;

// 1. process variables from previous stages
if( $stage!='all' && $stage>1 )
{
    print("<table>\n");
    print("\t".'<tr><th class="row_header">attribute</th><th class="row_header">values</th></tr>'."\n");
    for( $i=0; $i<count($names); $i++ )
    {
        if( $stage <= $stages[$i] )
            continue;

        // display the values
        printf("\t<tr class=\"".($rnr++ & 1 ? 'odd':'even')."row\"><td class=\"row_body\">%s</td><td class=\"row_body\">",$names[$i]);
        if( isset( $_REQUEST[$names[$i]] ))
        {
            $wvals = array();
            foreach( $_REQUEST[$names[$i]] as $val )
            {
                if( empty($val) ) continue;

                // display the value
                print $val.' ';
                array_push( $hiddens, '<input type="hidden" name="'.$names[$i].'[]" value="'.htmlspecialchars($val).'"/>'."\n" );

                // update the WHERE clause
                array_push( $wvals, "'".mysql_real_escape_string($val)."'" );
            }
            // update the WHERE clause
            if( count($wvals) )
                if( ! strncmp( $names[$i], 'date', 4 ) )
                    array_push( $where, ' s.submission_date'.(strstr($names[$i],'From') ? '>=' : '<=').$wvals[0] );
                else
                    array_push( $where, ' s.'.$names[$i].' IN ('.join(',', $wvals).')' );
        }
        // display the values
        print "</td></tr>\n";
    }
    print( "</table>\n" );
}

print join("\n", $hiddens);

// 2. process variables from current stage
if( $stage=='all' || $stage < $maxstage )
{
    for( $i=0; $i<count($names); $i++ )
    {
        if( $stage!='all' && $stage!=$stages[$i] )
            continue;

        // 2.1 print header
        print "\n<h3>".$names[$i]."</h3>\n";
        print '<span class="options">'."\n";


        if( ! strncmp( $names[$i], 'date', 4 ) )
            // 2.2 date fields
            print '<input type="text" id="'.$names[$i].'" name="'.$names[$i].'[]"/>'."\n";
        else
        {

            // 2.3 prepare a query for the values
            // quite complicated expression, but basically selects 
            // attribute name from all_submissions_view, 
            // plus number of related benchmark combinations
            // then formats for multiple_select()
            // can be 'COUNT( DISTINCT s.test_host,s.product,s.release)
            // and displays number of HW/SW combinations
            // or 'COUNT( DISTINCT s.tcfID)
            // and displays number of results
            $query = 'SELECT s.'.$names[$i].', COUNT(DISTINCT s.test_host,s.product,s.release), COUNT(DISTINCT s.tcfID) FROM all_submissions_view s, bench_data b WHERE s.resultsID=b.resultsID';

            // 2.4 update the WHERE clause
            if( count($where) )
                $query .= ' AND '.join(' AND ', $where);

            // 2.5 add an ORDER BY clause
            $query .= ' GROUP BY s.'.$names[$i].' ORDER BY s.'.$names[$i];

            // 2.6 query
//            echo $query."<br/>\n";
            $data = matrix_mysql_query($query,0);
            $data = array_map( create_function('$a','return array($a[0],sprintf("(%s/%s)\t%s",$a[1],$a[2],$a[0]));'), $data );

            // 2.7 display the results
            multiple_select($names[$i],$data,'');
        }
        print "</span>\n";
    }
}

// 3. in the last form, select individual submission IDs
if( $stage == $maxstage )
{
    $query = 'SELECT DISTINCT s.submissionID, b.resultsID, s.test_host, s.architecture, s.submission_date, s.testsuiteName, s.product, s.release, s.tester, s.comment FROM all_submissions_view s, bench_data b WHERE s.resultsID=b.resultsID';
    if( count($where) )
        $query .= ' AND '.join(' AND ', $where);
//    echo $query."<br/>\n";
    ($res = mysql_query( $query )) || die(mysql_error());
    $num = mysql_num_fields( $res );

// 3.1 a script to change all the checkboxes at once
?>
<p>
<script language="JavaScript" type="text/javascript">
<!-- 
function ToggleChecked(a) {
  for (var i = 0; i < document.benchForm.elements.length; i++) {
    if(document.benchForm.elements[i].type == 'checkbox'){
      document.benchForm.elements[i].checked = !(document.benchForm.elements[i].checked);
    }
  }
  a.checked = !(a.checked);
}
//-->
</script>
<table class="dbdata">
    <tr><th class="row_header"><input type="checkbox" checked="1" onclick="ToggleChecked(this);"></th><?php

// 3.2 table of found tcfIDs
    for( $i=0; $i<$num; $i++ )
        echo '<th class="row_header">'.mysql_field_name( $res, $i ).'</th>';
    echo "</tr>\n";
    
    $rnr = 0;
    while( $row = mysql_fetch_array($res) )
    {
        echo "\t".'<tr class="'.($rnr++ &1 ? 'odd':'even').'row">';
        echo '<td class="row_body"><input type="checkbox" checked="1" name="tests[]" value="'.$row['resultsID'].'"></td>';
        for( $i=0; $i<$num; $i++ )
            echo '<td class="row_body">'.$row[$i].'</td>';
        echo "</tr>\n";
    }

// 3.3 grouping options
?>
</table>
</p>

<?php
    if( $rnr==0 )
            echo '<p><font color="red">No data found, please do a new search</font></p>'."\n";
?>


<h3>Group results by</h3>
<p>
<select name="group_by">
    <option value="t.testsuiteName,s.test_host,pr.product,r.release">testsuiteName, test_host, product, release</option>
    <option value="t.testsuiteName,s.test_host,pr.product">testsuiteName, test_host, product</option>
    <option value="t.testsuiteName,s.test_host">testsuiteName, test_host</option>
    <option value="t.testsuiteName,s.submissionID">testsuiteName,submissionID</option>
    <option value="g.tcfID">tcfID</option>
</select>
</p>
<?php
    
}


?>
<span class="options">
    <input type="submit"/>
</span>
</form>
</body>
</html>

