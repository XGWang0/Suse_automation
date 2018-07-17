<?php
require_once('qadb.php');
common_header(array(
	'title'=>'Promote hosts and submissions',
	'id'=>'promote_html'
));

$step=http('step','search');

$steps = array(
	'search'=>'search hosts',
);
if( is_admin() )
	$steps['new']='new host';
$steps_alt = array('edit'=>'edit host');
print steps('?step=',$steps,$step,$steps_alt);

$host_got = http('host');
$arch_got = http('arch');
$product_got = http('product');
$reference_host_got = http('reference_host');
$submit = http('submit');

if( token_read(http('wtoken')) )	{
	if( !is_admin() )	{
		print html_error("Only admin may do this");
	}
	else if( $submit=='insert' && $host_got && $arch_got && $product_got )	{
		transaction();
		update_result( reference_host_insert($host_got,$arch_got,$product_got), 1 );
		commit();
	}
	else if( $submit=='delete_ref' && $reference_host_got )	{
		transaction();
		update_result( reference_host_delete($reference_host_got) );
		commit();
	}
	$host_got=$arch_got=$product_got=$reference_host_got=null;
}
else if( $reference_host_got )	{
	if( $detail = reference_host_search(
		array('reference_host_id'=>$reference_host_got),
		$transl
	))	{
		$host_got    = $detail[1]['host_id'];
		$arch_got    = $detail[1]['arch_id'];
		$product_got = $detail[1]['product_id'];
		table_translate($detail,$transl);
	}

}



$type = ($step=='search' ? MULTI_SELECT : SINGLE_SELECT);
$what = array(
	array('host',enum_list_id_val('host'),$host_got,$type),
	array('arch',enum_list_id_val('arch'),$arch_got,$type),
	array('product',enum_list_id_val('product'),$product_got,$type)
);
if( $step=='new' )	{
	$what[] = array('wtoken','',token_generate(),HIDDEN);
	$what[] = array('submit','','insert',HIDDEN);
}


if( $step=='search' )	{
	print html_search_form('reference.php', $what, array('submit'=>($step=='new' ? 'add new' : 'search')));
	$data = reference_host_search( array(
		'host_id'=>$host_got,
		'arch_id'=>$arch_got,
		'product_id'=>$product_got
	),$transl);
	table_translate($data,$transl);
	unset($data[0]['reference_host_id']);
	print html_table($data,array('id'=>'references','sort'=>'sss'));
}
else if( $step=='new' )	{
	print html_search_form('reference.php', $what, array('submit'=>($step=='new' ? 'add new' : 'search')));
}
else if( $step=='edit' )	{
	print html_search_form('reference.php', $what, array('submit'=>($step=='new' ? 'add new' : 'search')));
	$data = reference_host_search(array('reference_host_id'=>$reference_host_got),$transl);
	table_translate($data,$transl);
	unset($data[0]['reference_host_id']);
	print html_table($data,array());

	
}
?>
