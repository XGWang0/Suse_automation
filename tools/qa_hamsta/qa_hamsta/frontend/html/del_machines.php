<?php
    /**
     * Contents of the <tt>del_machines</tt> page
     */
    if (!defined('HAMSTA_FRONTEND')) {
        $go = 'del_machines';
        return require("index.php");
    }
?>
<?php
require("req_delmachine1.php");
?>

<h2 class="text-medium text-blue">Delete Machines</h2>
<form action="index.php?go=del_machines" method="post">
<p>
You are about to delete the following machines and remove them from any groups to which they may be assigned. Hamsta will have no further record of these machine and they will need to be manually re-added if you want to start managing them through Hamsta once again later on.
</p>
<?php require("req_delmachine2.php"); ?>
