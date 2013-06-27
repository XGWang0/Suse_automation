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

/* Returns JSON representation of different data about the
 * repositories and products.
 *
 * Used by Ajax.
 *
 * FIXME: it's better done from database
 */

require ("../globals.php");
require ("../lib/request.php");
require ("../include/json.php");

$product_type = request_str ('prod_type');
$json_file_path = '';
$product = request_str ('product');
$arch = request_str ('arch');
$capable = request_str ('capable');

/* Set up variables according to different products. */
switch ($product_type) {
case 'distro':
	$json_file_path = $config->url->index->repo;
	break;
case 'addon':
	$json_file_path = $config->url->index->sdk;
	break;
default:
	echo (json_encode (array()));
	return;
}

$repos = get_json_from_file ($json_file_path, false);
if (! isset ($repos)){
	echo json_encode (array());
	return;
}

/* If nothing is given, return all products names
   If product is given, return architectures
   If both product and arch is given, return the urls
*/
if (empty ($product)) {
	echo json_encode (list_all_products ($repos));
} else if (empty ($arch)) {
	switch ($product_type) {
	case 'distro':
		echo json_encode (get_distro_archs($repos, $product, $capable));
		break;
	case 'addon':
		echo json_encode (get_addon_archs ($repos, $product));
		break;
	default:
		echo (json_encode (array()));
		return;
	}
} else {
	echo json_encode (get_urls ($repos, $product, $arch));
}

?>
