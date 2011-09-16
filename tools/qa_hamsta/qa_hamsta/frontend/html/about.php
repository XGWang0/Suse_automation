<?php
    /**
     * Content of the <tt>about</tt> page.
     */
    
    if (!defined('HAMSTA_FRONTEND')) {
        $go = 'about';
        return require("index.php");
    }

?>

    <div style="float: left; margin-right: 10px; margin-bottom: 10px;">
		<img src="images/hamsta.jpg" alt="Hamsta" title="Hamsta" style="padding: 3px; border: 1px solid #dddddd;" />
	</div>

	<h2 class="text-medium text-blue bold"><u>HA</u>rdware <u>M</u>aintenance, <u>S</u>etup & <u>T</u>est <u>A</u>utomation (HAMSTA)</h2>
	<p class="text-main">Hamsta is a system that lets you build a network of System Under Test (SUT) machines. Machines are monitored by the master node, and receive planned jobs. The results, plus monitoring information, is sent back to the master.</p>
	<p class="text-main">Hamsta also allows the automated installation of SUTs and solves the need of distributing different local test automation frameworks with their integrated tests, towards extending the coverage of tested hardware configurations in a distributed and large scale computing environment.</p>
	<p class="text-main">Sounds cool, huh?</p>
	<p class="text-main"><strong>Current Version:</strong> <?php echo "$hamstaVersion"; ?></p>
	<p class="text-main">If you have any questions about, or issues with Hamsta, please just send an email to the automation team at <strong><a href="mailto:qa_automation@suse.de">qa-automation@suse.de</a></strong>. We'll be happy to help out.</p>
	<p class="text-main">Now, hang on and enjoy the ride!</p>
