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

    /**
     * Common HTML header for all pages. Displays the navigation bar, page
     * title and page selection bar if needed.
     */

	 require_once("include/Util.php");
?>
<html>
<head>
    <title><?php if(!empty($html_title)) echo($html_title." - "); ; ?>HAMSTA</title>
        <link href="css/style.css" rel="stylesheet" type="text/css">
        <link href="../tblib/css/common.css" rel="stylesheet" type="text/css">
	<link href="css/layout.css" rel="stylesheet" type="text/css">
	<link href="css/text.css" rel="stylesheet" type="text/css">
	<link href="css/links.css" rel="stylesheet" type="text/css">
	<link href="css/color.css" rel="stylesheet" type="text/css">
    <link rel="icon" type="image/png" href="/hamsta/icon.png">
    <script language="JavaScript" src="js/commfuncs.js" type="text/javascript"></script>
    <script language="JavaScript" src="/scripts/gs_sortable.js" type="text/javascript"></script>
    <script language="JavaScript" src="/scripts/jquery.js" type="text/javascript"></script>
    <?php if (!empty($html_refresh_uri)): ?>
        <meta http-equiv="refresh" content="<?php echo($html_refresh_interval.";".$html_refresh_uri); ?>">
    <?php endif; ?>
</head>
<body>

<div id="header">

	<div id="hlogo">
		<a href="/hamsta" border="0" style="text-decoration: none;">
			<img src="images/logo-hamsta.png" class="logo" alt="Hamsta Logo" title="Click to return to the main page" />
			<img src="images/logo-suse.png" class="logo" alt="Suse Logo" title="Click to return to the main page" />
			<img src="images/header.png" class="caption" alt="SUSE QA Automation" title="Click to return to the main page" />
			<img src="images/hamsta.png" class="hamsta" alt="Hamsta" title="Hamsta" />
		</a>
		<div class="version text-main text-white bold"><em>v<?php $version = explode("-", $hamstaVersion); echo($version[2]); ?></em></div>
		<div style="float: right" class="navibar"><a class="text-main text-white" href="index.php?go=install_client">Install Client</a></div>
	</div>

	<div id="header-links" class="text-medium bold">
	</div>

	<div class="text-small">
	</div>

	<div id="links" class="text-medium bold navibar">
	<?php
        while (list($key,$value) = each($naviarr)) {
                echo createLink($value, $key);
        }
	?>
	</div>
</div>

<div id="content">

<span id="message" class=""></span>

<h1 class="text-large text-blue"><?php echo($html_title); ?></h1>

<?php

if (!empty($pages_count))
{
	echo "<div class=\"pages\">";
	echo "Page: ";
	if (empty($page_params)) $page_params = "";

	for ($i = 0; $i < $pages_count; $i++) {
		if ($i > 0) echo(' | ');

		if ($page == $i) {
		echo('<b>'.($i + 1).'</b>');
		} else {
		echo('<a href="index.php?go='.$go.'&amp;page='.$i."&amp;".$page_params.'">'.($i + 1).'</a>');
		}

	}
	echo "</div>";
}

?>

<?php if (!empty($error)): ?>
<div class="error"><?php echo($error); ?></div>
<?php endif ?>
