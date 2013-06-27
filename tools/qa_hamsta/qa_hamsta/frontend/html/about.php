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
