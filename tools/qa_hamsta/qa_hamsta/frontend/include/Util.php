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
