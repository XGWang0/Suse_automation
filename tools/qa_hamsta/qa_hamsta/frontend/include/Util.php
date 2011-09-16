<?php

	function createLink($url, $text)
	{
		$requestUri = substr($_SERVER['REQUEST_URI'], 8);

		if($requestUri == $url or ($url == "index.php?go=machines" and $requestUri == "")) {
			return "" ."<a href=\"$url\">$text</a>" . "\n";
		} else {
			return "" .
				"<a href=\"$url\">$text</a>" . "\n";
		}
	}

	function showRefresh($page, $html_refresh_interval)
	{
		//if (!is_numeric($html_refresh_interval) && (int)$html_refresh_interval == $html_refresh_interval && $html_refresh_interval >= 0) {
		//	$_SESSION['message'] = 'Refresh interval must be a positive integer.';
		//	$_SESSION['mtype'] = "fail";
		//}
		return "<table class=\"tbrefresh\">" .
			"<tr>" .
				"<form action=\"$page\" method=\"post\">" .
					"<td>" .
						"<input name=\"pre_value\" type=\"hidden\" value=". $html_refresh_interval . " >" .
						"Refresh time: <strong>" . (($html_refresh_interval!=0) ? $html_refresh_interval . "s" : "disabled") . "</strong>. &nbsp;" .
						"Change:" .
						"<input name=\"interval\" type=\"text\" size=\"1\" maxlength=\"3\" class=\"btrefresh\"> " .
						"<input type=\"submit\" value=\"change\" class=\"btrefresh\">" .
					"</td>" .
				"</form>" .
				"<form action=\"$page\" method=\"post\">" .
					"<td>" .
						"<input name=\"norefresh\" type=\"hidden\" value=\"1\" >" .
						"<input type=\"submit\" value=\"stop\" class=\"btrefresh\" style=\"position: relative; top: 1px;\">" .
					"</td>" .
				"</form>" .
			 "</tr>" .
			"</table>";
	}

?>
