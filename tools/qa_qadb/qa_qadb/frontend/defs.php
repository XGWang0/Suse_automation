<?php

$bench_def_width  = 800;
$bench_def_height = 600;
$bench_def_pos    = 0;
$bench_def_font   = 1;

$cookies = array( 'graph_x', 'graph_y', 'legend_pos', 'font_size' );

$group_by = array(
	array( 0, 'testsuite, host, product, release', 't.testsuite,h.host,pr.product,rel.release' ),
	array( 1, 'testsuite, host, product', 't.testsuite,h.host,pr.product' ),
	array( 2, 'testsuite, host', 't.testsuite,h.host' ),
	array( 3, 'testsuite, submission_id', 't.testsuite,s.submission_id' ),
	array( 4, 'product, release, submission_id, comment', 'pr.product,rel.release,s.submission_id,s.comment' ),
	array(  5, 'testcase, testsuite, host, product, release', 'tc.testcase,t.testsuite,h.host,pr.product,rel.release' ),
	array(  6, 'testcase, testsuite, host, product', 'tc.testcase,t.testsuite,h.host,pr.product' ),
	array(  7, 'testcase, testsuite, host', 'tc.testcase,t.testsuite,h.host' ),
	array(  8, 'testcase, testsuite, submission_id', 'tc.testcase,t.testsuite,s.submission_id' ),

	array(  9, 'testcase', 'tg.tcf_id' ),
	array( 10, 'testcase, tcf_id', 'tc.testcase,tg.tcf_id' ),
);

?>
