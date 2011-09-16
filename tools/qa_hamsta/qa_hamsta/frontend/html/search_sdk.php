<?php
/* Search the locations of network installation source for a product

Used by Ajax.

sdk index is loaded from $SDK_INDEX_URL.

FIXME: it's better done from database
*/

require("../config.php");

// Load sdk index
$json = file_get_contents(SDK_INDEX_URL);
if ($json == ""){
	echo json_encode(array());
	return;
}
$sdk = json_decode($json);

/* If nothing is given, return all products names
   If product is given, return architecutres
   If both product and arch is given, return the urls
*/

$product = "";
$arch = "";
if (isset($_GET['product'])) 
    $product = $_GET['product'];
if (isset($_GET['arch'])) 
    $arch = $_GET['arch'];

if ($product == "")
	echo json_encode(list_all_products($sdk));
elseif ($arch == "")
	echo json_encode(get_archs($sdk, $product));
    else
	echo json_encode(get_urls($sdk, $product, $arch));

// Get all avaiable products from sdk
function list_all_products($sdk){
	foreach($sdk as $product)
		$products[] = $product->{"product"};
	return array_unique($products);
}	

// Get supported architectures by product
// FIXME: We'd better have embedded structure like $sdk->$product->$arch
// So that we don't need to iterate all products everytime
function get_archs($sdk, $product){
	$archs = array();
	foreach($sdk as $p){
		if ($p->{"product"} == $product)
			$archs[] = $p->{"arch"};
	}
	return $archs;
}

// Get the installation sources
function get_urls($sdk, $product, $arch){
	$urls = array();
	foreach($sdk as $p)
		if ($p->{"product"} == $product and $p->{"arch"} == $arch) {
            $urls[] = $p->{"url"};
            $urls[] = $p->{"pattern"};
        }
	return $urls;
}


?>
