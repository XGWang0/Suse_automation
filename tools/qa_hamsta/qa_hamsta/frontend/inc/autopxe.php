<?php
/**
 * Logic of the reinstall page 
 */
if (!defined('HAMSTA_FRONTEND')) {
    $go = 'autopxe';
    return require("../index.php");
}

$search = new MachineSearch();
$search->filter_in_array(request_array("a_machines"));
$machines = $search->query();

if (request_str("submit")) {
	$repourl = request_str("repourl");
	$type = request_str("type");
	$address = request_str("address");
	$is_hamsta = request_str("hamsta");
	$cmd = 'sudo ssh -o StrictHostKeyChecking=no rd-qa@'.$pxeserver." \"autopxe.pl $repourl $type $address $is_hamsta 1>/dev/null \"";
	system($cmd, $ret);
	if ($ret == 0) {
		echo "<div class=\"successmessage-big text-main\">AutoPXE configuration was a success!<br /><br />Please network boot the server with <strong>$type '$address'</strong> within 5 minutes to initiate an automated installation.</div>";
	} else if ($ret == 255) {
		echo "<div class=\"failmessage-big text-main\">AutoPXE configuration failed!<br /><br />Reason: autopxe.pl usage was incorrect. Please contact the automation team (qa-automation@suse.de) with the text of this error message.</div>";
	} else if ($ret == 10) {
		echo "<div class=\"failmessage-big text-main\">AutoPXE configuration warning!<br /><br />The AutoPXE configuration was a success (you do not need to run it again), however the 'atd' service was not loaded on your PXE server, which means that the automatic cleanup of the AutoPXE files will not happen. To fix this, please enable 'atd' on the PXE server (<strong>rcatd start; chkconfig atd on</strong>).</div>";
	} else if ($ret == 20) {
		echo "<div class=\"failmessage-big text-main\">AutoPXE configuration failed!<br /><br />Reason: the PXE file could not be created. Please file a bug or contact the automation team (qa-automation@suse.de) with the text of this error message.</div>";
	} else {
		echo "<div class=\"failmessage-big text-main\">AutoPXE configuration failed!<br /><br />Reason: Unknown (exit code '$ret'). Please contact the automation team (qa-automation@suse.de) with the text of this error message.</div>";
	}
}

$html_title = "AutoPXE";
?>
