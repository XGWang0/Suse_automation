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



$db = new mysqli("localhost", 'qadb','', "qadb");
if (mysqli_connect_errno()) {
    printf("Connect failed: %s\n", mysqli_connect_error());
    exit();
}


if(http('arch_id')){
	if(insert_update_promoted($db,$arch_id,$product_id,$build_nr,$release_id)){
	$res="recoder insert succeed<br>";
	}
	else {
	$res="recoder insert failed<br>";
	}
}

list_promoted($db);


print html_footer();



function insert_update_promoted($db,$arch_id,$product_id,$build_nr,$release_id)
{
	$stmt=$db->prepare("INSERT INTO build_promoted (arch_id,build_nr,product_id,release_id) VALUES ($arch_id ,$build_nr,$product_id,$release_id)");
	$stmt->execute();
	$affect=$stmt->affected_rows;
	if( $affect >0 ) 
	{
		echo "recoder insert succeed<br>";
		$stmt=$db->prepare("UPDATE submission SET release_id = $release_id WHERE arch_id=$arch_id AND build_nr=$build_nr AND product_id=$product_id");
		$stmt->execute();
		$number=$stmt->affected_rows;
		if( $number >0 ) {
			echo "$number recoders update<br>";
		}
		else 
		{
		echo "no recoders update<br>";
		}
	}
	else 
	{
		echo "recoder insert failed<br>";
	}

}

function list_promoted($db)
{
	$stmt=$db->prepare("SELECT build_promoted_id,arch.arch,build_nr,product.product,release.release FROM build_promoted JOIN arch USING(arch_id) JOIN product USING(product_id) JOIN `release` USING(release_id) ORDER BY build_promoted_id");
	$stmt->execute();
	$stmt->bind_result($bp_id,$a_id,$b_nr,$p_id,$r_id);
	$r[]=array('build_promoted_id','arch_id','product_id','build_nr','release_id');
	while($stmt->fetch()){
		$r[]=array($bp_id,$a_id,$p_id,$b_nr,$r_id);
	}
	print html_table($r);
}

?>
