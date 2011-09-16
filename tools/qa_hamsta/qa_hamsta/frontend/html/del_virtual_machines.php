<?php
    /**
     * Contents of the <tt>del_virtual_machines</tt> page
     */
    if (!defined('HAMSTA_FRONTEND')) {
        $go = 'del_virtual_machines';
        return require("index.php");
    }
	require("req_delmachine1.php");
?>

<h2 class="text-medium text-blue">Delete Virtual Machines</h2>
<form action="index.php?go=del_virtual_machines" method="post">
You are about to delete the following virtual machines and remove them from any groups to which they may be assigned. <b>These virtual machines will also be destroyed and removed from their virtualization hosts, including their disk images. It is not possible to restore the virtual machine once it has been deleted!</b>
<br />    
<?php require("req_delmachine2.php"); ?>
