<?php
/*Get all the avaiable products from INSTALLATION_REPO_URL page.
FIXME: it's better done from database

Return: ["products": $products] or Nothing
*/

require("../config.php");

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
