<?php

  /** Return a JSON object from specified file. See json_decode in PHP
   * documentation for more information about the as_associative_array
   * parameter.
   *
   * string $file_name Path to the JSON file.
   * boolean $as_associative_array Create associative array if true, object if false.
   */
function get_json_from_file ($file_name, $as_associative_array)
{
	$json = file_get_contents($file_name);
	if (! isset ($json) || empty ($json))
	{
		return null;
	}
	return json_decode($json, $as_associative_array);
}

/* Return a specified product that has specified url. */
function get_product_by_url ($repos, $url)
{
	foreach ($repos as $r)
	{
		if ($url == $r['url'])
		{
			return $r;
		}
	}
	return null;
}

/* Get all patterns for a given url. */
function get_patterns ($file, $url)
{
	$repos = get_json_from_file ($file, true);
	if (isset ($repos))
	{
		$product = get_product_by_url ($repos, $url);
		return $product['pattern'];
	}
	return null;
}

/* Get the installation sources. */
function get_urls($repo, $product, $arch){
	$urls = array();
	foreach($repo as $p)
		if ($p->{"product"} == $product and $p->{"arch"} == $arch) {
			$urls[] = $p->{"url"};
			$urls[] = $p->{"pattern"};
		}
	return $urls;
}

/* Get all avaiable products from repo. */
function list_all_products($repo){
	foreach($repo as $product)
		$products[] = $product->{"product"};
	return array_unique($products);
}	

/* Get supported architectures by product. */
function get_addon_archs($sdk, $product){
	$archs = array();
	foreach($sdk as $p){
		if ($p->{"product"} == $product)
			$archs[] = $p->{"arch"};
	}
	return $archs;
}

/* Get supported architectures by product. */
function get_distro_archs($repo, $product, $capable){
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

?>
