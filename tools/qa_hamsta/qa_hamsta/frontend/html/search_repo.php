<?php
/* Search the locations of network installation source for a product

Used by Ajax.

Repo index is loaded from $REPO_INDEX_URL.

FIXME: it's better done from database
*/

require("../config.php");

// Load repo index
$json = file_get_contents(REPO_INDEX_URL);
if ($json == ""){
	echo json_encode(array());
	return;
}
$repo = json_decode($json);

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
if (isset($_GET['capable'])) {
	$capable = $_GET['capable'];
} else {
	$capable = "";
}

if ($product == "")
	echo json_encode(list_all_products($repo));
elseif ($arch == "")
	echo json_encode(get_archs($repo, $product, $capable));
else
	echo json_encode(get_urls($repo, $product, $arch));

// Get all avaiable products from repo
function list_all_products($repo){
	foreach($repo as $product)
		$products[] = $product->{"product"};
	return array_unique($products);
}	

// Get supported architectures by product
// FIXME: We'd better have embedded structure like $repo->$product->$arch
// So that we don't need to iterate all products everytime
function get_archs($repo, $product, $capable){
	$archs = array();
	foreach($repo as $p) {
		if ($p->{"product"} == $product) {
			# Filter out archs that are not capable by this machine
			$thisArch = $p->{"arch"};
			if($thisArch == "x86_64" and ($capable == "" or $capable == "x86_64")) {
				# Only add x86_64 if capable is x86_64 or empty
				$archs[] = $thisArch;
			} else if($thisArch == "i586" and ($capable == "" or $capable == "x86_64" or $capable == "i586")) {
				# Only consider i586 if capable is x86_64, i586 or empty
				if(in_array("i386", $archs)) {
					# If an i386 and i586 exist, just show the i586
					$elementIndex = array_search("i386", $archs);
					$archs[$elementIndex] = "i586";
				} else {
					# Otherwise, just add the i586
					$archs[] = $thisArch;
				}
			} else if($thisArch == "i386" and ($capable == "" or $capable == "x86_64" or $capable == "i586")) {
				# Only consider i386 if capable is x86_64, i586 or empty
				if(!in_array("i586", $archs)) {
					# Only add i386 if an i586 doesn't yet exist
					$archs[] = $thisArch;
				}
			} else if(preg_match("/^ppc/", $thisArch) and ($capable == "" or preg_match("/^ppc/", $capable))) {
				# Only add ppc* if capable is ppc* or empty
				$archs[] = $thisArch;
			} else if(preg_match("/^ia/", $thisArch) and ($capable == "" or preg_match("/^ia/", $capable))) {
				# Only add ia* if capable is ia* or empty
				$archs[] = $thisArch;
			} else if(preg_match("/^s390/", $thisArch) and ($capable == "" or preg_match("/^s390/", $capable))) {
				# Only add s390* if capable is s390* or empty
				$archs[] = $thisArch;
			}
		}
	}
	return $archs;
}

// Get the installation sources
function get_urls($repo, $product, $arch){
	$urls = array();
	foreach($repo as $p)
		if ($p->{"product"} == $product and $p->{"arch"} == $arch) {
			$urls[] = $p->{"url"};
			$urls[] = $p->{"pattern"};
		}
	return $urls;
}
?>
