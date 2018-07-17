<?php

require_once('qadb.php');
common_header(array(
	'connect'=>false,
	'title'=>'QADB administration tools'
));

$data=array(
	html_link('View / edit reference hosts','reference.php','Reference hosts are hosts selected to do reference testing on specific products. Here you can define them.'),
	html_link('BuildNumber &rarr; Release mapping','promote.php','Maintaining a list of what BuildNr. on what architecture belongs to what release'),
	html_link('Viev / edit QADB enum types','enums.php','Administration of different lists - products, releases, hosts ....'),
	html_link('Users / permissions','users.php','Setting user permissions'),
);

print "<h3>Administration tools</h3>\n";
print html_div('list',join("<br/>\n",$data));
print html_footer();
?>
