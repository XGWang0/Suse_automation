<?php
require_once("qadb.php");
$pager1=$pager2=$pager3=array();
pager_fill_from_http($pager1,'p1_');
pager_fill_from_http($pager2,'p2_');
pager_fill_from_http($pager3,'p3_');

common_header(array('title'=>'regression tool'));
$ref_submission_id=$ref_submission_id_got=http('ref_submission_id',http('oldsubmission_id'));
$cand_submission_id=$cand_submission_id_got=http('cand_submission_id',http('newsubmission_id'));
$ref_tcf_id=http('ref_tcf_id');
$cand_tcf_id=http('cand_tcf_id');

$what1 = array(
	array('ref_submission_id' ,'',$ref_submission_id, TEXT_ROW,'Reference (old) submission ID'),
	array('cand_submission_id','',$cand_submission_id,TEXT_ROW,'Candidate (new) submission ID')
);
$what2 = array(
	array('ref_tcf_id' ,'',$ref_tcf_id, TEXT_ROW,'Reference (old) tcf_id'),
	array('cand_tcf_id','',$cand_tcf_id,TEXT_ROW,'Candidate (new) tcf_id')
);

function field($name,$value)
{	
	$set = is_numeric($value) || !empty($value);
	$cls = ($set ? 'set' : 'notset');
	printf('<input class="%s" id="%s" type="text" name="%s"%s/>', $cls, $name, $name ,$set ? ' value="'.$value.'"':'') ;
}

?>
<form action="regression.php" method="get">
<table class="screen">
  <tbody>
    <tr>
      <td>Reference Submission ID</td>
      <td><?php field('ref_submission_id',$ref_submission_id); ?></td>
      <td rowspan="2" width="50">OR</td>
      <td>Reference tcf_id</td>
      <td><?php field('ref_tcf_id',$ref_tcf_id); ?></td>
      <td></td>
    </tr>
    <tr>
      <td>Candidate Submission ID</td>
      <td><input type="text" name="cand_submission_id"<?php if($cand_submission_id) print " value=\"$cand_submission_id\"";?>/></td>
      <td>Candidate tcf_id</td>
      <td><?php field('cand_tcf_id',$cand_tcf_id); ?></td>
      <td><input type="submit" /></td>
    </tr>
  </tbody>
</table>
</form>
<hr/>
<?php

# combining reference/candidate states
# i - internal error + timeout, s - success, f - fail, S - skipped
$state_table=array(
	'i' => array( 's'=>'wi', 'f'=>'wr', 'S'=>'wi' ),
	's' => array( 'i'=>'wr', 'f'=>'r', 'S'=>'m' ),
	'f' => array( 'i'=>'wr', 's'=>'i', 'S'=>'wi' ),
	'S' => array( 'i'=>'wr', 's'=>'wi',  'f'=>'wr' )
);

# description of resulting status
$status_names=array(
	'wi'=>'weak improvement',
	'wr'=>'weak regression',
	'r'=>'regression',
	'i'=>'improvement',
	'm'=>'missing'
);

# weakening table
$weaker=array('i'=>'wi','wi'=>'wi','r'=>'wr','wr'=>'wr','m'=>'m');

function colorize()
{
	$row=func_get_args();
	return ' '.$row[13];
}

# HTTP args to preserve while paging
$what = array (
	array('ref_submission_id','',$ref_submission_id),
	array('cand_submission_id','',$cand_submission_id),
	array('ref_tcf_id','',$ref_tcf_id),
	array('cand_tcf_id','',$cand_tcf_id),
	array('p1_page','',http('p1_page')),
	array('p2_page','',http('p2_page')),
	array('p3_page','',http('p3_page'))
);

# From HTTP args to preserve, filter out each pager's own value
function pager_args($omit)
{
	global $what;
	$w=$what;
	for($i=0; $i<count($what); $i++)
		if( $w[$i][0] == $omit )	{
			array_splice($w,$i,1);
			break;
		}
	return $w;
}

# set HTTP values to preserve while paging
$pager1['what'] = pager_args('p1_page');
$pager2['what'] = pager_args('p2_page');
$pager3['what'] = pager_args('p3_page');
	

# if no submission_ids entered, count them from tcf_ids
if( $ref_tcf_id && !$ref_submission_id )
	$ref_submission_id = tcf_get_submission($ref_tcf_id);
if( $cand_tcf_id && !$cand_submission_id )
	$cand_submission_id = tcf_get_submission($cand_tcf_id);

# lookup submissions and print their details
if( $ref_submission_id>0 && $cand_submission_id>0 )
{
	echo "<h3>ref  (old) subm $ref_submission_id</h3>\n";
	$sub_r=&print_submission_details($ref_submission_id);
	echo "<h3>cand (new) subm $cand_submission_id</h3>\n";
	$sub_c=&print_submission_details($cand_submission_id);
}

# when all inputs present, do the comparison
if( isset($sub_r[1]) && isset($sub_c[1]) )
{
	echo "<h3>Improvements and regressions</h3>\n";

	# fetch preprocessed data
	$data = regression_differences(array(
		'cand_submission_id'	=> $cand_submission_id_got,
		'ref_submission_id'	=> $ref_submission_id_got,
		'cand_tcf_id'		=> $cand_tcf_id,
		'ref_tcf_id'		=> $ref_tcf_id,
	),$pager1);

	# rewrite table header received from DB
	$internal=array('testcase_id','r_state','c_state','waiver_id');
	$data[0]['r_testsuites']='ref<br/>suite(s)';
	$data[0]['r_succ']='ref<br/>succ';
	$data[0]['r_fail']='ref<br/>fail';
	$data[0]['r_interr']='ref<br/>interr';
	$data[0]['r_skip']='ref<br/>skipped';
	$data[0]['c_testsuites']='cand<br/>suite(s)';
	$data[0]['c_succ']='cand<br/>succ';
	$data[0]['c_fail']='cand<br/>fail';
	$data[0]['c_interr']='cand<br/>interr';
	$data[0]['c_skip']='cand<br/>skipped';
	$data[0]['status']='status';
	$data[0]['waiver']='waiver';
	foreach($internal as $int)
		unset($data[0][$int]);

	# according to waiver, we put the rows in either of these
	$out = $out2 = array($data[0]);

	# modify rows
	for($i=1; $i<count($data); $i++)
	{
		# status
		$row=$data[$i];
		$tc_id=$row['testcase_id'];
		$match=$state_table[$row['r_state']][$row['c_state']];
		$info=$status_names[$match];

		# waiver
		$waiver='';
		$wr=$wc=$hide=0;
		$waiver_id=$row['waiver_id'];
		if( $waiver_id )	{
			# waiver exists
			$wr=waiver_exact($waiver_id,$sub_r);
			$wc=waiver_exact($waiver_id,$sub_c);

			# hide testcases known to be broken
			if( $wc=='problem' || ($wc=='no problem' && $wr=='problem') )
				$hide=1;

			# button to view/edit waiver details
			$waiver=html_text_button("show","waiver.php?view=view_waiver&waiver_id=$waiver_id");
			
			# display mode, weaken the status
			$info .= ', waiver';
			if (!( $wc=='no problem' && $wr=='no problem' ))
				$match=$weaker[$match];
			$match .= ' w';
		} else {
			# waiver does not exist - button
			$waiver=html_text_button("create","waiver.php?view=new_both&testcase=$tc_id&arch=".$sub_c[1]['arch_id'].'&products='.$sub_c[1]['product_id'].'&releases='.$sub_c[1]['release_id']);
		}

		# write results, hide internal columns
		$row['status']=$info;
		$row['waiver']=$waiver;
		$row['match'] =$match;
		foreach($internal as $int)
			unset($row[$int]);

		# add the row either into the comparsion, or into the list of skipped
		if( $hide )
			$out2[]=$row;
		else
			$out[]=$row;

	}

	# print regression table
	print html_table($out,array('callback'=>'colorize','id'=>'regressions','sort'=>'ssiiiisiiiiss','pager'=>$pager1,'total'=>1));

	# print testcases hidden by waiver
	if( count($out2)>1 )
	{
		print "<h3>Skipped waiver testcases</h3>\n";
		print html_table($out2,array('callback'=>'colorize','id'=>'w_regressions','sort'=>'ssiiiisiiiiss'));
	}

	# candicate-only testcases
	$transl=array();
	$candonly=search_submissions_result(0,array('submission_id'=>$cand_submission_id_got,'tcf_id'=>$cand_tcf_id,'res_minus_sub'=>$ref_submission_id_got,'res_minus_tcf'=>$ref_tcf_id),$transl,$pager2);
	if( count($candonly)>1 )	{
		print "<h3>Testcases only in candidate</h3>\n";
		result_process_print($candonly,$sub_c,$transl,$pager2,'res_candonly');
	}

	# reference-only testcases
	$transl=array();
	$refonly=search_submissions_result(0,array('submission_id'=>$ref_submission_id_got,'tcf_id'=>$ref_tcf_id,'res_minus_sub'=>$cand_submission_id_got,'res_minus_tcf'=>$cand_tcf_id),$transl,$pager3);
	if( count($refonly)>1 )	{
		print "<h3>Testcases only in reference</h3>\n";
		result_process_print($refonly,$sub_r,$transl,$pager3,'res_refonly');
	}

}
print html_footer();
?>
