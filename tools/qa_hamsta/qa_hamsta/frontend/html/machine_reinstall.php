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

	if (!defined('HAMSTA_FRONTEND')) {
		$go = 'machine_send_job';
		return require("index.php");
	}

/* Check if the machines are suited for reinstall. */
if (check_machines_before_reinstall ($machines, 'reinstall')) {

?>
Machines:
<?php foreach ($machines as $machine): ?>
<span class="machine_name">
	<a class="text-small-bold" href="index.php?go=machine_details&amp;id=<?php echo($machine->get_id()); ?>"><?php echo($machine->get_hostname()); ?></a><input class="x" type="button" value="x" onclick="removeMachine(<?php echo($machine->get_id())?>, this)"/>

</span>
<?php endforeach; ?>

<form enctype="multipart/form-data" action="index.php?go=machine_reinstall" method="POST" onsubmit="return checkcontents(this);">
<input id="summary" type="checkbox"/>
<label for="summary" class="button">show summary</label>
<div class="finish">
	<label for="summary" class="btn first">Edit</label>
	<input type="submit" value="Submit" name="proceed" class="btn"/>
</div>
<div class="tabs">
	<div id="tab-product" class="tab">
		<input type="radio" id="tab1" name="tab-group-1" checked/>
		<div class="content">
			<div class="breadcrumb breadcrumb_top">
				<label for="tab1" class="btn disabled">Prev</label>
				<label for="tab2" class="btn">Next</label>
				<label for="summary" class="btn">Finish</label>
				<label for="tab1" class="btn active first">Product</label>
				&raquo;
				<label for="tab2" class="btn">Disk</label>
				&raquo;
				<label for="tab3" class="btn">Advanced</label>
			</div>
			<?php require ("req_rein_all.php"); ?>
			<div class="breadcrumb breadcrumb_bottom">
				<label for="tab1" class="btn disabled">Prev</label>
				<label for="tab2" class="btn">Next</label>
				<label for="summary" class="btn">Finish</label>
			</div>
		</div>
	</div>
	<div id="tab-disk" class="tab">
		<input type="radio" id="tab2" name="tab-group-1"/>
		<div class="content">
			<div class="breadcrumb breadcrumb_top">
				<label for="tab1" class="btn">Prev</label>
				<label for="tab3" class="btn">Next</label>
				<label for="summary" class="btn">Finish</label>
				<label for="tab1" class="btn first">Product</label>
				&raquo;
				<label for="tab2" class="btn active">Disk</label>
				&raquo;
				<label for="tab3" class="btn">Advanced</label>
			</div>
			<?php require ("req_rein.php"); ?>
			<div class="breadcrumb breadcrumb_bottom">
				<label for="tab1" class="btn">Prev</label>
				<label for="tab3" class="btn">Next</label>
				<label for="summary" class="btn">Finish</label>
			</div>

		</div>
	</div>
	<div id="tab-advanced" class="tab">
		<input type="radio" id="tab3" name="tab-group-1"/>
		<div class="content">
			<div class="breadcrumb breadcrumb_top">
				<label for="tab2" class="btn">Prev</label>
				<label for="tab3" class="btn disabled">Next</label>
				<label for="summary" class="btn">Finish</label>
				<label for="tab1" class="btn first">Product</label>
				&raquo;
				<label for="tab2" class="btn">Disk</label>
				&raquo;
				<label for="tab3" class="btn active">Advanced</label>
			</div>
			<?php require ("req_sut.php"); ?>
			<div class="breadcrumb breadcrumb_bottom">
				<label for="tab2" class="btn">Prev</label>
				<label for="tab3" class="btn disabled">Next</label>
				<label for="summary" class="btn">Finish</label>
			</div>

		</div>
	</div>
</div>
<div class="finish">
	<label for="summary" class="btn first">Edit</label>
	<input type="submit" value="Submit" class="btn" name="proceed"/>
</div>

<?php
	foreach ($machines as $machine):
		echo('<input type="hidden" name="a_machines[]" value="'.$machine->get_id().'">');
	endforeach;

	print_install_post_data ();
?>

</form>
<?php
}
?>

<script src="js/install_product.js"></script>
