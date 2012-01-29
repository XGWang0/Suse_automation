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
	'architectures'		=> array('archID','arch'),
	'products'		=> array('productID','product'),
	'releases'		=> array('releaseID','release'),
	'kernel_branches'	=> array('branchID','branch'),
	'kernel_flavors'	=> array('flavorID','flavor'),
	'testsuites'		=> array('testsuiteID','testsuite'),
	'testcases'		=> array('testcaseID','testcase'),
	'bench_parts'		=> array('partID','part'),
	'rpm_basenames'		=> array('basenameID','basename'),
	'rpm_versions'		=> array('versionID','version'),
	'rpmConfig'		=> array('configID','md5sum'),
	'hosts'			=> array('hostID','host'),
	'testers'		=> array('testerID','tester'),
	);


###############################################################################
# Misc utils

/** 
  * Tests if the given $waiverID applies to a given submission's arch/product/release.
  * @see print_submission_details()
  * @param array $s output of print_submission_detais()
  * @return int 0 for no waiver, 1 for partial match (testcase only), 2 for full match
  **/
function waiver_exact($waiverID,$s)
{
	return scalar_query('SELECT matchtype FROM waiver_testcase WHERE waiverID=? AND productID=? AND releaseID=? AND (archID=? OR archID IS NULL) ORDER BY archID DESC LIMIT 1','iiii',$waiverID,$s[1]['productID'],$s[1]['releaseID'],$s[1]['archID']);
/*
	1: exact match pozitivni na cand nebo ref -> o tomhle se vi
	2: exact match negativni na oba 

(red)	1: (testcase,product,release,arch match) & matchtype==1 -> regrese
(green)	2: (testcase,product,release,arch match) & matchtype==0 -> o tomhle se vi
	else
(yellow)3: (testcase match) -> mozna regrese, mozna ne - urcite vypsat, ale barevne odlisit od 100% nich regresi
	else
(red)	4: -> regrese

	pripad 2,3 - ma byt odkaz do waiver_data, u 1 mozna take
	moznost pridat aktualni testcase do waiveru (aspon u 3), moznost editovat/mazat stavaijci
	moznost pridat testcase do waiveru i bez regrese
*/
}

/** gets testcaseID, returns waiverID or null */
function waiver_get_id($testcaseID)
{	return scalar_query('SELECT waiverID FROM waiver_data WHERE testcaseID=?','i',$testcaseID);	}

/** Gets waiver_tcID, returns waiverID */
function waiver_get_master($waiver_tcID)
{	return scalar_query('SELECT waiverID FROM waiver_testcase WHERE waiver_tcID=?','i',$waiver_tcID);	}

/** creates a new waiver in waiver_data table */
function waiver_new($testcaseID=null,$bugID=null,$explanation='')
{	return insert_query('INSERT INTO waiver_data(testcaseID,bugID,explanation) VALUES(?,?,?)','iis',$testcaseID,$bugID,$explanation);	}

/** creates a new detail in waiver_testcase table */
function waiver_new_detail($waiverID, $productID, $releaseID, $archID, $matchtype)
{	return insert_query('INSERT INTO waiver_testcase(waiverID,productID,releaseID,archID,matchtype) VALUES(?,?,?,?,?)','iiiis',$waiverID,$productID,$releaseID,$archID,$matchtype);	}

/** deletes a waiver from waiver_data table */
function waiver_delete($waiverID)
{	return update_query('DELETE FROM waiver_data WHERE waiverID=?','i',$waiverID);	}

/** deletes a waiver detail */
function waiver_delete_detail($waiver_tcID)
{	return update_query('DELETE FROM waiver_testcase WHERE waiver_tcID=?','i',$waiver_tcID);	}

/** updates an existing waiver_data record */
function waiver_update($waiverID, $testcaseID, $bugID, $explanation)
{	return update_query('UPDATE waiver_data SET testcaseID=?,bugID=?,explanation=? WHERE waiverID=?','iisi',$testcaseID,$bugID,$explanation,$waiverID);	}

/** updates an existing waiver_testcase record */
function waiver_update_detail($waiver_tcID, $productID, $releaseID, $archID, $matchtype)
{	return update_query('UPDATE waiver_testcase SET productID=?,releaseID=?,archID=?,matchtype=? WHERE waiver_tcID=?','iiisi',$productID,$releaseID,$archID,$matchtype,$waiver_tcID);	}


/**
  * Searches waiver tables.
  * $mode: 
  *   0 waiver_data
  *   1 waiver_data + waiver_testcase
  *   2 waiver_testcase only
  * $attrs['only_id']: 
  *   0 for full details
  *   1 for IDs only 
  * $attrs['order_nr']: +/- (1+<index of the result column>)
  *   positive nr. means ascending order, negative means descending.
  *
  * NOTE: see search_submissions_results for similar code & more comments
  * @return array 2D array of results
  **/
function search_waiver($mode,$attrs)
{
	# supported arguments
	$attrs_known=array(
		'waiverID'=> array('d.waiverID=?','i'),
		'waiver_tcID'=>array('t.waiver_tcID=?','i'),
		'bugID'=>array('d.bugID=?','i'),
		'explanation'=>array('d.explanation like ?','s'),
		'productID'=>array('t.productID=?','i'),
		'releaseID'=>array('t.releaseID=?','i'),
		'testcaseID'=>array('d.testcaseID=?','i'),
		'archID'=>array('t.archID=?','i'),
		'matchtype'=>array('t.matchtype=?','i')
	);
	$only_id=hash_get($attrs,'only_id',false,true);
	# $sel0[ $mode ] - base attribute
	$sel0=array( 'd.waiverID', 't.waiver_tcID', 't.waiver_tcID' );
	# $sel1[ $mode ] - additional attributes for (!$only_id)
	$sel1=array(
		array('d.testcaseID','d.bugID','d.explanation'),
		array('d.testcaseID','d.waiverID','t.productID','t.releaseID','t.archID','t.matchtype'),
		array('t.productID','t.releaseID','t.archID','t.matchtype')
	);
	# $from0[ $mode ] - tables to select from
	$from0=array('waiver_data d','waiver_data d JOIN waiver_testcase t USING(waiverID)');
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
function get_bench_number($resultsID,$partID)
{	return scalar_query('SELECT result FROM bench_data WHERE resultsID=? AND partID=?','ii',$resultsID,$partID);	}

/** Gets keys and bench numbers for a given resultsID */
function get_bench_numbers($resultsID,$limit=null)
{	return matrix_query(0,$limit,'SELECT partID,result FROM bench_data WHERE resultsID=?','i',$resultsID);	}

/** Lists all testsuites that contain benchmark data. Uses the statistical table 'tests'. */
function bench_list_testsuites($limit=null)
{	return matrix_query(0,$limit,'SELECT DISTINCT testsuiteID,testsuite FROM tests JOIN testsuites USING(testsuiteID) WHERE is_bench ORDER BY testsuite');	}


/** searches for submissions, testsuites, or results
  * $mode :
  *   0 results
  *   1 just submissions
  *   2 maintenance
  *   3 KOTD
  *   4 product
  *   5 any
  *   6 testsuites
  *   7 trend graphs
  *   8 submissions + TCF
  *   9 bench search
  *  10 submissions + TCF + testcases
  *  11 summaries
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
function search_submissions_results($mode, $attrs, &$transl=null, &$pager=null)
{
	# base SQL for result difference
	$rd1='NOT EXISTS( SELECT * FROM results r2 JOIN tcf_group g2 USING(tcfID) WHERE';
	$rd2='AND r.testcaseID=r2.testcaseID)';
	# supported arguments
	$attrs_known=array(
		'date_from'	=> array('s.submission_date>=?',	's'),
		'date_to'	=> array('s.submission_date<=?',	's'),
		'hostID'	=> array('s.hostID=?',			'i'),
		'testerID'	=> array('s.testerID=?',		'i'),
		'archID'	=> array('s.archID=?',			'i'),
		'productID'	=> array('s.productID=?',		'i'),
		'releaseID'	=> array('s.releaseID=?',		'i'),
		'active'	=> array('s.active=?',			'i'),
		'testsuiteID'   => array('g.testsuiteID=?',		'i'),
		'testcaseID'	=> array('r.testcaseID=?',		'i'),
		'testcase'	=> array('c.testcase like ?',	's'),
		'tcfID'		=> array('r.tcfID=?',			'i'),
		'submissionID'	=> array('s.submissionID=?',		'i'),
		'configID'	=> array('s.configID=?',		'i'),
		'hwinfoID'	=> array('s.hwinfoID=?',		'i'),
		'comment'	=> array('s.comment like ?',		's'),
		# testcase differences - only for result search
		'res_minus_sub'	=> array("$rd1 g2.submissionID=? $rd2",	'i'),
		'res_minus_tcf'	=> array("$rd1 g2.tcfID=? $rd2",	'i'),
	);

	# index into $sel0[], $sel1[] (SELECT ...), and $from0[] (FROM ...)
	$i_main = array( 1,0,0,0,0,0,2,0,0,0,0 );
	# index into $sel2[] (SELECT ...)
	$i_next = array( 0,0,1,2,0,3,0,4,5,5,6 );
	# index into $from2[] (FROM ...)
	$i_from = array( 0,0,1,2,3,4,0,0,5,6,7 );
	# index into $links2[] ( $transl->['links'] )
	$i_link = array( 0,0,0,1,0,0,0,0,2,2,2 );

	# should I return submissionID only?
	$only_id  = hash_get($attrs,'only_id',false,true);

	# skip the header?
	$header = hash_get($attrs,'header',true,false);

	# SELECT $sel FROM $from
	# $sel = $sel0 [ $sel1 ] [ $sel2 ]
	# $from = $from0 $from2
	# $sel0..$sel2 are done as lists - for ordering by them
	# $sel0[ $i_main ] -- always
	$sel0=array( 's.submissionID', 'r.resultsID', 'g.testsuiteID' );
	# $sel1[ $i_main ] -- appends for full details
	$sel1=array( 
/* subms */  array('s.submission_date','s.hostID','s.testerID','s.archID','s.productID','s.releaseID','s.active','s.related','s.comment','s.configID','s.hwinfoID','s.type'),
/* rslts */  array('g.tcfID','g.testsuiteID','r.testcaseID','t.testcase','r.succeeded','r.failed','r.internal_error','r.skipped','r.times_run','r.test_time','w.waiverID','t.relative_url'),
/* suite */  array(),
/* sums  */  array('SUM(r.testcases) as testcases','SUM(r.succeeded) as succeeded','SUM(r.failed) as failed','SUM(r.internal_error) as internal_error','SUM(r.skipped) as skipped','SUM(r.times_run) as times_run','SUM(r.test_time) as test_time')
	);
	# $sel2[ $i_next ] -- appends for full details
	$sel2=array( 
/* simple */ array(),
/* mtnce  */ array('m.patchID','m.md5sum','m.status'),
/* KOTD   */ array('k.release','k.version','k.branchID','k.flavorID'),
/* any    */ array('m.patchID','m.md5sum','m.status'),
/* trend  */ array('g.testsuiteID'),
/* TCF    */ array('g.testsuiteID','g.tcfID'),
/* TCF+res*/ array('g.testsuiteID','g.tcfID','r.testcaseID'),
	);

	# $from0[ $i_main ] -- always
	$from0=array( 'submissions s', 'submissions s JOIN tcf_group g USING(submissionID) JOIN results r USING(tcfID)', 'submissions s JOIN tcf_group g USING(submissionID)' );
	# $from1[ $i_main ] -- append for full details
	$from1=array( '', ' JOIN testcases t USING(testcaseID) LEFT OUTER JOIN waiver_data w USING(testcaseID)', '' );
	# $from2[ $i_from ] -- always
	$from2=array(
/* simple */	'',
/* mtnce  */	' JOIN maintenance_testing m USING(submissionID)',
/* KOTD   */	' JOIN kotd_testing k USING(submissionID)',
/* prod   */	' JOIN product_testing p USING(submissionID)',
/* any    */	' LEFT JOIN kotd_testing k USING(submissionID) LEFT JOIN maintenance_testing m USING(submissionID) LEFT JOIN product_testing p USING(submissionID)',
/* TCF    */    ' JOIN tcf_group g USING(submissionID)',
/* bench  */	' JOIN tcf_group g USING(submissionID) JOIN bench_suites b USING(testsuiteID)',
/* TCF+res*/	' JOIN tcf_group g USING(submissionID) JOIN results r USING(tcfID) JOIN testcases c USING(testcaseID)',
	);
	
	# $enum1[ $i_main ] - for full details when $transl set
	$enum1=array(
/* subms */  array('hostID'=>'hosts','testerID'=>'testers','archID'=>'architectures','productID'=>'products','releaseID'=>'releases'),
/* rslts */  array('testsuiteID'=>'testsuites'),
/* suite */  array()
	);

	# $enum1[ $i_next ] - for full details when $transl set
	$enum2=array(
/* simple */	array(),
/* mtnce  */	array(),
/* KOTD   */	array('branchID'=>'kernel_branches','flavorID'=>'kernel_flavors'),
/* prod   */	array(),
/* any    */	array(),
/* TCF    */	array('testsuiteID'=>'testsuites'),
/* bench  */	array('testsuiteID'=>'testsuites'),
/* TCF+res*/	array('testsuiteID'=>'testsuites','testcaseID'=>'testcases')
	);

	# $links1[ $i_main ] - for full details when $transl set
	$links1=array(
/* subms */	array('submissionID'=>'submission.php?submissionID=','related'=>'submission.php?submissionID=','configID'=>'rpms.php?configID=','hwinfoID'=>'hwinfo.php?hwinfoID='),
/* rslts */	array('tcfID'=>'results.php?tcfID='),
/* suite */	array()
	);

	# $links2[ $i_link ] - for full details when $transl set
	$links2=array(	
		array(), 
/* KOTD */	array('release'=>'http://kerncvs.suse.de/gitweb/?p=kernel-source.git;a=commit;h='), 
/* TCF data */	array('tcfID'=>'results.php?tcfID=') 
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
	$data=search_common( $sel, $from, $attrs, $attrs_known, $pager );
	if( $mode==2 ) # maintenance - append RPM lists
		$data=append_maintenance($data,$header);
	return $data;
}

function get_maintenance_rpms($submissionID)
{
	$data=matrix_query(0,null,"SELECT b.basename,v.version FROM released_rpms r join rpm_basenames b on (r.basenameID=b.basenameID) left outer join rpm_versions v on (r.versionID=v.versionID) WHERE r.submissionID=?",'i',$submissionID);
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
		$data[$i]['rpms'] = get_maintenance_rpms($data[$i]['submissionID']);
	return $data;
}

function result_stats($submissionID,$testcaseID)
{
	return row_query(null,'SELECT count(*),sum(succeeded),sum(failed),sum(internal_error),sum(skipped) FROM results r,tcf_group g WHERE r.tcfID=g.tcfID AND g.submissionID=? AND r.testcaseID=?','ii',$submissionID,$testcaseID);
}

function regression_differences($attrs,&$pager=null)
{
	# This is ugly, but comparing submissions of 100k testcases was no longer possible in PHP
	# What happens here: 
	# we link candidate and reference data using testcaseID
	# on-the-fly we compute status succ(s), fail(f), interr(i) or skipped(S) for both
	# we filter out testcases with the same status
	#
	# As the status is auto-generated, MySQL seems only able to filter it in an outside SELECT
	# We use search_common() to select proper data and generate SQL
	# then we add the outer SELECT with filtering out testcases with the same status
	
	# ugly hack: the first two columns are separated so that we can order by index 2, the others not
	$sel=array("c.testcaseID","testcase",
		"GROUP_CONCAT(CASE WHEN tr.logs_url IS NULL THEN sr.testsuite ELSE CONCAT('<a href=\"',tr.logs_url,'/',relative_url,'\">',sr.testsuite,'</a>') END) AS r_testsuites, 
			SUM(r.succeeded) AS r_succ, 
			SUM(r.failed) AS r_fail, 
			SUM(r.internal_error) AS r_interr, 
			SUM(r.skipped) AS r_skip, 
			(CASE WHEN r.failed>0 THEN 'f' WHEN r.internal_error>0 THEN 'i' WHEN r.skipped>0 THEN 'S' WHEN r.succeeded>0 THEN 's' ELSE 'i' END) AS r_state,
		 GROUP_CONCAT(CASE WHEN tc.logs_url IS NULL THEN sc.testsuite ELSE CONCAT('<a href=\"',tc.logs_url,'/',relative_url,'\">',sc.testsuite,'</a>') END) AS c_testsuites, 
		 	SUM(c.succeeded) AS c_succ, 
		 	SUM(c.failed) AS c_fail, 
			SUM(c.internal_error) AS c_interr, 
			SUM(c.skipped) AS c_skip, 
			(CASE WHEN c.failed>0 THEN 'f' WHEN c.internal_error>0 THEN 'i' WHEN c.skipped>0 THEN 'S' WHEN c.succeeded>0 THEN 's' ELSE 'i' END) AS c_state,
		waiverID
	");
	$from="results c JOIN tcf_group tc USING(tcfID) JOIN testsuites sc USING(testsuiteID) JOIN testcases ss USING(testcaseID), results r JOIN tcf_group tr USING(tcfID) JOIN testsuites sr USING(testsuiteID) LEFT OUTER JOIN waiver_data USING(testcaseID)";
	$where="c.testcaseID=r.testcaseID";

	# attributes
	$attrs_known=array(
		'cand_submissionID'	=> array('tc.submissionID=?','i'),
		'ref_submissionID'	=> array('tr.submissionID=?','i'),
		'cand_tcfID'		=> array('c.tcfID=?','i'),
		'ref_tcfID'		=> array('r.tcfID=?','i')
	);

	# check that both cand/ref are specified, would block DB otherwise
	if(!(	(isset($attrs['cand_submissionID']) || isset($attrs['cand_tcfID'])) &&
		(isset($attrs['ref_submissionID'])  || isset($attrs['ref_tcfID'] )) ))
		die("Called regression_difference() without specifying cand/ref, would block DB");

	# other query settings
	$attrs['just_sql']=true;
	$attrs['where']=$where;
	$attrs['order_nr']=2;
	$attrs['group_by']='c.testcaseID';
	
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
# API for submissions, configuration, comments etc.

function submission_set_details($submissionID, $active, $related, $comment)
{	return update_query('UPDATE submissions SET active=?,related=?,comment=? WHERE submissionID=?','iisi',$active,$related,$comment,$submissionID);	}

/**  gets ID of related submission or null */
function submission_get_related($submissionID)
{	return scalar_query('SELECT related FROM submissions WHERE submissionID=?','i',$submissionID);	}

/*  sets ID of a related submission */
#function set_related_submission($submissionID, $relatedID)
#{	return update_query('UPDATE submissions SET related=? WHERE submissionID=?','ii',$relatedID,$submissionID);	}

/*  gets a comment from the submissions table */
#function get_comment($submissionID)
#{	return scalar_query('SELECT comment FROM submissions WHERE submissionID=?','i',$submissionID);	}

/*  sets a comment in the submission table */
#function set_comment($submissionID, $comment)
#{	return update_query('UPDATE submissions SET comment=? WHERE submissionID=?','si',$comment,$submissionID);	}

/**  gets hwinfo */
function hwinfo_get($hwinfoID)
{
	$data=scalar_query('SELECT hwinfo_bz2 FROM hwinfo WHERE hwinfoID=?','i',$hwinfoID);
	if( $data )
		$data=bzdecompress($data);
	return $data;
}

/** gets submission's hwinfoID */
function submission_get_hwinfoID($submissionID)
{	return scalar_query('SELECT hwinfoID FROM submissions WHERE submissionID=?','i',$submissionID);	}

/** Deletes the whole submission. Triggers will delete the details. */
function submission_delete($submissionID)
{	return update_query('DELETE FROM submissions WHERE submissionID=?','i',$submissionID);	}

/** 
  * Fetches TCF details and results stats for either a $submissionID or a tcfID.
  * @param int $type 0 for submissionID, 1 for tcfID
  * @param int $ID either submissionID or tcfID
  **/
function tcf_details($ID,$type,$header=1,$limit=null)
{
	return mhash_query($header,$limit,'SELECT g.tcfID,g.testsuiteID,COUNT(r.testcaseID) as testcases,SUM(r.succeeded) as succeeded,SUM(r.failed) as failed,SUM(r.internal_error) as internal_error,SUM(r.skipped) as skipped, SUM(r.times_run) as times_run,SUM(test_time) as test_time,g.logs_url FROM tcf_group g LEFT OUTER JOIN results r USING(tcfID) WHERE g.'.($type ? 'tcf':'submission').'ID=? GROUP BY g.tcfID','i',$ID);
}

/** deletes all TCFs for a submissionID and testcaseID */
function tcf_delete($submissionID, $tcfID)
{	return update_query('DELETE FROM tcf_group WHERE submissionID=? AND tcfID=?','ii',$submissionID,$tcfID);	}

/** Returns a submissionID for a tcfID */
function tcf_get_submission($tcfID)
{	return scalar_query('SELECT submissionID FROM tcf_group WHERE tcfID=? LIMIT 1','i',$tcfID);	}

/** Sets a URL link to test logs */
function tcf_set_url($tcfID,$url)
{	return update_query('UPDATE tcf_group SET logs_url=? WHERE tcfID=?','si',$url,$tcfID);	}

/** Returns URL to test logs */
function tcf_get_url($tcfID)
{	return scalar_query('SELECT logs_url FROM tcf_group WHERE tcfID=?','i',$tcfID);	}

function testcases_get_relative_url($testcaseID)
{	return scalar_query('SELECT relative_url FROM testcases WHERE testcaseID=?','i',$testcaseID);	}


/** Creates or finds current user's numerical ID in the table 'testers' */
function get_userID()
{
	global $mysqluser;
	return enum_get_id_or_insert('testers',$mysqluser);
}

/** Lists last board entries. */
function board_list($header=1,$limit=null)
{	return mhash_query($header,$limit,'SELECT boardID,last_update,created_by,updated_by,topic FROM board ORDER BY last_update DESC');	}

/** Inserts a new board entry. */
function board_insert($topic)
{	return insert_query('INSERT INTO board(created_by,topic) VALUES(?,?)','is',get_userID(),$topic);	}

/** Gets just one topic from the board. */
function board_get_topic($boardID)
{	return scalar_query('SELECT topic FROM board WHERE boardID=?','i',$boardID);	}

/** Updates a board topic. */
function board_update($boardID,$topic)
{	return update_query('UPDATE board SET topic=?,updated_by=? WHERE boardID=?','ssi',$topic,get_userID(),$boardID);	}

/** Deletes a board topic. */
function board_delete($boardID)
{	return update_query('DELETE FROM board WHERE boardID=? LIMIT 1','i',$boardID);	}

/** Returns nonzero if there are new board messages since user's last visit. */
function board_last()
{
	$last = scalar_query('SELECT last FROM board_last WHERE testerID=?','i',get_userID());
	if( !$last )	return 0;	# default for new board_last record for the current user
	return scalar_query('SELECT EXISTS(SELECT * FROM board WHERE last_update>? LIMIT 1)','s',$last);
}

/** Updates current user's last board access info in the table board_last. */
function board_update_last()
{	return update_query('INSERT INTO board_last(testerID) VALUES(?) ON DUPLICATE KEY UPDATE last=NOW()','i',get_userID());	}


/** Gets a description text for a given database table. */
function table_description($table)
{	return scalar_query('SELECT `desc` FROM table_desc WHERE `table`=? LIMIT 1','s',$table);	}

###############################################################################
# API for RPM configurations
# minimalistic (rest done by import script) - expand when needed

/** gets configID from submissions */
function get_configID($tcfID)
{	return scalar_query('SELECT configID FROM tcf_group WHERE tcfID=?','i',$tcfID);	}

/** gets basenames and versions for a given configID, returns table with 2 columns */
function rpms_fetch($configID,$header=1,$limit=null)
{	
	return matrix_query($header,$limit,"SELECT basename, version FROM softwareConfig JOIN rpms USING(rpmID) JOIN rpm_basenames USING(basenameID) JOIN rpm_versions USING(versionID) WHERE configID=? ORDER BY basename,version",'i',$configID);	
}

/** 
 * compares two or more configurations, returns versions that don't exist in other ones
 * usage: diff_rpms( $configID, $configID2, ... )
 **/
function rpms_diff($limit,$all,$configIDs) 
{
	$sql_args=array(); # SQL args for prepared statement
	$select='basename';
	$from='softwareConfig c JOIN rpms r USING(rpmID) JOIN rpm_basenames USING(basenameID) JOIN rpm_versions USING(versionID)';
	$where2=array(); # 'c<n>.rpmID is null' conditions
	$cnt=count($configIDs);
	for($i=0; $i<$cnt; $i++)	{
		$configID=$configIDs[$i];
		$select .= ", GROUP_CONCAT(DISTINCT IF(c$i.rpmID,version,NULL) SEPARATOR '<br/>') AS '$configID'";
		$from .= " LEFT OUTER JOIN softwareConfig c$i ON(r.rpmID=c$i.rpmID and c$i.configID=?) ";
		$where2[] = "c$i.rpmID IS NULL";
		$sql_args[] = $configID;
	}
	$where = "c.configID IN (".join( ',', array_fill(0,$cnt,'?') ).')';
	if( !$all )
		$where .= " AND (".join(' OR ', $where2 ).")";
	$sql = "SELECT $select FROM $from WHERE $where GROUP BY basename";
	$call = array(1,$limit,$sql,str_repeat('i',2*$cnt));
	return call_user_func_array('mhash_query',array_merge($call,$sql_args,$sql_args));
/*	Original query that supported only two configIDs was:
	return matrix_query(1,$limit,
		"SELECT basename, ".
			"GROUP_CONCAT(IF(c1.rpmID,version,NULL) SEPARATOR '<br/>') AS 'v. $configID1', ".
			"GROUP_CONCAT(IF(c2.rpmID,version,NULL) SEPARATOR '<br/>') AS 'v. $configID2'".
		"FROM softwareConfig c JOIN rpms r USING(rpmID) ".
			"JOIN rpm_basenames USING(basenameID) JOIN rpm_versions USING(versionID) ".
			"LEFT OUTER JOIN softwareConfig c1 ON(r.rpmID=c1.rpmID and c1.configID=?) ".
			"LEFT OUTER JOIN softwareConfig c2 ON(r.rpmID=c2.rpmID and c2.configID=?) ".
		"WHERE c.configID in (?,?) AND (c1.rpmID IS NULL OR c2.rpmID IS NULL) ".
		"GROUP BY basename","iiii",$configID1,$configID2,$configID1,$configID2);*/
}

/** returns the number of RPMs in a given configID */
function rpms_num($configID)
{
	return scalar_query('SELECT COUNT(*) FROM softwareConfig WHERE configID=?','i',$configID);
}

$glob_dest=array( 
	array("index.php", "Home"), 
	'log' => array(), 
	array("results.php", "Results"), 
	array("submission.php", "Submissions"), 
	array("regression.php", "Regressions"), 
	array("waiver.php", "Waiver"), 
	'board' => array("board.php", "Board"),
#	array("trends.php", "Trend Graphs"), 
#	array("bench/search.php", 'Benchmarks'), 
#	array(" "," "), 
	array( array(
		array("http://qadb.suse.de/hamsta/", "De"),
		array("http://hamsta.qa.suse.cz/hamsta/", "Cz"),
		array("http://151.155.248.99/hamsta/","Us"),
		array("http://147.2.207.30/hamsta/index.php","Cn"),
		), 'Hamsta'),
	array("doc.php","Docs")); 

/** logs into DB, checks user, prints header, prints navigation bar */
function common_header($args=null)
{
	global $connID,$glob_dest;
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
		$connID=connect_to_mydb();
	print html_header($args);
	print_nav_bar($glob_dest);
}



###############################################################################
# other functions

/**
  * Prints one-row table of submission details. 
  * @return array the used table data
  **/
function &print_submission_details($submissionID)
{
	$transl=array();
	$where=array('submissionID'=>$submissionID);
	$res=search_submissions_results(1,$where,$transl);
	if( count($res)<2 )
		print "No such submissionID: $submissionID<br/>\n";
	else
	{
		if($res[1]['type']=='maint')
			$res=search_submissions_results(2,$where,$transl);
		else if($res[1]['type']=='kotd')
			$res=search_submissions_results(3,$where,$transl);
		$res2=$res; # need to return original values
		table_translate($res2, $transl );
		print html_table( $res2, null, null );
	}
	return $res;
}

/** Prints one-row table with TCF details. */
function &print_tcf_details($tcfID)
{
	$res=tcf_details($tcfID,1);
	if( count($res)<2 )
		print "No such tcfID: $tcfID<br/>\n";
	else
	{
		$res2=$res; # preserve to return
		table_translate($res2,array(
			'links'=>array('tcfID'=>'results.php?search=1&tcfID='),
			'enums'=>array('testsuiteID'=>'testsuites'),
			'urls'=>array('logs_url'=>'logs')
		));
		print html_table($res2,null,null);
	}
	return $res;
}

/** returns newest and oldest allowed version of a script, or for all known scripts */
function get_script_versions($name=null)
{
	$base="SELECT script_name, CONCAT(latest_major,'.',latest_minor), CONCAT(minimal_major,'.',minimal_minor) FROM script_versions";
	if( $name )
		return matrix_query(0,null,"$base WHERE script_name=?",'s',$name);
	else
		return matrix_query(0,null,$base);
}

/** converts dynamical menu items, prints the menu */
function print_nav_bar($dest)
{
	global $connID;
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
				if( $connID && board_last() )
					$dest[$key][1]='<span class="board_new">'.$dest[$key][1].'</span>';
				break;
		}
	}
	print nav_bar($dest);
}

# process results table before printing
# $sub_info is output from print_submission_details()
# $data should contain fields: '
function results_process_print(&$data,$sub_info,$transl,$pager,$id)
{
	# links to logs
	$tcfID_url=array();

	# add highlight, waiver info, links to logs
	for( $i=1; $i<count($data); $i++ )
	{
		# highlight
		$classes='';
		if( $data[$i]['skipped'] ) $classes=' skipped';
		if( $data[$i]['internal_error'] ) $classes=' internalerr';
		if( $data[$i]['failed'] ) $classes=' failed';

		# waivers
		$waiverID=$data[$i]['waiverID'];
		if( $waiverID )
		{	# waiver exists
			$data[$i]['waiver']=html_text_button("show","waiver.php?view=view_waiver&waiverID=$waiverID");
			$classes.=' w';
		}
		else
		{	# waiver does not exist
			$matchtype=($data[$i]['failed'] || $data[$i]['internal_error'] ? 'problem' : 'no+problem');
			$data[$i]['waiver']=html_text_button("create","waiver.php?view=new_both&detail=1&testcases=".$data[$i]['testcaseID'].'&architectures='.$sub_info[1]['archID'].'&products='.$sub_info[1]['productID'].'&releases='.$sub_info[1]['releaseID']."&matchtype=$matchtype");
		}
		unset($data[$i]['waiverID']);

		# links to logs
		$my_tcfID=$data[$i]['tcfID'];
		if( !array_key_exists($my_tcfID,$tcfID_url) )
			$tcfID_url[$my_tcfID]=tcf_get_url($my_tcfID);
		$url=$tcfID_url[$my_tcfID];
		$data[$i]['logs']=($url ? html_link('logs',$tcfID_url[$my_tcfID].'/'.$data[$i]['relative_url']) : '');

		unset($data[$i]['testcaseID']);
		unset($data[$i]['relative_url']);

		# append highlight info at the end
		$data[$i][]=$classes;
	}
	# fix the header
	$data[0]['logs']='logs';
	$data[0]['waiver']='waiver';
	unset($data[0]['waiverID']);
	unset($data[0]['testcaseID']);
	unset($data[0]['relative_url']);

	table_translate( $data, $transl );
	print html_table( $data, array('callback'=>'highlight_results','id'=>$id,'sort'=>'iissiiiiiiss','pager'=>$pager,'total'=>1));
}

# DB schema last update
function schema_get_version()
{	return scalar_query('SELECT version FROM `schema` LIMIT 1');	}

# standard highlight function - returns last column (to be used as class)
function highlight_results()
{	# return last nonprintable column of the table
	global $data;
	$row=func_get_args();
	return $row[count($row)-1];
}


?>
