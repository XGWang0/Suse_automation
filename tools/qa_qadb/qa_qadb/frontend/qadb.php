<?php

/**
  * QADB - related functions
  * @package QADB
  * @filesource
  * @license http://opensource.org/licenses/gpl-2.0.php GNU General Public License
  **/

/** library functions - common DB and HTML functions */
require_once('../tblib/tblib.php');

$enums = array(
	'arch'			=> array('arch_id','arch'),
	'product'		=> array('product_id','product'),
	'release'		=> array('release_id','release'),
	'kernel_branch'		=> array('kernel_branch_id','kernel_branch'),
	'kernel_flavor'		=> array('kernel_flavor_id','kernel_flavor'),
	'kernel_version'	=> array('kernel_version_id','kernel_version'),
	'testsuite'		=> array('testsuite_id','testsuite'),
	'testcase'		=> array('testcase_id','testcase'),
	'bench_part'		=> array('bench_part_id','bench_part'),
	'rpm_basename'		=> array('rpm_basename_id','rpm_basename'),
	'rpm_version'		=> array('rpm_version_id','rpm_version'),
	'rpm_config'		=> array('rpm_config_id','md5sum'),
	'host'			=> array('host_id','host'),
	'status'		=> array('status_id','status'),
	'tester'		=> array('tester_id','tester'),
	);


###############################################################################
# Misc utils

/** 
  * Tests if the given $waiver_id applies to a given submission's arch/product/release.
  * @see print_submission_details()
  * @param array $s output of print_submission_detais()
  * @return int 0 for no waiver, 1 for partial match (testcase only), 2 for full match
  **/
function waiver_exact($waiver_id,$s)
{
	return scalar_query('SELECT matchtype FROM waiver_testcase WHERE waiver_id=? AND product_id=? AND release_id=? AND (arch_id=? OR arch_id IS NULL) ORDER BY arch_id DESC LIMIT 1','iiii',$waiver_id,$s[1]['product_id'],$s[1]['release_id'],$s[1]['arch_id']);
/*
	1: exact match pozitivni na cand nebo ref -> o tomhle se vi
	2: exact match negativni na oba 

(red)	1: (testcase,product,release,arch match) & matchtype==1 -> regrese
(green)	2: (testcase,product,release,arch match) & matchtype==0 -> o tomhle se vi
	else
(yellow)3: (testcase match) -> mozna regrese, mozna ne - urcite vypsat, ale barevne odlisit od 100% nich regresi
	else
(red)	4: -> regrese

	pripad 2,3 - ma byt odkaz do waiver, u 1 mozna take
	moznost pridat aktualni testcase do waiveru (aspon u 3), moznost editovat/mazat stavaijci
	moznost pridat testcase do waiveru i bez regrese
*/
}

/** gets testcase_id, returns waiver_id or null */
function waiver_get_id($testcase_id)
{	return scalar_query('SELECT waiver_id FROM waiver WHERE testcase_id=?','i',$testcase_id);	}

/** Gets waiver_testcase_id, returns waiver_id */
function waiver_get_master($waiver_testcase_id)
{	return scalar_query('SELECT waiver_id FROM waiver_testcase WHERE waiver_testcase_id=?','i',$waiver_testcase_id);	}

/** creates a new waiver master record in waiver table */
function waiver_new($testcase_id=null,$bug_id=null,$explanation='')
{	return insert_query('INSERT INTO waiver(testcase_id,bug_id,explanation) VALUES(?,?,?)','iis',$testcase_id,$bug_id,$explanation);	}

/** creates a new detail in waiver_testcase table */
function waiver_new_detail($waiver_id, $product_id, $release_id, $arch_id, $matchtype)
{	return insert_query('INSERT INTO waiver_testcase(waiver_id,product_id,release_id,arch_id,matchtype) VALUES(?,?,?,?,?)','iiiis',$waiver_id,$product_id,$release_id,$arch_id,$matchtype);	}

/** deletes a waiver */
function waiver_delete($waiver_id)
{	return update_query('DELETE FROM waiver WHERE waiver_id=?','i',$waiver_id);	}

/** deletes a waiver detail */
function waiver_delete_detail($waiver_testcase_id)
{	return update_query('DELETE FROM waiver_testcase WHERE waiver_testcase_id=?','i',$waiver_testcase_id);	}

/** updates an existing waiver master record */
function waiver_update($waiver_id, $testcase_id, $bug_id, $explanation)
{	return update_query('UPDATE waiver SET testcase_id=?,bug_id=?,explanation=? WHERE waiver_id=?','iisi',$testcase_id,$bug_id,$explanation,$waiver_id);	}

/** updates an existing waiver_testcase record */
function waiver_update_detail($waiver_testcase_id, $product_id, $release_id, $arch_id, $matchtype)
{	return update_query('UPDATE waiver_testcase SET product_id=?,release_id=?,arch_id=?,matchtype=? WHERE waiver_testcase_id=?','iiisi',$product_id,$release_id,$arch_id,$matchtype,$waiver_testcase_id);	}


/**
  * Searches waiver tables.
  * $mode: 
  *   0 waiver
  *   1 waiver + waiver_testcase
  *   2 waiver_testcase only
  * $attrs['only_id']: 
  *   0 for full details
  *   1 for IDs only 
  * $attrs['order_nr']: +/- (1+<index of the result column>)
  *   positive nr. means ascending order, negative means descending.
  *
  * NOTE: see search_submission_result for similar code & more comments
  * @return array 2D array of result
  **/
function search_waiver($mode,$attrs)
{
	# supported arguments
	$attrs_known=array(
		'waiver_id'=> array('d.waiver_id=?','i'),
		'waiver_testcase_id'=>array('t.waiver_testcase_id=?','i'),
		'bug_id'=>array('d.bug_id=?','i'),
		'explanation'=>array('d.explanation like ?','s'),
		'product_id'=>array('t.product_id=?','i'),
		'release_id'=>array('t.release_id=?','i'),
		'testcase_id'=>array('d.testcase_id=?','i'),
		'arch_id'=>array('t.arch_id=?','i'),
		'matchtype'=>array('t.matchtype=?','i')
	);
	$only_id=hash_get($attrs,'only_id',false,true);
	# $sel0[ $mode ] - base attribute
	$sel0=array( 'd.waiver_id', 't.waiver_testcase_id', 't.waiver_testcase_id' );
	# $sel1[ $mode ] - additional attributes for (!$only_id)
	$sel1=array(
		array('d.testcase_id','d.bug_id','d.explanation'),
		array('d.testcase_id','d.waiver_id','t.product_id','t.release_id','t.arch_id','t.matchtype'),
		array('t.product_id','t.release_id','t.arch_id','t.matchtype')
	);
	# $from0[ $mode ] - tables to select from
	$from0=array('waiver d','waiver d JOIN waiver_testcase t USING(waiver_id)');
	$from0[2]=$from0[1];
	$sel=$sel0[$mode];
	if( !$only_id )
		$sel=array_merge( array($sel), $sel1[$mode] );
	return search_common( $sel, $from0[$mode], $attrs, $attrs_known );
}


/*
rommel@suse.de, kgw@suse.de

GUI:
1. regressions (waiver colors, can create waiver)
2. waiver list
3. waiver details list (can add/delete/edit details)
4. edit waiver (bug ID, explanation)
5. new waiver detail
6. edit waiver detail
7. waiver search form (searches after: testcase) ->3
*/

###############################################################################
# API for test search & benchmark data

/** Gets one row from bench_data. */
function get_bench_number($result_id,$bench_part_id)
{	return scalar_query('SELECT `result` FROM bench_data WHERE result_id=? AND bench_part_id=?','ii',$result_id,$bench_part_id);	}

/** Gets keys and bench numbers for a given result_id */
function get_bench_numbers($result_id,$limit=null)
{	return matrix_query(0,$limit,'SELECT bench_part_id,`result` FROM bench_data WHERE result_id=?','i',$result_id);	}

/** Lists all testsuite that contain benchmark data. Uses the statistical table 'test'. */
function bench_list_testsuite($limit=null)
{	return matrix_query(0,$limit,'SELECT DISTINCT testsuite_id,testsuite FROM test JOIN testsuite USING(testsuite_id) WHERE is_bench ORDER BY testsuite');	}
###############################################################################
# API for promote data
function list_promoted($limit=null)
{
       return matrix_query(0,$limit,'SELECT build_promoted_id,arch.arch,build_nr,product.product,release.release FROM build_promoted JOIN arch USING(arch_id) JOIN product USING(product_id) JOIN `release` USING(release_id) ORDER BY build_promoted_id');
}

function insert_update_promoted($arch_id,$product_id,$build_nr,$release_id)
{
        $insert=insert_query('INSERT INTO build_promoted (arch_id,build_nr,product_id,release_id) VALUES (?,?,?,?)','iiii',$arch_id ,$build_nr,$product_id,$release_id);
        $update=update_query('UPDATE submission SET release_id = ? WHERE arch_id=? AND build_nr=? AND product_id=?','iiii',$release_id,$arch_id,$build_nr,$product_id);
	return array ($insert,$update);

}

/** searches for submission, testsuite, or result
  * $mode :
  *   0 result
  *   1 just submission
  *   2 maintenance
  *   3 KOTD
  *   4 product
  *   5 any
  *   6 testsuite
  *   7 trend graphs
  *   8 submission + TCF
  *   9 bench search
  *  10 submission + TCF + testcase
  *  11 extended regressions, both testsuite and testcase
  *  12 extended regressions, just testsuites
  * $attrs['only_id']: 
  *   0 for full details
  *   1 for IDs only 
  * $attrs['order_nr']: +/- (1+<index of the result column>):
  *   positive nr. means ascending order, negative means descending
  *
  * Other $attrs keyvals are search criteria and their values (single or arrays). 
  *   See $attrs_known below for available search criteria.
  * $transl - if you put an empty array here, it would get filled with arguments
  *   suitable for calling table_translate() (enums and links only).
  **/
function search_submission_result($mode, $attrs, &$transl=null, &$pager=null)
{
	# base SQL for reference searches
	$rs1='EXISTS( SELECT * FROM reference_host rh WHERE s.host_id=rh.host_id AND s.arch_id=rh.arch_id AND s.product_id=rh.product_id )';
	# base SQL for result difference
	$rd1='NOT EXISTS( SELECT * FROM result r2 JOIN tcf_group g2 USING(tcf_id) WHERE';
	$rd2='AND r.testcase_id=r2.testcase_id)';
	# supported arguments
	$attrs_known=array(
		'date_from'	=> array('s.submission_date>=?',	's'),
		'date_to'	=> array('s.submission_date<=?',	's'),
		'host_id'	=> array('s.host_id=?',			'i'),
		'tester_id'	=> array('s.tester_id=?',		'i'),
		'arch_id'	=> array('s.arch_id=?',			'i'),
		'product_id'	=> array('s.product_id=?',		'i'),
		'release_id'	=> array('s.release_id=?',		'i'),
		'testsuite_id'	=> array('g.testsuite_id=?',		'i'),
		'testcase_id'	=> array('r.testcase_id=?',		'i'),
		'testcase'	=> array('c.testcase like ?',	's'),
		'tcf_id'	=> array('r.tcf_id=?',			'i'),
		'submission_id'	=> array('s.submission_id=?',		'i'),
		'rpm_config_id'	=> array('s.rpm_config_id=?',		'i'),
		'hwinfo_id'	=> array('s.hwinfo_id=?',		'i'),
		'comment'	=> array('s.comment like ?',		's'),
		'status_id'	=> array('s.status_id=?',		'i'),
		'md5sum'	=> array('s.md5sum=?',			's'),
		'patch_id'	=> array('s.patch_id=?',		's'),
		'type'		=> array('s.type=?',			's'),
		'kernel_version'=> array('s.kernel_version_id=?',	'i'),
		'kernel_branch'	=> array('s.kernel_branch_id=?',	'i'),
		'kernel_flavor'	=> array('s.kernel_flavor_id=?',	'i'),
		'ref'		=> array("s.ref!=''",			   ),
		'refhost'	=> array( $rs1				   ),
		# testcase differences - only for result search
		'res_minus_sub'	=> array("$rd1 g2.submission_id=? $rd2",'i'),
		'res_minus_tcf'	=> array("$rd1 g2.tcf_id=? $rd2",	'i'),
	);

	# index into $sel0[], $sel1[] (SELECT ...), and $from0[] (FROM ...)
	$i_main = array( 1,0,0,0,0,0,2,0,0,0,0,3,3 );
	# index into $sel2[] (SELECT ...)
	$i_next = array( 0,0,1,2,0,3,0,4,5,5,6,7,8 );
	# index into $from2[] (FROM ...)
	$i_from = array( 0,0,1,2,3,4,0,0,5,6,7,8,8 );
	# index into $links2[] ( $transl->['links'] )
	$i_link = array( 0,0,0,1,0,0,0,0,2,2,2,0,0 );

	# should I return submission_id only?
	$only_id  = hash_get($attrs,'only_id',false,true);

	# skip the header?
	$header = hash_get($attrs,'header',true,false);

	# SELECT $sel FROM $from
	# $sel = $sel0 [ $sel1 ] [ $sel2 ]
	# $from = $from0 $from2
	# $sel0..$sel2 are done as lists - for ordering by them
	# $sel0[ $i_main ] -- always
	$sel0=array( 's.submission_id', 'r.result_id', 'g.testsuite_id','SUM(r.times_run) as runs' );
	# $sel1[ $i_main ] -- appends for full details
	$sel1=array( 
/* subms */  array('s.submission_date','s.host_id','s.tester_id','s.arch_id','s.product_id','s.release_id','s.related','s.status_id','s.comment','s.rpm_config_id','s.hwinfo_id','s.type','s.ref'),
/* rslts */  array('g.tcf_id','g.testsuite_id','r.testcase_id','t.testcase','r.succeeded','r.failed','r.internal_error','r.skipped','r.times_run','r.test_time','w.waiver_id','t.relative_url','b.is_bench'),
/* suite */  array(),
/* regs  */  array('s.product_id','s.release_id','SUM(r.succeeded) as succ','SUM(r.failed) as fail','SUM(r.internal_error) as interr','SUM(r.skipped) as skip','SUM(r.test_time) as time')
	);
	# $sel2[ $i_next ] -- appends for full details
	$sel2=array( 
/* simple */ array(),
/* mtnce  */ array('s.patch_id','s.md5sum'),
/* KOTD   */ array('s.md5sum','s.kernel_version_id','s.kernel_branch_id','s.kernel_flavor_id'),
/* any    */ array('s.patch_id','s.md5sum'),
/* trend  */ array('g.testsuite_id'),
/* TCF    */ array('g.testsuite_id','g.tcf_id'),
/* TCF+res*/ array('g.testsuite_id','g.tcf_id','r.testcase_id'),
/* regs	  */ array('testsuite','testcase'),
/* regs-  */ array('testsuite'),
	);

	# $from0[ $i_main ] -- always
	$from0=array( 'submission s', 'submission s JOIN tcf_group g USING(submission_id) JOIN result r USING(tcf_id)', 'submission s JOIN tcf_group g USING(submission_id)', 'submission s' );
	# $from1[ $i_main ] -- append for full details
	$from1=array( '', ' JOIN testcase t USING(testcase_id) LEFT OUTER JOIN waiver w USING(testcase_id) JOIN test b USING(testcase_id)', '', '' );
	# $from2[ $i_from ] -- always
	$from2=array(
/* simple */	'',
/* mtnce  */	'',
/* KOTD   */	'',
/* prod   */	'',
/* any    */	'',
/* TCF    */    ' JOIN tcf_group g USING(submission_id)',
/* bench  */	' JOIN tcf_group g USING(submission_id) JOIN bench_suite b USING(testsuite_id)',
/* TCF+res*/	' JOIN tcf_group g USING(submission_id) JOIN `result` r USING(tcf_id) JOIN testcase c USING(testcase_id)',
/* regres */	' JOIN tcf_group g USING(submission_id) JOIN result r USING(tcf_id) JOIN testcase USING(testcase_id) JOIN testsuite USING(testsuite_id)', # testsuite/testcase joined to sort properly
	);
	
	# $enum1[ $i_main ] - for full details when $transl set
	$enum1=array(
/* subms */  array('host_id'=>'host','tester_id'=>'tester','arch_id'=>'arch','product_id'=>'product','release_id'=>'release','status_id'=>'status'),
/* rslts */  array('testsuite_id'=>'testsuite'),
/* suite */  array(),
/* regs  */  array(),
	);

	# $enum1[ $i_next ] - for full details when $transl set
	$enum2=array(
/* simple */	array(),
/* mtnce  */	array(),
/* KOTD   */	array('kernel_branch_id'=>'kernel_branch','kernel_flavor_id'=>'kernel_flavor','kernel_version_id'=>'kernel_version'),
/* prod   */	array(),
/* any    */	array(),
/* TCF    */	array('testsuite_id'=>'testsuite'),
/* bench  */	array('testsuite_id'=>'testsuite'),
/* regs   */	array(),
/* regs+  */	array(),
	);

	# $links1[ $i_main ] - for full details when $transl set
	$links1=array(
/* subms */	array('submission_id'=>'submission.php?submission_id=','related'=>'submission.php?submission_id=','rpm_config_id'=>'rpms.php?rpm_config_id=','hwinfo_id'=>'hwinfo.php?hwinfo_id='),
/* rslts */	array('tcf_id'=>'result.php?tcf_id='),
/* suite */	array(),
/* regs  */	array(),
	);

	# $links2[ $i_link ] - for full details when $transl set
	$links2=array(	
		array(),
/* KOTD */	array('md5sum'=>'http://kerncvs.suse.de/gitweb/?p=kernel-source.git;a=commit;h='), 
/* TCF data */	array('tcf_id'=>'result.php?tcf_id=') 
	);
	
	# make the SQL base SELECT
	$sel=array($sel0[$i_main[$mode]]);
	if( !$only_id )
		$sel=array_merge($sel, $sel1[$i_main[$mode]], $sel2[$i_next[$mode]]);
	$from=$from0[$i_main[$mode]].($only_id ? '' : $from1[$i_main[$mode]]).$from2[$i_from[$mode]];

	# prepare translation array
	if( isset($transl) && !$only_id )
	{
		$transl=array();
		$transl['enums'] = array_merge($enum1[ $i_main[$mode]], $enum2[ $i_next[$mode]]);
		$transl['links'] = array_merge($links1[$i_main[$mode]], $links2[$i_link[$mode]]);
	}
	# TODO: redesign following code
	if( !isset($attrs['type']) )	{
		$type = array(2=>'maint',3=>'kotd',4=>'prod'/*,5=>array('maint','kotd')*/);
		if( isset($type[$mode]) )
			$attrs['type']=$type[$mode];
	}
	$data=search_common( $sel, $from, $attrs, $attrs_known, $pager );
	if( $mode==2 ) # maintenance - append RPM lists
		$data=append_maintenance($data,$header);
	return $data;
}

function get_maintenance_rpms($submission_id)
{
	$data=matrix_query(0,null,"SELECT b.rpm_basename,v.rpm_version FROM released_rpm r JOIN rpm_basename b ON (r.rpm_basename_id=b.rpm_basename_id) LEFT OUTER JOIN rpm_version v ON (r.rpm_version_id=v.rpm_version_id) WHERE r.submission_id=?",'i',$submission_id);
	$ret=array();
	foreach( $data as $row )
		$ret[]=$row[0].(is_null($row[1]) ? '':'-'.$row[1]);
	return join(', ',$ret);
}

function append_maintenance( $data, $header )
{
	if($header)
		$data[0]['rpms']='RPMS included in this update';
	for( $i=($header ? 1:0); $i<count($data); $i++ )
		$data[$i]['rpms'] = get_maintenance_rpms($data[$i]['submission_id']);
	return $data;
}

function result_stats($submission_id,$testcase_id)
{
	return row_query(null,'SELECT count(*),sum(succeeded),sum(failed),sum(internal_error),sum(skipped) FROM result r,tcf_group g WHERE r.tcf_id=g.tcf_id AND g.submission_id=? AND r.testcase_id=?','ii',$submission_id,$testcase_id);
}

function regression_differences($attrs,&$pager=null)
{
	# This is ugly, but comparing submission of 100k testcase was no longer possible in PHP
	# What happens here: 
	# we link candidate and reference data using testcase_id
	# on-the-fly we compute status succ(s), fail(f), interr(i) or skipped(S) for both
	# we filter out testcase with the same status
	#
	# As the status is auto-generated, MySQL seems only able to filter it in an outside SELECT
	# We use search_common() to select proper data and generate SQL
	# then we add the outer SELECT with filtering out testcase with the same status
	
	# ugly hack: the first two columns are separated so that we can order by index 2, the others not
	$sel=array("c.testcase_id","testcase",
		"GROUP_CONCAT(CASE WHEN tr.log_url IS NULL THEN sr.testsuite ELSE CONCAT('<a href=\"',tr.log_url,'/',relative_url,'\">',sr.testsuite,'</a>') END) AS r_testsuite, 
			SUM(r.succeeded) AS r_succ, 
			SUM(r.failed) AS r_fail, 
			SUM(r.internal_error) AS r_interr, 
			SUM(r.skipped) AS r_skip, 
			(CASE WHEN r.failed>0 THEN 'f' WHEN r.internal_error>0 THEN 'i' WHEN r.skipped>0 THEN 'S' WHEN r.succeeded>0 THEN 's' ELSE 'i' END) AS r_state,
		 GROUP_CONCAT(CASE WHEN tc.log_url IS NULL THEN sc.testsuite ELSE CONCAT('<a href=\"',tc.log_url,'/',relative_url,'\">',sc.testsuite,'</a>') END) AS c_testsuite, 
		 	SUM(c.succeeded) AS c_succ, 
		 	SUM(c.failed) AS c_fail, 
			SUM(c.internal_error) AS c_interr, 
			SUM(c.skipped) AS c_skip, 
			(CASE WHEN c.failed>0 THEN 'f' WHEN c.internal_error>0 THEN 'i' WHEN c.skipped>0 THEN 'S' WHEN c.succeeded>0 THEN 's' ELSE 'i' END) AS c_state,
		waiver_id
	");
	$from="result c JOIN tcf_group tc USING(tcf_id) JOIN testsuite sc USING(testsuite_id) JOIN testcase ss USING(testcase_id), result r JOIN tcf_group tr USING(tcf_id) JOIN testsuite sr USING(testsuite_id) LEFT OUTER JOIN waiver USING(testcase_id)";
	$where="c.testcase_id=r.testcase_id";

	# attributes
	$attrs_known=array(
		'cand_submission_id'	=> array('tc.submission_id=?','i'),
		'ref_submission_id'	=> array('tr.submission_id=?','i'),
		'cand_tcf_id'		=> array('c.tcf_id=?','i'),
		'ref_tcf_id'		=> array('r.tcf_id=?','i')
	);

	# check that both cand/ref are specified, would block DB otherwise
	if(!(	(isset($attrs['cand_submission_id']) || isset($attrs['cand_tcf_id'])) &&
		(isset($attrs['ref_submission_id'])  || isset($attrs['ref_tcf_id'] )) ))
		die("Called regression_difference() without specifying cand/ref, would block DB");

	# other query settings
	$attrs['just_sql']=true;
	$attrs['where']=$where;
	$attrs['order_nr']=2;
	$attrs['group_by']='c.testcase_id';
	
	# disable inner select's default limit of search_common()
	if( !isset($attrs['limit']) )
		$attrs['limit']=array();	

	# generate inner query
	$args=search_common($sel,$from,$attrs,$attrs_known);
	$sql="FROM (".$args[2].") tbl WHERE c_state!=r_state";

	# paging
	$limit=null;
	if( !is_null($pager) )	{
		$cargs = $args;
		$cargs[2] = "SELECT COUNT(*) $sql";
		array_splice($cargs,0,2);
		$count = call_user_func_array('scalar_query',$cargs);
		$limit = limit_from_pager($pager,$count);
	}

	# get data
	$args[2] = "SELECT * $sql".(is_null($limit) ? '' : " LIMIT ".$limit[0].','.$limit[1]);

	return call_user_func_array('mhash_query',$args);
}

function search_user($username) {
	return scalar_query('SELECT password FROM mysql.user WHERE user=?','s',$username);
}


###############################################################################
# API for submission, configuration, comments etc.

function submission_set_details($submission_id, $status_id, $related, $comment, $ref)
{	return update_query('UPDATE submission SET status_id=?,related=?,comment=?,ref=? WHERE submission_id=?','iissi',$status_id,$related,$comment,$ref,$submission_id);	}

/**  gets ID of related submission or null */
function submission_get_related($submission_id)
{	return scalar_query('SELECT related FROM submission WHERE submission_id=?','i',$submission_id);	}

/*  sets ID of a related submission */
#function set_related_submission($submission_id, $related_id)
#{	return update_query('UPDATE submission SET related=? WHERE submission_id=?','ii',$related_id,$submission_id);	}

/*  gets a comment from the submission table */
#function get_comment($submission_id)
#{	return scalar_query('SELECT comment FROM submission WHERE submission_id=?','i',$submission_id);	}

/*  sets a comment in the submission table */
#function set_comment($submission_id, $comment)
#{	return update_query('UPDATE submission SET comment=? WHERE submission_id=?','si',$comment,$submission_id);	}

/**  gets hwinfo */
function hwinfo_get($hwinfo_id)
{
	$data=scalar_query('SELECT hwinfo_bz2 FROM hwinfo WHERE hwinfo_id=?','i',$hwinfo_id);
	if( $data )
		$data=bzdecompress($data);
	return $data;
}

/** gets submission's hwinfo_id */
function submission_get_hwinfo_id($submission_id)
{	return scalar_query('SELECT hwinfo_id FROM submission WHERE submission_id=?','i',$submission_id);	}

/** Deletes the whole submission. Triggers will delete the details. */
function submission_delete($submission_id)
{	return update_query('DELETE FROM submission WHERE submission_id=?','i',$submission_id);	}

/** 
  * Fetches TCF details and result stats for either a $submission_id or a tcf_id.
  * @param int $type 0 for submission_id, 1 for tcf_id
  * @param int $ID either submission_id or tcf_id
  **/
function tcf_details($ID,$type,$header=1,$limit=null)
{
	return mhash_query($header,$limit,'SELECT g.tcf_id,g.testsuite_id,COUNT(r.testcase_id) as testcase,SUM(r.succeeded) as succeeded,SUM(r.failed) as failed,SUM(r.internal_error) as internal_error,SUM(r.skipped) as skipped, SUM(r.times_run) as times_run,SUM(test_time) as test_time,g.log_url FROM tcf_group g LEFT OUTER JOIN result r USING(tcf_id) WHERE g.'.($type ? 'tcf':'submission').'_id=? GROUP BY g.tcf_id','i',$ID);
}

/** deletes all TCFs for a submission_id and testcase_id */
function tcf_delete($submission_id, $tcf_id)
{	return update_query('DELETE FROM tcf_group WHERE submission_id=? AND tcf_id=?','ii',$submission_id,$tcf_id);	}

/** Returns a submission_id for a tcf_id */
function tcf_get_submission($tcf_id)
{	return scalar_query('SELECT submission_id FROM tcf_group WHERE tcf_id=? LIMIT 1','i',$tcf_id);	}

/** Sets a URL link to test logs */
function tcf_set_url($tcf_id,$url)
{	return update_query('UPDATE tcf_group SET log_url=? WHERE tcf_id=?','si',$url,$tcf_id);	}

/** Returns URL to test logs */
function tcf_get_url($tcf_id)
{	return scalar_query('SELECT log_url FROM tcf_group WHERE tcf_id=?','i',$tcf_id);	}

function testcase_get_relative_url($testcase_id)
{	return scalar_query('SELECT relative_url FROM testcase WHERE testcase_id=?','i',$testcase_id);	}


/** Creates or finds current user's numerical ID in the table 'tester' */
function get_user_id()
{
	global $mysqluser;
	return enum_get_id_or_insert('tester',$mysqluser);
}

/** Lists last board entries. */
function board_list($header=1,$limit=null)
{	return mhash_query($header,$limit,'SELECT board_id,last_update,created_by,updated_by,topic FROM board ORDER BY last_update DESC');	}

/** Inserts a new board entry. */
function board_insert($topic)
{	return insert_query('INSERT INTO board(created_by,topic) VALUES(?,?)','is',get_user_id(),$topic);	}

/** Gets just one topic from the board. */
function board_get_topic($board_id)
{	return scalar_query('SELECT topic FROM board WHERE board_id=?','i',$board_id);	}

/** Updates a board topic. */
function board_update($board_id,$topic)
{	return update_query('UPDATE board SET topic=?,updated_by=? WHERE board_id=?','ssi',$topic,get_user_id(),$board_id);	}

/** Deletes a board topic. */
function board_delete($board_id)
{	return update_query('DELETE FROM board WHERE board_id=? LIMIT 1','i',$board_id);	}

/** Returns nonzero if there are new board messages since user's last visit. */
function board_last()
{
	$last = scalar_query('SELECT last FROM board_last WHERE tester_id=?','i',get_user_id());
	if( !$last )	return 0;	# default for new board_last record for the current user
	return scalar_query('SELECT EXISTS(SELECT * FROM board WHERE last_update>? LIMIT 1)','s',$last);
}

/** Updates current user's last board access info in the table board_last. */
function board_update_last()
{	return update_query('INSERT INTO board_last(tester_id) VALUES(?) ON DUPLICATE KEY UPDATE last=NOW()','i',get_user_id());	}


/** Gets a description text for a given database table. */
function table_description($table)
{	return scalar_query('SELECT `desc` FROM table_desc WHERE `table`=? LIMIT 1','s',$table);	}

###############################################################################
# API for RPM configurations
# minimalistic (rest done by import script) - expand when needed

/** gets rpm_config_id from submission */
function get_rpm_config_id($tcf_id)
{	return scalar_query('SELECT rpm_config_id FROM tcf_group WHERE tcf_id=?','i',$tcf_id);	}

/** gets RPM basenames and versions for a given rpm_config_id, returns table with 2 columns */
function rpms_fetch($rpm_config_id,$header=1,$limit=null)
{	
	return matrix_query($header,$limit,"SELECT rpm_basename, rpm_version FROM software_config JOIN rpm USING(rpm_id) JOIN rpm_basename USING(rpm_basename_id) JOIN rpm_version USING(rpm_version_id) WHERE rpm_config_id=? ORDER BY rpm_basename,rpm_version",'i',$rpm_config_id);	
}

/** 
 * compares two or more configurations, returns versions that don't exist in other ones
 * usage: diff_rpms( $rpm_config_id, $rpm_config_id2, ... )
 **/
function rpms_diff($limit,$all,$rpm_config_ids) 
{
	$sql_args=array(); # SQL args for prepared statement
	$select='rpm_basename';
	$from='software_config c JOIN rpm r USING(rpm_id) JOIN rpm_basename USING(rpm_basename_id) JOIN rpm_version USING(rpm_version_id)';
	$where2=array(); # 'c<n>.rpm_id is null' conditions
	$cnt=count($rpm_config_ids);
	for($i=0; $i<$cnt; $i++)	{
		$rpm_config_id=$rpm_config_ids[$i];
		$select .= ", GROUP_CONCAT(DISTINCT IF(c$i.rpm_id,rpm_version,NULL) SEPARATOR '<br/>') AS '$rpm_config_id'";
		$from .= " LEFT OUTER JOIN software_config c$i ON(r.rpm_id=c$i.rpm_id and c$i.rpm_config_id=?) ";
		$where2[] = "c$i.rpm_id IS NULL";
		$sql_args[] = $rpm_config_id;
	}
	$where = "c.rpm_config_id IN (".join( ',', array_fill(0,$cnt,'?') ).')';
	if( !$all )
		$where .= " AND (".join(' OR ', $where2 ).")";
	$sql = "SELECT $select FROM $from WHERE $where GROUP BY rpm_basename";
	$call = array(1,$limit,$sql,str_repeat('i',2*$cnt));
	return call_user_func_array('mhash_query',array_merge($call,$sql_args,$sql_args));
/*	Original query that supported only two rpm_config_ids was:
	return matrix_query(1,$limit,
		"SELECT rpm_basename, ".
			"GROUP_CONCAT(IF(c1.rpm_id,rpm_version,NULL) SEPARATOR '<br/>') AS 'v. $rpm_config_id1', ".
			"GROUP_CONCAT(IF(c2.rpm_id,rpm_version,NULL) SEPARATOR '<br/>') AS 'v. $rpm_config_id2'".
		"FROM software_config c JOIN rpm r USING(rpm_id) ".
			"JOIN rpm_basename USING(rpm_basename_id) JOIN rpm_version USING(rpm_version_id) ".
			"LEFT OUTER JOIN software_config c1 ON(r.rpm_id=c1.rpm_id and c1.rpm_config_id=?) ".
			"LEFT OUTER JOIN software_config c2 ON(r.rpm_id=c2.rpm_id and c2.rpm_config_id=?) ".
		"WHERE c.config_id in (?,?) AND (c1.rpm_id IS NULL OR c2.rpm_id IS NULL) ".
		"GROUP BY rpm_basename","iiii",$rpm_config_id1,$rpm_config_id2,$rpm_config_id1,$rpm_config_id2);*/
}

/** returns the number of RPMs in a given rpm_config_id */
function rpms_num($rpm_config_id)
{
	return scalar_query('SELECT COUNT(*) FROM software_config WHERE rpm_config_id=?','i',$rpm_config_id);
}

$glob_dest=array( 
	array("index.php", "Home"), 
	'log' => array(), 
	array("result.php", "Results"), 
	array("submission.php", "Submissions"), 
	array("regression.php", "Regressions"), 
	array("waiver.php", "Waiver"), 
	'board' => array("board.php", "Board"),
	array("reference.php","Ref. host"),
	array("promote.php", "BuildNr."),
#	array("trends.php", "Trend Graphs"), 
#	array("bench/search.php", 'Benchmarks'), 
#	array(" "," "), 
	array( array(
		array("http://qadb.suse.de/hamsta/", "De"),
		array("http://hamsta.qa.suse.cz/hamsta/", "Cz"),
		array("http://hamsta.sled.lab.novell.com/hamsta/","Us"),
		array("http://147.2.207.30/hamsta/index.php","Cn"),
		), 'Hamsta'),
	array("doc.php","Docs")); 

/** logs into DB, checks user, prints header, prints navigation bar */
function common_header($args=null)
{
	global $conn_id,$glob_dest;
#	$is_production_server = ( $_SERVER['SERVER_ADDR'] == '10.10.3.155' );
	$defaults=array(
		'session'=>true,
		'connect'=>true,
		'icon'=>'icons/qadb_ico.png'
	);
	$args=args_defaults($args,$defaults);
	if( $args['session'] )
		session_start();
	if( $args['connect'] )
		$conn_id=connect_to_mydb();
	print html_header($args);
	print_nav_bar($glob_dest);
}



###############################################################################
# other functions

/**
  * Prints one-row table of submission details. 
  * @return array the used table data
  **/
function &print_submission_details($submission_id)
{
	$transl=array();
	$where=array('submission_id'=>$submission_id);
	$res=search_submission_result(1,$where,$transl);
	if( count($res)<2 )
		print "No such submission_id: $submission_id<br/>\n";
	else
	{
		if($res[1]['type']=='maint')
			$res=search_submission_result(2,$where,$transl);
		else if($res[1]['type']=='kotd')
			$res=search_submission_result(3,$where,$transl);
		$res2=$res; # need to return original values
		table_translate($res2, $transl );
		print html_table( $res2, null, null );
	}
	return $res;
}

/** Prints one-row table with TCF details. */
function &print_tcf_details($tcf_id)
{
	$res=tcf_details($tcf_id,1);
	if( count($res)<2 )
		print "No such tcf_id: $tcf_id<br/>\n";
	else
	{
		$res2=$res; # preserve to return
		table_translate($res2,array(
			'links'=>array('tcf_id'=>'result.php?search=1&tcf_id='),
			'enums'=>array('testsuite_id'=>'testsuite'),
			'urls'=>array('log_url'=>'log')
		));
		print html_table($res2,null,null);
	}
	return $res;
}

/** returns newest and oldest allowed version of a script, or for all known scripts */
function get_script_versions($name=null)
{
	$base="SELECT script_name, CONCAT(latest_major,'.',latest_minor), CONCAT(minimal_major,'.',minimal_minor) FROM script_version";
	if( $name )
		return matrix_query(0,null,"$base WHERE script_name=?",'s',$name);
	else
		return matrix_query(0,null,$base);
}

/** converts dynamical menu items, prints the menu */
function print_nav_bar($dest)
{
	global $conn_id;
	foreach( array_keys($dest) as $key )
	{
		if( is_numeric($key) ) continue;
		switch($key)
		{
			case 'log':
				if( isset($_SESSION['user']) && isset($_SESSION['pass']) )
					$dest[$key]=array( "logout.php", "Logout");
				else
					$dest[$key]=array("login.php", "Login");
				break;

			case 'board':
				if( $conn_id && board_last() )
					$dest[$key][1]='<span class="board_new">'.$dest[$key][1].'</span>';
				break;
		}
	}
	print nav_bar($dest);
}

# process result table before printing
# $sub_info is output from print_submission_details()
# $data should contain fields: '
function result_process_print(&$data,$sub_info,$transl,$pager,$id)
{
	# links to logs
	$tcf_id_url=array();

	# add highlight, waiver info, links to logs
	for( $i=1; $i<count($data); $i++ )
	{
		# highlight
		$classes='';
		if( $data[$i]['skipped'] ) $classes=' skipped';
		if( $data[$i]['internal_error'] ) $classes=' internalerr';
		if( $data[$i]['failed'] ) $classes=' failed';

		# waivers
		$waiver_id=$data[$i]['waiver_id'];
		if( $waiver_id )
		{	# waiver exists
			$data[$i]['waiver']=html_text_button("show","waiver.php?view=vw&waiver_id=$waiver_id");
			$classes.=' w';
		}
		else
		{	# waiver does not exist
			$matchtype=($data[$i]['failed'] || $data[$i]['internal_error'] ? 'problem' : 'no+problem');
			$data[$i]['waiver']=html_text_button("create","waiver.php?view=nwd&detail=1&testcase=".$data[$i]['testcase_id'].'&arch='.$sub_info[1]['arch_id'].'&product='.$sub_info[1]['product_id'].'&release='.$sub_info[1]['release_id']."&matchtype=$matchtype");
		}
		unset($data[$i]['waiver_id']);

		# links to logs
		$my_tcf_id=$data[$i]['tcf_id'];
		if( !array_key_exists($my_tcf_id,$tcf_id_url) )
			$tcf_id_url[$my_tcf_id]=tcf_get_url($my_tcf_id);
		$url=$tcf_id_url[$my_tcf_id];
		$data[$i]['logs']=($url ? html_link('logs',$tcf_id_url[$my_tcf_id].'/'.$data[$i]['relative_url']) : '');
                #Display Graphs for benchmark results.
		if( $data[$i]['is_bench'] )
		{
			require_once('defs.php');
		        $graphlink="benchmarks.php?tests[]=".$my_tcf_id."&testcase=".$data[$i]['testcase']."&group_by=0&graph_x=".$bench_def_width."&graph_y=".$bench_def_height."&legend_pos=".$bench_def_pos."&font_size=".$bench_def_font."&search=1";
			$data[$i]['testcase']= html_link($data[$i]['testcase'],$graphlink);
		}
		unset($data[$i]['testcase_id']);
		unset($data[$i]['relative_url']);
		unset($data[$i]['is_bench']);

		# append highlight info at the end
		$data[$i][]=$classes;
	}
	# fix the header
	$data[0]['logs']='logs';
	$data[0]['waiver']='waiver';
	unset($data[0]['waiver_id']);
	unset($data[0]['testcase_id']);
	unset($data[0]['relative_url']);
	unset($data[0]['is_bench']);

	table_translate( $data, $transl );
	print html_table( $data, array('callback'=>'highlight_result','id'=>$id,'sort'=>'iissiiiiiiss','pager'=>$pager,'total'=>1));
}

# DB schema last update
function schema_get_version()
{	return scalar_query('SELECT version FROM `schema` LIMIT 1');	}

# standard highlight function - returns last column (to be used as class)
function highlight_result()
{	# return last nonprintable column of the table
	$row=func_get_args();
	return $row[count($row)-1];
}

function reference_host_search($attrs,&$transl=array(),&$pager=null)
{
	$attrs_known = array(
		'reference_host_id'=>array('reference_host_id=?','i'),
		'host_id'=>array('host_id=?','i'),
		'arch_id'=>array('arch_id=?','i'),
		'product_id'=>array('product_id=?','i')
	);
	$transl['enums'] = array(
		'host_id'=>'host',
		'arch_id'=>'arch',
		'product_id'=>'product',
	);
	$transl['ctrls'] = array(
		'edit'=>'reference.php?step=edit&reference_host=',
		'delete'=>'confirm.php?confirm=rh&reference_host='
	);
	return search_common(
		array('reference_host_id','host_id','arch_id','product_id'),
		'reference_host',
		$attrs,
		$attrs_known,
		$pager
	);
}

function reference_host_insert($host_id,$arch_id,$product_id)	{
	return insert_query('INSERT INTO reference_host(host_id,arch_id,product_id) VALUES(?,?,?)', 'iii', $host_id, $arch_id, $product_id );
}

function reference_host_delete($reference_host_id)	{
	return update_query('DELETE FROM reference_host WHERE reference_host_id=?', 'i', $reference_host_id );
}



?>
