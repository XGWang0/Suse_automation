<?php
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
    <script language="JavaScript" src="/tblib/scripts/gs_sortable.js" type="text/javascript"></script>
    <script language="JavaScript" src="/tblib/scripts/jquery-1.6.1.js" type="text/javascript"></script>
    <?php if (!empty($html_refresh_uri)): ?>
        <meta http-equiv="refresh" content="<?php echo($html_refresh_interval.";".$html_refresh_uri); ?>">
    <?php endif; ?>
</head>
<body>

<div id="header">

	<div id="hlogo">
		<a href="/hamsta" border="0" style="text-decoration: none;">
			<img src="images/logo-novell.png" class="logo" alt="Novell Logo" title="Click to return to the main page" />
			<img src="images/logo-hamsta.png" class="logo" alt="Hamsta Logo" title="Click to return to the main page" />
			<img src="images/logo-suse.png" class="logo" alt="Suse Logo" title="Click to return to the main page" />
			<img src="images/header.png" class="caption" alt="OPS QA Automation" title="Click to return to the main page" />
			<img src="images/hamsta.png" class="hamsta" alt="Hamsta" title="Hamsta" />
		</a>
		<div class="version text-main text-white bold"><em>v2.2.0</em></div>
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
