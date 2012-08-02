<?php

require_once('qadb.php');
common_header(array(
    'connect'=>false,
    'title'=>'QADB documentation pages'
));

$data = array(
	'User documentation' => array(
#		html_link('Architecture overview','doc/qadb_architecture/index.html','Basic orientation in QADB'),
		html_link('Using the web frontend','doc/qadb_web_usage/index.html','QADB web interface overview'),
		html_link('Frontend presentation','doc/qadb_web_demonstration/demonstration.html','Flash that demonstrates how to use the frontend'),
	),
	'Manual pages for qa_tools package' => array(
		html_link('qa_db_report.pl','doc/qa_db_report.pl.1.html','QADB submission tool'),
		html_link('select_db.pl','doc/select_db.pl.1.html','tool to select QADB instance'),
		html_link('product.pl','doc/product.pl.1.html','product guesser'),
		html_link('~/.mysql_loc.rc','doc/mysql_loc.rc.5.html','client-side MySQL instance configuration'),
	),
	'Programming documentation' => array(
		html_link('qadb.pm','doc/qadb_api/index.html','QADB-specific DB functions'),
		html_link('TBlib','../tblib/doc/tblib_api/index.html','database and HTML toolkit'),
		html_link('TBlib usage','../tblib/doc/tblib_usage/index.html','using the TBlib - database and HTML toolkit'),
		html_link('DB tables (semi-generated)','tbldoc.php'),
#		html_link('DB tables','doc/qadb_new.html','Description of the database tables'),
#		html_link('DB tables (old)','doc/qadb_old.html','Description of the original QADB tables'),
#		html_link('Implemented changes','http://hamsta.qa.suse.cz/new_qadb.html','Describing the implemented changes since the original version'),
	),

);

print '<div class="list">'."\n";

foreach( $data as $section => $list )
{
	print "<h3>$section</h3>\n";
	print join("<br/>\n",$list);
}
print "</div>\n";

print html_footer();
?>
