<?php
/* ****************************************************************************
  Copyright (c) 2011 Unpublished Work of SUSE. All Rights Reserved.
  
  THIS IS AN UNPUBLISHED WORK OF SUSE.  IT CONTAINS SUSE'S
  CONFIDENTIAL, PROPRIETARY, AND TRADE SECRET INFORMATION.  SUSE
  RESTRICTS THIS WORK TO SUSE EMPLOYEES WHO NEED THE WORK TO PERFORM
  THEIR ASSIGNMENTS AND TO THIRD PARTIES AUTHORIZED BY SUSE IN WRITING.
  THIS WORK IS SUBJECT TO U.S. AND INTERNATIONAL COPYRIGHT LAWS AND
  TREATIES. IT MAY NOT BE USED, COPIED, DISTRIBUTED, DISCLOSED, ADAPTED,
  PERFORMED, DISPLAYED, COLLECTED, COMPILED, OR LINKED WITHOUT SUSE'S
  PRIOR WRITTEN CONSENT. USE OR EXPLOITATION OF THIS WORK WITHOUT
  AUTHORIZATION COULD SUBJECT THE PERPETRATOR TO CRIMINAL AND  CIVIL
  LIABILITY.
  
  SUSE PROVIDES THE WORK 'AS IS,' WITHOUT ANY EXPRESS OR IMPLIED
  WARRANTY, INCLUDING WITHOUT THE IMPLIED WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE, AND NON-INFRINGEMENT. SUSE, THE
  AUTHORS OF THE WORK, AND THE OWNERS OF COPYRIGHT IN THE WORK ARE NOT
  LIABLE FOR ANY CLAIM, DAMAGES, OR OTHER LIABILITY, WHETHER IN AN ACTION
  OF CONTRACT, TORT, OR OTHERWISE, ARISING FROM, OUT OF, OR IN CONNECTION
  WITH THE WORK OR THE USE OR OTHER DEALINGS IN THE WORK.
  ****************************************************************************
 */

/* Search the locations of network installation source for a product

Used by Ajax.

FIXME: it's better done from database
*/

require("../config.php");
require_once ('../lib/ConfigFactory.php');
/* We need to build it here because this is not evaluated within the
 * index page but using JSON. */
$conf = ConfigFactory::build("Ini", "../config.ini", $configuration_group);

// Load sdk index
$json = file_get_contents($conf->url->index->sdk);
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
