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
?>

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
