<html>
<head>
<title>Latest Features - Description</title>
<link href="../css/text.css" rel="stylesheet" type="text/css">
<link href="../css/color.css" rel="stylesheet" type="text/css">
</head>
<body>
<?php
	require("../globals.php");
	global $latestFeatures;
	
	# Make sure the feature description exists
	if(isset($_GET['release']) and array_key_exists($_GET['release'], $latestFeatures) and isset($_GET['index']) and $_GET['index'] < count($latestFeatures[$_GET['release']]))
	{
		# Get the feature's information
		$currentFeature = $latestFeatures[$_GET['release']][$_GET['index']];
		$descriptionSplit = explode(" -- ", $currentFeature, 3);
		$title = $descriptionSplit[1];
		$date = $descriptionSplit[0];
		$rest = $descriptionSplit[2];
	}
	else
	{
		# Set dummy feature information
		$title = "";
		$date = "";
		$rest = "";
	}

	echo "<h2 class=\"text-medium text-blue\" style=\"border-bottom: 2px solid; border-color: #e78f08;\">Latest Feature Details</h2>";
	if($date != "")
	{
		echo "<p class=\"text-main\"><strong>Feature:</strong> $title</p>";
		echo "<p class=\"text-main\"><strong>Date Added:</strong> $date</p>";
		echo "<p class=\"text-main\"><strong>Description:</strong> $rest</p>";
	}
	else
	{
		echo "<p class=\"text-main\"><strong>Sorry!</strong> The feature description could not be retrieved. Either you have tried to access a non-existing feature, or the feature description was incorrectly written by the developer.</p>";
	}
?>
</body>
</html>
