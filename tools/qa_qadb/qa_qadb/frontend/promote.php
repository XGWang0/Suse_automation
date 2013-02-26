<?php
require_once('qadb.php');

$arch_got=http('arch_id');
$product_got=http('product_id');
$build_nr_got=http('build_nr');
$release_got=http('release_id');
$build_promoted_got=http('build_promoted_id');
$submit=http('submit');
$wtoken=http('wtoken');

common_header(array('title'=>'Promote Buildxxx to officially release'));

if(token_read($wtoken))	{
	if( $submit=='insert' && $build_nr_got )	{
		transaction();
		list ($insert,$update) = build_promoted_insert_update($arch_got,$product_got,$build_nr_got,$release_got);
		update_result($insert,1);
		update_result($update);
		commit();
	}
	else if( $submit=='delete_prom' && $build_promoted_got )	{
		transaction();
		update_result( build_promoted_delete($build_promoted_got) );
		commit();
	}
}

$what=array(
        array('arch_id',enum_list_id_val('arch'),$arch_got,SINGLE_SELECT,'arch'),
        array('product_id',enum_list_id_val('product'),$product_got,SINGLE_SELECT,'product'),
        array('build_nr','',$build_nr_got,TEXT_ROW,'Build Nr. *'),
	array('=>','','',TEXT),
	array('release_id',enum_list_id_val('release'),$release_got,SINGLE_SELECT,'release'),
	array('submit','','insert',HIDDEN),
	array('wtoken','',token_generate(),HIDDEN),
);

print html_search_form('promote.php',$what);

$data = build_promoted_list();
table_translate($data, array(
	'ctrls'=>array( 'delete' => 'confirm.php?confirm=pr&build_promoted_id=' ),
));
$data[0][0]='ID';
print html_table($data, array());


print html_footer();

?>
