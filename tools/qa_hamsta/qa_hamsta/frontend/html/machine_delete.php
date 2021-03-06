<?php
/* ****************************************************************************
  Copyright (c) 2013 Unpublished Work of SUSE. All Rights Reserved.
  
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
     * Contents of the <tt>machine_delete</tt> page
     */
    if (!defined('HAMSTA_FRONTEND')) {
        $go = 'machine_delete';
        return require("index.php");
    }
?>
<?php
require("req_delmachine1.php");
?>

<h2 class="text-medium text-blue">Delete Machines</h2>
<form action="index.php?go=machine_delete" method="post">
<p>
You are about to delete the following machines and remove them from any groups to which they may be assigned.
<ul>
<li>To completely delete, stop the hamsta client on the machine, remove it from chkconfig, and click Yes here. The machine will disappear.
<li>To simply purge old data and refresh the machine, just click Yes now (the client will disappear for a moment and then re-connect to the master with a fresh configuration).
</ul>
Hamsta will have no further record of these machines and they will need to be manually re-added if you want to start managing them through Hamsta once again later on.
</p>
<p>
Machine deletion might take up to one minute. Please be patient and wait until the page reloads.
</p>
<?php require("req_delmachine2.php"); ?>
