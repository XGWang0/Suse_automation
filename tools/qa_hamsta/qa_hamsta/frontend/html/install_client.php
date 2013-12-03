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
     * Contents of the <tt>install_client</tt> page
     */
    if (!defined('HAMSTA_FRONTEND')) {
        $go = 'install_client';
        return require("index.php");
    }
    $SLE_HEAD_repos = array('SLES_9', 'SLE_10_SP1_Head', 'SLE_10_SP2_Head', 'SLE_10_SP3', 'SLE_10_SP4_Update', 'SLE_10_SP4', 'SUSE_SLE-11_GA', 'SUSE_SLE-11_Update', 'SUSE_SLE-11-SP1_GA', 'SLE_11_SP1_Update', 'SUSE_SLE-11-SP2_GA', 'SLE_Factory', 'SUSE_Factory_Head');
    $openSUSE_HEAD_repos = array('openSUSE_11.4', 'openSUSE_12.1', 'openSUSE_Factory');
?>
<script type="text/javascript" src="js/install_client.js"></script>
<h2 class="text-medium text-blue">One Click Install</h2>
<p>
	This will install the Hamsta Client on the local machine. Load this page from a system under test to install the Hamsta Client.
	<div class="text-small text-blue">Select your operating system</div><br />
	<div class="soo_button" id="openSUSE_button" onclick="selectOS('openSUSE_button', 'openSUSE_repos')">
		<img src="images/opensuse.png" alt="openSUSE" style="height: 50px">
		<p>openSUSE</p>
	</div>
	<div class="soo_button" id="SLE_button" onclick="selectOS('SLE_button', 'SLE_repos')">
		<img src="images/logo-suse.png" alt="SLE" style="height: 50px">
		<p>SLE</p>
	</div>
	<br /><br /><br /><br /><br /><br />
	<div id="openSUSE_repos" style="display: none">
		<div class="text-small text-blue">Install using One Click Install</div><br />
		<?php
			foreach ($openSUSE_HEAD_repos as $repo) {
				echo '<a href="inst/hamsta_HEAD_'.$repo.'.ymp">'.$repo.'</a><br />';
			}
		?>
		<br />
	</div>
	<div id="SLE_repos"  style="display: none">
		<div class="text-small text-blue">Install using One Click Install</div><br />
		<?php
			foreach ($SLE_HEAD_repos as $repo) {
				echo '<a href="inst/hamsta_HEAD_'.$repo.'.ymp">'.$repo.'</a><br />';
			}
    		?>
	</div>
</p>
