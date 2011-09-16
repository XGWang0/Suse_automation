<?php
    /**
     * Logic of the about page.
     */
    
    if (!defined('HAMSTA_FRONTEND')) {
        $go = 'about';
        return require("index.php");
    }

    $html_title = "About Hamsta";

	$hamstaVersion = htmlspecialchars(`rpm -q qa_hamsta-master`);

?>
