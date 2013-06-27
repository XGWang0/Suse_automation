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

/*Get all the avaiable products from INSTALLATION_REPO_URL page.
FIXME: it's better done from database

Return: ["products": $products] or Nothing
*/

require("../globals.php");

$page_pd = file_get_contents(INSTALLATION_REPO_URL);
$page_sdk = file_get_contents(SDK_REPO_URL);
if (preg_match_all('/<a\s+href=["\']([^"\']+)["\']/i', $page_pd, $links_pd, PREG_PATTERN_ORDER) == false)
	return;
if (preg_match_all('/<a\s+href=["\']([^"\']+)["\']/i', $page_sdk, $links_sdk, PREG_PATTERN_ORDER) == false)
        return;

foreach($links_pd[1] as $link_pd){
        if(stripos($link_pd, 'le') == false)
                continue;
        if(stripos($link_pd, 'sdk') == true)
                continue;
	$url = join('/', array(rtrim(INSTALLATION_REPO_URL, '/'), $link_pd));
	$products[] = $url;
}
foreach($links_sdk[1] as $link_sdk){
        if(stripos($link_sdk, 'sdk') == false)
                continue;
        $url = join('/', array(rtrim(SDK_REPO_URL, '/'), $link_sdk));
        $sdks[] = $url;
}
echo json_encode(array("products" => $products, "sdks" => $sdks));
?>
