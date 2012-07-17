<?php
require_once('qadb.php');

$arch_id=http('arch_id');
$product_id=http('product_id');
$build_nr=http('build_nr');
$release_id=http('release_id');

common_header(array('title'=>'Promote Buildxxx to officially release'));


$what=array(
        array('arch_id',enum_list_id_val('arch'),$arch_id,SINGLE_SELECT,'arch'),
        array('product_id',enum_list_id_val('product'),$product_id,SINGLE_SELECT,'product'),
        array('build_nr','',$build_nr,TEXT_ROW,'build_nr'),
	array('=>'),
        array('release_id',enum_list_id_val('release'),$release_id,SINGLE_SELECT,'release')
);
print html_search_form('promote.php',$what);

if(is_numeric(http('build_nr'))){
	list ($insert,$update) = insert_update_promoted($arch_id,$product_id,$build_nr,$release_id);
	if($insert > 0){
		 echo("$update recoders update");
	}else{
		echo("Insert failed");
	}
}

$filter[]=array('build_promoted_id','arch_id','product_id','build_nr','release_id');
foreach(list_promoted() as $r) $filter[]=$r;

print html_table($filter);

print html_footer();

?>
