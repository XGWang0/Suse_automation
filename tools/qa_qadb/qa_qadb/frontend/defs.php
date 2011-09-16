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
	array( 3, 'testsuite, submissionID', 't.testsuite,s.submissionID' ),
	array( 4, 'product, release, submissionID, comment', 'pr.product,rel.release,s.submissionID,s.comment' ),
	array( 5, 'tcfID', 'tg.tcfID' ),
);

?>
