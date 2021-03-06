<?php

/**
  * QADB - related functions
  * @package QADB
  * @filesource
  * @license http://opensource.org/licenses/gpl-2.0.php GNU General Public License
  **/

/** library functions - common DB and HTML functions */
require_once('../tblib/tblib.php');
require_once('Zend/Auth.php');
require_once('Zend/Session.php');

$enums = array(
	'arch'			=> array('arch_id','arch'),
	'product'		=> array('product_id','product'),
	'release'		=> array('release_id','release'),
	'kernel_branch'		=> array('kernel_branch_id','kernel_branch'),
	'kernel_flavor'		=> array('kernel_flavor_id','kernel_flavor'),
	'kernel_version'	=> array('kernel_version_id','kernel_version'),
	'testsuite'		=> array('testsuite_id','testsuite'),
	'testcase'		=> array('testcase_id','testcase'),
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
# API for build promote data
function build_promoted_list($limit=null)
{
       return matrix_query(1,$limit,'SELECT build_promoted_id,arch,build_nr,product,`release` FROM build_promoted JOIN arch USING(arch_id) JOIN product USING(product_id) JOIN `release` USING(release_id) ORDER BY build_promoted_id');
}

function build_promoted_insert_update($arch_id,$product_id,$build_nr,$release_id)
{
        $insert=insert_query('INSERT INTO build_promoted (arch_id,build_nr,product_id,release_id) VALUES (?,?,?,?)','iiii',$arch_id ,$build_nr,$product_id,$release_id);
        $update=update_query('UPDATE submission SET release_id = ? WHERE arch_id=? AND build_nr=? AND product_id=?','iiii',$release_id,$arch_id,$build_nr,$product_id);
	return array ($insert,$update);

}

function build_promoted_delete($build_promoted_id)	{
	return update_query('DELETE FROM build_promoted WHERE build_promoted_id=?','i',$build_promoted_id);
}

/** searches for submission, testsuite, or result
  * $mode :
  *   0 result
  *   1 just submission
  *   2 maintenance
  *   3 KOTD
  *   4 product
  *   5 any
  *   6 testsuite (+testcase)
  *   7 trend graphs
  *   8 submission + TCF
  *   9 bench search
  *  10 submission + TCF + testcase
  *  11 extended regressions, both testsuite and testcase
  *  12 extended regressions, just testsuites
  *  13 distinct products/releases for extended regressions
  *  14 distinct testsuite/testcase combinations (for regressions)
  *  15 distinct submissions for extended regressions
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
	global $dir;
	# base SQL for reference searches
	$rs1='EXISTS( SELECT * FROM reference_host rh WHERE s.host_id=rh.host_id AND s.arch_id=rh.arch_id AND s.product_id=rh.product_id )';
	# base SQL for result difference
	$rd1='NOT EXISTS( SELECT * FROM result r2 JOIN tcf_group g2 USING(tcf_id) WHERE';
	$rd2='AND r.testcase_id=r2.testcase_id)';
	# base SQL for testsuite existence searches
	$te1='EXISTS( SELECT * FROM tcf_group g WHERE g.testsuite_id=? AND g.submission_id=s.submission_id)';
	# base fields for summaries
	$sum=array('SUM(times_run) AS runs','SUM(succeeded) AS succ', 'SUM(failed) AS fail', 'SUM(internal_error) AS interr', 'SUM(skipped) AS skip', 'SUM(test_time) AS time', "CASE WHEN SUM(failed)>0 THEN 'failed' WHEN SUM(internal_error)>0 THEN 'interr' WHEN SUM(skipped)>0 THEN 'skipped' WHEN SUM(succeeded)>0 THEN 'success' ELSE NULL END AS status");
#	$status="CASE WHEN failed THEN 'failed' WHEN internal_error THEN 'interr' WHEN skipped THEN 'skipped' WHEN succeeded THEN 'success' ELSE NULL END AS status";
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
		'testsuite_eid'	=> array( $te1,				'i'),
		'testcase_id'	=> array('r.testcase_id=?',		'i'),
		'testcase'	=> array('c.testcase like ?',		's'),
		'tcf_id'	=> array('r.tcf_id=?',			'i'),
		'submission_id'	=> array('s.submission_id=?',		'i'),
		'rpm_config_id'	=> array('s.rpm_config_id=?',		'i'),
		'hwinfo_id'	=> array('s.hwinfo_id=?',		'i'),
		'comment'	=> array('s.comment like ?',		's'),
		'status_id'	=> array('s.status_id=?',		'i'),
		'md5sum'	=> array('s.md5sum=?',			's'),
		'patch_id'	=> array('s.patch_id=?',		's'),
		'issuer_id'	=> array('s.issuer_id=?',		's'),
		'issue_id'	=> array('s.issue_id=?',		'i'),
		'type'		=> array('s.type=?',			's'),
		'kernel_version'=> array('s.kernel_version_id=?',	'i'),
		'kernel_branch'	=> array('s.kernel_branch_id=?',	'i'),
		'kernel_flavor'	=> array('s.kernel_flavor_id=?',	'i'),
		'ref'		=> array("s.ref!=''",			   ),
		'refhost'	=> array( $rs1				   ),
		# testcase differences - only for result search
		'res_minus_sub'	=> array("$rd1 g2.submission_id=? $rd2",'i'),
		'res_minus_tcf'	=> array("$rd1 g2.tcf_id=? $rd2",	'i'),
		'has_succ'	=> array('r.succeeded>0'		   ),
		'has_fail'	=> array('r.failed>0'			   ),
		'has_interr'	=> array('r.internal_error>0'		   ),
		'has_skip'	=> array('r.skipped>0'			   ),
		'has_nosucc'	=> array('(r.failed+r.internal_error+r.skipped)>0' ),
	);

	# index into $sel0[], $sel1[] (SELECT ...), and $from0[] (FROM ...)
	$i_main = array( 1,0,0,0,0,0,2,0,0,0,0,2,2,3,4,5 );
	# index into $sel2[] (SELECT ...)
	$i_next = array( 0,0,1,2,0,3,0,4,5,5,6,7,8,0,9,0 );
	# index into $from2[] (FROM ...)
	$i_from = array( 0,0,1,2,3,4,0,0,5,6,7,0,0,8,0,0 );
	# index into $links2[] ( $transl->['links'] )
	$i_link = array( 0,0,0,1,0,0,0,0,2,2,2,0,0,0,0,0 );

	# should I return submission_id only?
	$only_id  = hash_get($attrs,'only_id',false,true);

	# skip the header?
	$header = hash_get($attrs,'header',true,false);

	# SELECT $sel FROM $from GROUP BY $group_by
	# $sel = $sel0 [ $sel1 ] [ $sel2 ]
	# $from = $from0 $from2
	# $sel0..$sel2 are done as lists - for ordering by them
	# $sel0[ $i_main ] -- always
	$sel0=array( 's.submission_id', 'r.result_id', 'testsuite_id','DISTINCT product_id', 'DISTINCT testsuite_id', 'DISTINCT submission_id' );
	# $sel1[ $i_main ] -- appends for full details
	$sel1=array( 
/* subms */  array('s.submission_date','s.host_id','s.tester_id','s.arch_id','s.product_id','s.release_id','s.related','s.status_id','s.comment','s.rpm_config_id','s.hwinfo_id','s.type','s.ref'),
/* rslts */  array('g.tcf_id','g.testsuite_id','r.testcase_id','t.testcase','r.succeeded','r.failed','r.internal_error','r.skipped','r.times_run','r.test_time','w.waiver_id','t.relative_url','(SELECT COUNT(b.result) from bench_data b where b.result_id=r.result_id) AS bench_count'),
/* suite */  array(),
/* Dprod */  array('product','s.release_id','`release`'),
/* Dsuit */  array(),
/* Dsubm */  array(),
	);
	# $sel2[ $i_next ] -- appends for full details
	$sel2=array( 
/* simple */ array(),
/* mtnce  */ array('s.patch_id','s.issuer_id','s.issue_id','s.md5sum'),
/* KOTD   */ array('s.md5sum','s.kernel_version_id','s.kernel_branch_id','s.kernel_flavor_id'),
/* any    */ array('s.patch_id','s.md5sum'),
/* trend  */ array('g.testsuite_id'),
/* TCF    */ array('g.testsuite_id','g.tcf_id'),
/* TCF+res*/ array('g.testsuite_id','g.tcf_id','r.testcase_id'),
/* regs	  */ array_merge(array('testcase_id'),$sum),
/* regs-  */ $sum,
/* tcases */ array('r.testcase_id'),
	);

	# $from0[ $i_main ] -- always
	$from0=array( 
/* subms */	'submission s', 
/* rslts */	'submission s JOIN tcf_group g USING(submission_id) JOIN result r USING(tcf_id)',
/* suite */	'submission s JOIN tcf_group g USING(submission_id)',
/* Dprod */	'submission s JOIN product USING(product_id) JOIN `release` USING(release_id)',
/* Dsuit */	'submission s JOIN tcf_group g USING(submission_id)',
/* Dsubm */	'submission s JOIN tcf_group g USING(submission_id)',
);
	# $from1[ $i_main ] -- append for full details
	$from1=array( 
/* subms */	'', 
/* rslts */	' JOIN testcase t USING(testcase_id) LEFT OUTER JOIN waiver w USING(testcase_id)', 
/* suite */	' JOIN `result` r USING(tcf_id)', 
/* Dprod */	'',
/* Dsuit */	' JOIN `result` r USING(tcf_id)',
/* Dsubm */	'',
);
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
/* regres */	' JOIN tcf_group g USING(submission_id) JOIN result r USING(tcf_id)', # testsuite/testcase joined to sort properly
	);

	# GROUP BY can be overwritten by $attrs['group_by']
	# $group_by = [ $group_by0 ] [ $group_by1 ]
	# $group_by0[ $i_main ] - always
	$group_by0=array(
/* subms */	array(),
/* rslts */	array(),
/* suite */	array(),
/* Dprod */	array(),
/* Dsuit */	array(),
/* Dsubm */	array(),
	);

	# $group_by1[ $i_next ] - appends for full details
	$group_by1=array(
/* simple */	array(),
/* mtnce  */	array(),
/* KOTD   */	array(),
/* prod   */	array(),
/* any    */	array(),
/* TCF    */	array(),
/* bench  */	array(),
/* regs   */	array('testsuite_id','testcase_id'),
/* regs-  */	array('testsuite_id'),
/* tcases */	array(),
	);


	# $enum1[ $i_main ] - for full details when $transl set
	$enum1=array(
/* subms */  array('host_id'=>'host','tester_id'=>'tester','arch_id'=>'arch','product_id'=>'product','release_id'=>'release','status_id'=>'status'),
/* rslts */  array('testsuite_id'=>'testsuite'),
/* suite */  array('testsuite_id'=>'testsuite'),
/* Dprod */  array(),
/* Dsuit */  array('testsuite_id'=>'testsuite'),
/* Dsubm */  array(),
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
/* regs   */	array('testcase_id'=>'testcase'),
/* regs-  */	array(),
/* tcases */	array(),
	);

	# $links1[ $i_main ] - for full details when $transl set
	$links1=array(
/* subms */	array('submission_id'=>$dir.'submission.php?submission_id=','related'=>$dir.'submission.php?submission_id=','rpm_config_id'=>$dir.'rpms.php?rpm_config_id=','hwinfo_id'=>$dir.'hwinfo.php?hwinfo_id='),
/* rslts */	array('tcf_id'=>$dir.'result.php?tcf_id='),
/* suite */	array(),
/* Dprod */	array(),
/* Dsuit */	array(),
/* Dsubm */	array(),
	);

	# $links2[ $i_link ] - for full details when $transl set
	$links2=array(	
		array(),
/* KOTD */	array('md5sum'=>'http://kerncvs.suse.de/gitweb/?p=kernel-source.git;a=commit;h='), 
/* TCF data */	array('tcf_id'=>$dir.'result.php?tcf_id=') 
	);
	
	# make the SQL base SELECT
	$sel=array($sel0[$i_main[$mode]]);
	if( !$only_id )
		$sel=array_merge($sel, $sel1[$i_main[$mode]], $sel2[$i_next[$mode]]);
	$from=$from0[$i_main[$mode]].($only_id ? '' : $from1[$i_main[$mode]]).$from2[$i_from[$mode]];
	if( !isset($attrs['group_by']) )
		$attrs['group_by']=array_merge($group_by0[$i_main[$mode]],($only_id ? array() : $group_by1[$i_next[$mode]] ));

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


/**
  * Extended regressions finder
  * @param $is_tc boolean true to show testcases
  * @param $method int 1: different status, 2: fails+interrs, 3: everything
  * @param $attrs the search attributes
  * @param &$transl array enum translation table
  * @param &$pager array pager
  **/
function extended_regression($is_tc,$group_submissions,$method,$attrs,&$footer=null,&$transl=null,&$pager=null)
{
	# This turned out to be the simplest way to print extended regressions
	# in a reasonable time.
	# If you want to really understand the construction, try dumping the
	# output SQL and study it in-depth.
	# Basically there are following steps to be performed by the database:
	# - find the columns, i.e. product/release combinations
	# - fetch all combinations of testsuites (+testcases)
	# - for every column (i.e. product/release), create own tmp table with the results
	# - add some statistics to these temporary tables
	# - run the main SELECT that joins them all and does the regression filtering
	# - clean up

	# first part, just read the products/releases that go onto X
	$debug=0;
	$use_res=($method==1);
	$cell_color	= hash_get($attrs,'cell_color',1,true);
	$cell_text	= hash_get($attrs,'cell_text',1,true);
	$footer_color	= hash_get($attrs,'footer_color',1,true);
	$footer_text	= hash_get($attrs,'footer_text',1,true);
	$show_runs	= hash_get($attrs,'show_runs',0,true);
	$a=$attrs; # copy for the main query
	$attrs['just_sql']=1; # use the original to generate SQL

	# order by, group by
	if( !$group_submissions )
		$a['order_by']=array('product','`release`');
	unset($a['group_by']);

	if( $debug>1 )	{
		print "<pre>"; 
		print_r($a);
		print "SQL="; 
		print_r(search_submission_result(($group_submissions ? 15 : 13),array_merge($a,array('just_sql'=>1)))); 
		print "</pre>\n";
	}

	# make X axis
	$xaxis=search_submission_result(($group_submissions ? 15 : 13),$a);
	if( count($xaxis) < 2 )	{
		return array(array()); # empty table header
	}
	if( count($xaxis) > 51 )	{
		print html_error("Too many different values on X axis (".(count($xaxis)-1)."), only showing first 50");
		array_splice($xaxis,50);
	}
	if( $debug )	{
		print "<h3>X-axis</h3>\n";
		print html_table($xaxis);
	}
	
	# we use one more temporary table than the X count
	# this produces their names
	$tbase='qadb_tmp.tmp_ext_reg_'.rand(1000,9999);
	$tbase1=$tbase.'_base';
	$tbase2=$tbase.'_t';

	# SQL to clean up at the end
	$cleanup=array("DROP TABLE IF EXISTS $tbase1");

	# SQL to prepare the temporary tables
	$commands=array(
		$cleanup[0],
		"CREATE TEMPORARY TABLE $tbase1 ( testsuite_id INT, ".($is_tc ? 'testcase_id INT, ':'').'INDEX(testsuite_id'.($is_tc ? ',testcase_id':'').' ))',
	);

	# prepare base table that just holds all combinations of testsuites (+testcases)
	if( $group_submissions )	{
		$submission_id=array();
		for( $i=1; $i<count($xaxis); $i++ )
			$submission_id[$xaxis[$i]['submission_id']]=1;
		$attrs['submission_id']=array_keys($submission_id);
	}
	else	{
		$product_id=array();
		$release_id=array();
		for($i=1; $i<count($xaxis); $i++)	{
			$product_id[$xaxis[$i]['product_id']]=1;
			$release_id[$xaxis[$i]['release_id']]=1;
		}
		$attrs['product_id']=array_keys($product_id);
		$attrs['release_id']=array_keys($release_id);
	}
	$attrs['only_id']=(!$is_tc);
	$sub_sql=search_submission_result(14,$attrs);
	$attrs['only_id']=0;
	$sub_sql[2]="INSERT INTO $tbase1 ".$sub_sql[2];
	array_splice($sub_sql,0,2); # remove header/limit
	$commands[]=$sub_sql;

	# fields for SELECT
	$select=array('testsuite_id'=>'base.testsuite_id');
	if( $is_tc )
		$select['testcase_id']='base.testcase_id';

	# joined temporary tables of the FROM section
	$from=array("$tbase1 base");

	# parts of WHERE
	$where=array();

	# data columns for full statistics
	$cols=array('status','runs','succ','fail','interr','skip','time');

	# data columns for finding regressions
	$colsr=array_slice($cols,2,4);

	# parts of term to find status differences (SELECT+WHERE sections)
	if( $use_res )	{
		$res=array();
		foreach($colsr as $c)
			$res[$c]=array();
	}

	# create & fill a temporary table holding testsuites/testcases for every column
	for($i=1; $i<count($xaxis); $i++)	{
		# this is what we are processing now
		if( $group_submissions )	{
			$attrs['submission_id']=$xaxis[$i]['submission_id'];
		}
		else	{
			$attrs['product_id']=$xaxis[$i]['product_id'];
			$attrs['release_id']=$xaxis[$i]['release_id'];
		}

		# SQL to clean up the temporary tables
		$clean="DROP TABLE IF EXISTS $tbase2$i";
		$cleanup[]=$clean;
		$commands[]=$clean;

		# create table, insert data, set is_*
		$commands[]="CREATE TEMPORARY TABLE $tbase2$i( testsuite_id INT, ".($is_tc ? 'testcase_id INT, ':'')."runs INT, succ INT, fail INT, interr INT, skip INT, time INT, status ENUM('success','skipped','interr','failed'), is_succ TINYINT, is_skip TINYINT, is_interr TINYINT, is_fail TINYINT, INDEX(testsuite_id,".($is_tc ? 'testcase_id,':'')."status) )";
		$sub_sql=search_submission_result($is_tc ? 11:12,$attrs,$transl);
		$sub_sql[2]="INSERT INTO $tbase2$i(testsuite_id,".($is_tc ? 'testcase_id,':'')."runs,succ,fail,interr,skip,time,status) ".$sub_sql[2];
		array_splice($sub_sql,0,2);
		$commands[]=$sub_sql;
		$commands[]="UPDATE $tbase2$i SET is_succ=IF(status='success',1,0), is_skip=IF(status='skipped',1,0), is_interr=IF(status='interr',1,0), is_fail=IF(status='failed',1,0)";

		# fields that go into the main SELECT
		foreach( $cols as $c )
			$select["$c$i"]="t$i.$c";

		if( $use_res )	{
			# for status differences, this is what we put there
			foreach( $colsr as $c )	{
				if( !isset($res[$c]) )
					$res[$c]=array();
				$res[$c][]="IFNULL(t$i.is_$c,0)";
			}
		}
		else if( $method==2 )	{
			# if we print just all fails, this simpler term goes directly into WHERE
			$where[]="t$i.status IN ('interr','failed')";
		}

		# join the temporary table into the main SELECT
		$from[]="LEFT JOIN $tbase2$i t$i ON(base.testsuite_id=t$i.testsuite_id".($is_tc ? " AND base.testcase_id=t$i.testcase_id":'').')';
	}

	# when showing differences only, this builds the filter column
	if( $use_res )	{
		$resol=array();
		foreach( $colsr as $c )
			$resol[$c]='IF('.join(' + ',$res[$c]).'>0,1,0)';
		$select['res']=join(' + ',$resol);
	}

	# prepare SELECT fields
	$sel=array();
	foreach( $select as $k=>$v )
		$sel[]="$v AS $k";

	# build the base SELECT
	$sql_right=' FROM '.join(' ',$from).($where?' WHERE '.join(' OR ',$where):'');
	$sql='SELECT '.join(',',$sel).$sql_right;
	if( $use_res )	{
		# build the construction that shows different statuses
		$sql_right=" FROM ( $sql ) t WHERE t.res>1";
		$sql='SELECT '.join(',',array_keys($select)).$sql_right;
	}
	$sql_count='SELECT COUNT(*)'.$sql_right;
	if( $debug > 1 )	{
		print "<pre>\n";
		print_r($commands);
		print "</pre>\n";
		print "\nSQL=$sql\n";
		print "<pre>\n";
		print_r($cleanup);
		print "</pre>\n";
	}
	# run the section that creates & fills temporary tables
	if( ($ret=update_sequence($commands)) < 0 )
		exit;

	if( $debug )	{
		$e=array('testsuite_id'=>'testsuite');
		if( $is_tc )
			$e['testcase_id']='testcase';
		$transl=array('enums'=>$e);
		print "<h3>base</h3>\n";
		$data=mhash_query(1,null,"SELECT * FROM $tbase1");
		table_translate($data,$transl);
		print html_table($data);
		for($i=1; $i<count($xaxis); $i++)	{
			print "<h3>Table t$i</h3>\n";
			$data=mhash_query(1,null,"SELECT * FROM $tbase2$i");
			table_translate($data,$transl);
			print html_table($data);
		}
		if( $debug>1 )
			print "Count query: $sql_count<br/>\n";
	}

	# run the main query
	$limit=null;
	$count=scalar_query($sql_count);
	if( !is_null($pager) )	
		$limit=limit_from_pager($pager,$count);
	$data=mhash_query(1,$limit,$sql);

	# run the cleanup part
	if( ($ret=update_sequence($cleanup)) < 0 )
		exit;
#	print html_table($data);

#	return $data;
	# postprocessing
	$ibase=( $is_tc ? 2 : 1 );

	# format header fields
	array_splice( $data[0], $ibase );
	for( $j=1; $j<count($xaxis); $j++ )	{
		$data[0]['c'.($ibase+$j-1)]=( $group_submissions ?
			$xaxis[$j]['submission_id'] :
			sprintf( "%s<br/>%s", $xaxis[$j]['product'], $xaxis[$j]['release'] )
		);
	}

	$status2class=array('success'=>'i','failed'=>'failed','interr'=>'internalerr','skipped'=>'skipped',''=>'');
	$names=array('fail','interr','skip','succ','runs');
	if( isset($footer) )	{
		foreach( $names as $n )	{
			$footer[$n]['testsuite_id']=$n;
			if( $is_tc )
				$footer[$n]['testcase_id']='';
		}
	}
	
	for( $i=1; $i<count($data); $i++ )	{
		$r=$data[$i];
		for( $j=1; $j<count($xaxis); $j++ )	{
			$status=hash_get($r,"status$j",'',true);
			$runs=hash_get($r,"runs$j",'',true);
			$succ=hash_get($r,"succ$j",'',true);
			$fail=hash_get($r,"fail$j",'',true);
			$interr=hash_get($r,"interr$j",'',true);
			$skip=hash_get($r,"skip$j",'',true);
			$time=hash_get($r,"time$j",'',true);

			$col='c'.($ibase+$j-1);

			if( $footer )	{
				if( $i==1 )	{
					foreach( $names as $n )
						$footer[$n][$col]='';
				}
				$footer['runs'][$col] += $runs;
				$footer['succ'][$col] += $succ;
				$footer['fail'][$col] += $fail;
				$footer['interr'][$col] += $interr;
				$footer['skip'][$col] += $skip;
			}

			$f=array('text'=>'');

			if( $runs>0 )	{
				switch( $cell_text )	{
				case 1: # status
					$f['text']=$status;
					break;
				case 2: # % pass
					$f['text']=( $runs>0 ? sprintf("%2d",100*$succ/$runs).'%' : 'N/A' );
					break;
				case 3: # numbers
					$f['text']="$fail $interr $skip $succ";
					break;
				case 4: # X
					$f['text']=( $fail || $interr ? 'X' : '' );
					break;
				}

				$f['title']="fail:$fail interr:$interr skip:$skip success:$succ runs:$runs time:$time";
				switch( $cell_color )	{
				case 1: # status
					$f['class']=$status2class[$status]; 
					break;
				case 2: # RGB
					$f['style']=rgbstyle($fail,$succ,$interr,$runs);
					break;
				case 3: # grayscale
					$f['style']=rgbstyle($succ,$succ,$succ,$runs);
					break;
				}
			}
			$r[$col]=$f;
		}

		$data[$i]=$r;
	}

	# format / colorize the footer
	if( $footer )	{
		$name2class=array('succ'=>'i','fail'=>'failed','interr'=>'internalerr','skip'=>'skipped',''=>'');

		# debug: print footer
		if( $debug > 1 )	{
			print "<h3>Footer</h3>\n";
			print "<pre>\n";
			print_r($footer);
			print "</pre>\n";
		}
		foreach($footer as $n=>$row)
			foreach( $row as $col=>$val )	{
				$n2c = ( isset($name2class[$n]) ? $name2class[$n] : '' );
				# colorize the header
				if( $col=='testsuite_id' && $n2c )	{
					$footer[$n][$col]=array(
						'text'=>$val,
						'class'=>$n2c,
					);
					continue;
				}

				# get number of total runs
				$runs = ( $footer['runs'][$col] ? $footer['runs'][$col] : '' );

				# skip missing / wrong data
				if( !is_numeric($val) || !is_numeric($runs) )
					continue;
				$style = '';
				$class = '';
				if( !$val )
					$footer[$n][$col]='';
				else {
					# cell text
					switch( $footer_text )	{
					case 1: # status
						break;
					case 2: # %pass
						if( $n!='runs' )
							$val = sprintf( "%2d%%", 100*$val/$runs );
						break;
					case 3: # numbers
						break;
					case 4: # X
						$val = ($val ? 'X' : '');
						break;
					case 5:
						$val='';
						break;
					}

					# cell color
					if( $n != 'runs' )	{
						switch( $footer_color )	{
						case 1: # status
							$class=$n2c;
							break;
						case 2: # RGB
							switch( $n )	{
								case 'succ':
									$style=rgbstyle(0,$val,0,$runs);
									break;
								case 'fail':
									$style=rgbstyle($val,0,0,$runs);
									break;
								case 'interr':
									$style=rgbstyle(0,0,$val,$runs);
									break;
								default:
									$style=rgbstyle($val,$val,$val,$runs);
									break;
							}
							break;
						case 3: # grayscale
							$style=rgbstyle($val,$val,$val,$runs);
							break;
						}
					}
				}
				if( $style || $class )	{
					$footer[$n][$col]=array(
						'text'=>$val,
					);
					if( $style )
						$footer[$n][$col]['style']=$style;
					else
						$footer[$n][$col]['class']=$class;
				}
			}
	}
	if( !$show_runs )
		unset($footer['runs']);
	return $data;
}

function rgbstyle($r,$g,$b,$div)
{
# luminosity - see http://stackoverflow.com/questions/596216/formula-to-determine-brightness-of-rgb-color
	$lum=(0.2126*$r + 0.7152*$g + 0.0722*$b) / $div;
	return sprintf( "background-color:rgb(%d,%d,%d); color:%s",
		255*$r/$div, 255*$g/$div, 255*$b/$div,
		($lum<0.5) ? 'white' : 'black' );
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


/* User functions */

/** Current tester data */
$current_tester=array();

/** Query & cache current tester data */
function tester_get_current()
{
	global $current_tester,$auth;
	if( !$current_tester && $auth && $auth->hasIdentity() )	
		$current_tester=row_query('SELECT * FROM tester WHERE ext_ident=?','s',$auth->getIdentity());
	return $current_tester;
}

/** Look up user by his login */
function tester_get_by_login($tester)
{
	return row_query('SELECT * FROM tester WHERE tester=?','s',$tester);
}

/** Inserts new tester */
function tester_insert($tester,$ext_ident,$name,$email)
{
	return insert_query('INSERT INTO tester(tester,ext_ident,name,email) VALUES(?,?,?,?)','ssss',$tester,$ext_ident,$name,$email);
}

/** Delete existing tester */
function tester_delete($tester_id)	{
	return update_query('DELETE FROM tester WHERE tester_id=?','i',$tester_id);
}

/** Sets tester's details */
function tester_update($tester_id,$tester,$ext_ident,$name,$email)
{
	return update_query('UPDATE tester SET tester=?,ext_ident=?,name=?,email=? WHERE tester_id=?','sssss',$tester,$ext_ident,$name,$email,$tester_id);
}

/** Looks up current tester's numerical ID */
function tester_current_id()
{
	$tester = tester_get_current();
	return @$tester['tester_id'];
}

/** search / list testers */
function tester_search($attrs)	{
	$attrs_known = array(
		'tester_id'=>array('tester_id=?','i'),
		'tester'=>array('tester like ?','s'),
		'ext_ident'=>array('ext_ident like ?','s'),
		'name'=>array('name like ?','s'),
		'email'=>array('email like ?','s'),
		'is_admin'=>array('is_admin=?','i'),
		'is_confirmed'=>array('is_confirmed=?','i'),
	);
	return search_common(
		array('tester_id','tester','name','email','ext_ident','is_confirmed','is_admin'),
		'tester',
		$attrs,
		$attrs_known
	);
}

/** sets is_admin flag */
function tester_set_admin($tester_id,$is_admin)	{
	return update_query('UPDATE tester SET is_admin=? WHERE tester_id=?','ii',$is_admin,$tester_id);
}

/** sets is_confirmed flag */
function tester_set_confirmed($tester_id,$is_confirmed)	{
	return update_query('UPDATE tester SET is_confirmed=? WHERE tester_id=?','ii',$is_confirmed,$tester_id);
}

/** returns nonzero if current user is admin */
function is_admin()	{
	$tester = tester_get_current();
	return @$tester['is_admin'];
}

/** returns nonzero if current user is confirmed */
function is_confirmed()	{
	$tester = tester_get_current();
	return @$tester['is_confirmed'];
}


/** Lists last board entries. */
function board_list($header=1,$limit=null)
{	return mhash_query($header,$limit,'SELECT board_id,last_update,created_by,updated_by,topic FROM board ORDER BY last_update DESC');	}

/** Inserts a new board entry. */
function board_insert($topic)
{	return insert_query('INSERT INTO board(created_by,topic) VALUES(?,?)','is',tester_current_id(),$topic);	}

/** Gets just one topic from the board. */
function board_get_topic($board_id)
{	return scalar_query('SELECT topic FROM board WHERE board_id=?','i',$board_id);	}

/** Updates a board topic. */
function board_update($board_id,$topic)
{	return update_query('UPDATE board SET topic=?,updated_by=? WHERE board_id=?','ssi',$topic,tester_current_id(),$board_id);	}

/** Deletes a board topic. */
function board_delete($board_id)
{	return update_query('DELETE FROM board WHERE board_id=? LIMIT 1','i',$board_id);	}

/** Returns nonzero if there are new board messages since user's last visit. */
function board_last()
{
	$last = scalar_query('SELECT last FROM board_last WHERE tester_id=?','i',tester_current_id());
	if( !$last )	return 0;	# default for new board_last record for the current user
	return scalar_query('SELECT EXISTS(SELECT * FROM board WHERE last_update>? LIMIT 1)','s',$last);
}

/** Updates current user's last board access info in the table board_last. */
function board_update_last()
{	return update_query('INSERT INTO board_last(tester_id) VALUES(?) ON DUPLICATE KEY UPDATE last=NOW()','i',tester_current_id());	}


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
	array($dir.'index.php', 'Home'), 
	'log' => array(), 
	array($dir.'result.php', 'Results'), 
	array($dir.'submission.php', 'Submissions'), 
	array($dir.'regression.php', 'Regressions'), 
	array($dir.'waiver.php', 'Waiver'), 
	'board' => array($dir.'board.php', 'Board'),
	array($dir.'admin.php','Admin'),
#	array('trends.php', 'Trend Graphs'), 
#	array('bench/search.php', 'Benchmarks'), 
#	array(' ',' '), 
	array( array(
		array("http://qadb.suse.de/hamsta/", "De"),
		array("http://hamsta.qa.suse.cz/hamsta/", "Cz"),
		array("http://xen80.virt.lab.novell.com/hamsta/","Us"),
		array("http://147.2.207.30/hamsta/index.php","Cn"),
		), 'Hamsta:'),
	array($dir.'doc.php','Docs')); 

/** Connects to the database. Mostly called from common_header(), but you may need it independently. */
function do_db_connect()
{
	global $conn_id,$auth,$role;
	require('myconnect.inc.php');
	$conn_id=connect_to_mydb();
	/* We want to know user's role.
	   If the user has a role, we reconnect him with another permissions. */
	$role='';
	if( $conn_id && $auth && $auth->hasIdentity() )	{
		$role = ( is_admin() ? 'admin' : 'user' );
		disconnect_from_mydb();
		require('myconnect.inc.php');
		$conn_id=connect_to_mydb();
	}
}

/** logs into DB, checks user, prints header, prints navigation bar */
function common_header($args=null)
{
	global $glob_dest,$auth;
#	$is_production_server = ( $_SERVER['SERVER_ADDR'] == '10.10.3.155' );
	$defaults=array(
		'session'=>true,		# start sessions ?
		'connect'=>true,		# connect database ?
		'icon'=>'icons/qadb_ico.png',	# favicon
		'css_screen'=>'css/screen.css',	# CSS for screen
		'jquery'=>'true',		# load jquery ?
		'auth'=>'true',			# initialize openID ?
	);
	$args=args_defaults($args,$defaults);
	if( $args['session'] )	{
		if( $args['auth'] )
			Zend_Session::start();
		else # not using Zend in that case
			session_start();
	}
	if( $args['auth'] )
		$auth = Zend_Auth::getInstance();
	if( $args['connect'] )
		do_db_connect();
	print html_header($args);
	if( !hash_get($args,'embed',false,false) )
		print_nav_bar($glob_dest);
	if(isset($_SESSION['message']))
	{
		print html_message($_SESSION['message'], 'center '.@$_SESSION['mtype']);
		unset($_SESSION['message']);
		unset($_SESSION['mtype']);
	}
}



###############################################################################
# other functions

/**
  * Prints one-row table of submission details. 
  * @return array the used table data
  **/
function &print_submission_details( $submission_id, $print=true )
{
	$transl=array();
	$where=array('submission_id'=>$submission_id);
	$res=search_submission_result(1,$where,$transl);
	if( count($res)<2 )	{
		if ($print)
			print "No such submission_id: $submission_id<br/>\n";
	}
	else
	{
		if($res[1]['type']=='maint')
			$res=search_submission_result(2,$where,$transl);
		else if($res[1]['type']=='kotd')
			$res=search_submission_result(3,$where,$transl);
		$res2=$res; # need to return original values, unless $print is off
		table_translate($res2, $transl );
		if( !$print )
			return $res2;
		print html_table( $res2 );
	}
	return $res;
}

/**
  * Prints table comparison of multiple submissions
  * @param array $data array of submission details, returned e.g. by print_submission_details()
  * @param array $idnames additional info to submission IDs
  * @see print_submission_details
  **/
function submissions_compare_print( $data, $idnames=array() )
{
	if( empty($data) )
		return;

	# union of all column keys
	$merged=array();
	foreach( $data as $item )	{
		$merged=array_merge($merged,$item[0]);
	}
	foreach(array_keys($merged) as $key)	{

		# create union of unique values for that column
		$all_vals=array();
		foreach( $data as $id=>$item )	{
			if (array_key_exists($key,$item[1]))
				$all_vals[]=$item[1][$key];
		}
		$all_vals=array_unique($all_vals);

		# CSS classes for the columns
		$class[$key]=( count($all_vals) > 1 ? 'm' : 'small skipped' );
	}

	# print a table comparing the submissions
	print "<table class=\"tbl\">\n";
	foreach(array_keys($data) as $id)	{
		if( !isset($data[$id]) )
			continue;
		# submission header row
		$label='<h3>'.(empty($idnames[$id]) ? '': $idnames[$id].' ')."submission $id</h3>";
		print "\t<tr><td class=\"space\" colspan=\"".count($data[$id][0]).'">'.$label."</td></td>\n";

		# one submission details
		for( $i=0; $i<=1; $i++ )	{
			$tag=( $i ? 'td' : 'th' );
			print "\t<tr>";
			foreach($data[$id][$i] as $key=>$val)
				print html_tag($tag,$val,array('class'=>$class[$key]));
			print "</tr>\n";
		}
	}
	print "</table>\n";

}

/** Prints one-row table with TCF details. */
function &print_tcf_details($tcf_id)
{
	global $dir;
	$res=tcf_details($tcf_id,1);
	if( count($res)<2 )
		print "No such tcf_id: $tcf_id<br/>\n";
	else
	{
		$res2=$res; # preserve to return
		table_translate($res2,array(
			'links'=>array('tcf_id'=>$dir.'result.php?search=1&tcf_id='),
			'enums'=>array('testsuite_id'=>'testsuite'),
			'urls'=>array('log_url'=>'log')
		));
		print html_table($res2);
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
	global $conn_id,$dir,$auth;
	foreach( array_keys($dest) as $key )
	{
		if( is_numeric($key) ) continue;
		switch($key)
		{
			case 'log':
				if( $auth && $auth->hasIdentity() )
					$dest[$key]=array( $dir.'logout.php', "Logout");
				else
					$dest[$key]=array($dir.'login.php', "Login");
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
	global $dir;

	# links to logs
	$tcf_id_url=array();

	# add highlight, waiver info, links to logs
	for( $i=1; $i<count($data); $i++ )
	{
		# highlight
		$classes='';
		if( $data[$i]['succeeded'] ) $classes=' i';
		if( $data[$i]['skipped'] ) $classes=' skipped';
		if( $data[$i]['internal_error'] ) $classes=' internalerr';
		if( $data[$i]['failed'] ) $classes=' failed';

		# waivers
		$waiver_id=$data[$i]['waiver_id'];
		if( $waiver_id )
		{	# waiver exists
			$data[$i]['waiver']=html_text_button("show",$dir."waiver.php?view=vw&waiver_id=$waiver_id");
			$classes.=' w';
		}
		else
		{	# waiver does not exist
			$matchtype=($data[$i]['failed'] || $data[$i]['internal_error'] ? 'problem' : 'no+problem');
			$data[$i]['waiver']=html_user_button("create",$dir."waiver.php?view=nwd&detail=1&testcase=".$data[$i]['testcase_id'].'&arch='.$sub_info[1]['arch_id'].'&product='.$sub_info[1]['product_id'].'&release='.$sub_info[1]['release_id']."&matchtype=$matchtype");
		}
		unset($data[$i]['waiver_id']);

		# links to logs
		$my_tcf_id=$data[$i]['tcf_id'];
		if( !array_key_exists($my_tcf_id,$tcf_id_url) )
			$tcf_id_url[$my_tcf_id]=tcf_get_url($my_tcf_id);
		$url=$tcf_id_url[$my_tcf_id];
		$data[$i]['logs']=($url ? html_link('logs',$tcf_id_url[$my_tcf_id].'/'.$data[$i]['relative_url']) : '');
                #Display Graphs for benchmark results.
		if( $data[$i]['bench_count'] > 0 )
		{
			require_once($dir.'defs.php');
		        $graphlink=$dir."benchmarks.php?tests[]=".$my_tcf_id."&testcase=".$data[$i]['testcase']."&group_by=0&graph_x=".$bench_def_width."&graph_y=".$bench_def_height."&legend_pos=".$bench_def_pos."&font_size=".$bench_def_font."&search=1";
			$data[$i]['testcase']= html_link($data[$i]['testcase'],$graphlink);
		}
		else 
		{
			unset($data[$i]['bench_count']);
			unset($data[0]['bench_count']);
		}
		unset($data[$i]['testcase_id']);
		unset($data[$i]['relative_url']);

		# append highlight info at the end
		$data[$i][]=$classes;
	}
	# fix the header
	$data[0]['logs']='logs';
	$data[0]['waiver']='waiver';
	unset($data[0]['waiver_id']);
	unset($data[0]['testcase_id']);
	unset($data[0]['relative_url']);

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

# filter refence hosts
function reference_host_search($attrs,&$transl=array(),&$pager=null)
{
	global $dir;

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
	$transl['user_ctrls'] = array(
		'edit'=>$dir.'reference.php?step=edit&reference_host=',
		'delete'=>$dir.'confirm.php?confirm=rh&reference_host='
	);
	return search_common(
		array('reference_host_id','host_id','arch_id','product_id'),
		'reference_host',
		$attrs,
		$attrs_known,
		$pager
	);
}

# inserts reference host
function reference_host_insert($host_id,$arch_id,$product_id)	{
	return insert_query('INSERT INTO reference_host(host_id,arch_id,product_id) VALUES(?,?,?)', 'iii', $host_id, $arch_id, $product_id );
}

# deletes reference host
function reference_host_delete($reference_host_id)	{
	return update_query('DELETE FROM reference_host WHERE reference_host_id=?', 'i', $reference_host_id );
}

# function primarily intended for renaming enum values.
# NOTE: check if $table is a valid table before use!
function table_replace_value($table,$column,$oldval,$newval)	{
	return update_query("UPDATE `$table` SET `$column`=? WHERE `$column`=?",'ii',$newval,$oldval);
}

function html_user_button($text,$url,$title=null)
{
	global $auth;
	if( is_confirmed() )
		return html_text_button($text,$url,$title);
	else	{
		$title = ($title ? "$title\n" : '')."Not available unless you are logged in and confirmed.";
		return html_text_button_disabled($text,$title);
	}
}

function html_admin_button($text,$url,$title=null)
{
	if( is_admin() )
		return html_text_button($text,$url,$title);
	else	{
		$title = ($title ? "$title\n" : '')."Only available to admins.";
		return html_text_button_disabled($text,$title);
	}
}


?>
