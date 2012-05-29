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
	 * Content of the <tt>machines</tt> page.
	 */
if (!defined('HAMSTA_FRONTEND')) {
	$go = 'machines';
	return require("index.php");
}
?>
<form action="index.php?go=machines" method="post" name="machine_list" onSubmit="return checkcheckbox(this)">
<table class="list text-main" id="machines">
  <thead>
	<tr>
		<th><input type="checkbox" onChange='chkall("machine_list", this)'></th>
		<th>Name</th>
		<th>Status</th>
		<?php
			foreach ($fields_list as $key=>$value)
				if (in_array($key, $display_fields))
					echo("<th>$value</th>");
		?>
		<th id='actions'><a>Actions</a></th>
	</tr>
  </thead>
  <tbody>
	<?php foreach ($machines as $machine): ?>
	   <tr
			<?php if (($machine->get_status_id() == MS_DOWN) && ($machine->is_busy())): ?>
			class="crashed_job"
			<?php endif; ?>
		>
			<td><input type="checkbox" name="a_machines[]" value="<?php echo($machine->get_id()); ?>" <?php if (in_array($machine->get_id(), $a_machines)) echo("checked"); ?>></td>
			<td title="<?php echo($machine->get_notes()); ?>"><a href="index.php?go=machine_details&amp;id=<?php echo($machine->get_id()); ?>&amp;highlight=<?php echo($highlight); ?>"><?php echo($machine->get_hostname()); ?></a></td>
			<td><?php echo($machine->get_status_string()); if ($old_packages = $machine->get_tools_out_of_date()) echo('<a href="index.php?go=send_job&a_machines[]='.$machine->get_id().'&filename[]='.XML_DIR.'/hamsta-upgrade-restart.xml&submit=1"><img src="images/exclamation_yellow.png" alt="Tools out of date!" title="Click to update. Outdated tools: '.implode(", ", $old_packages).'" width="20" style="float:right; padding-left: 3px;"></img></a>'); if ($machine->get_devel_tools()) echo('<img src="images/gear-cog_blue.png" alt="Devel Tools" title="Devel Tools" width="20" style="float:right; padding-left: 3px;"></img>'); ?></td>
		<?php
			foreach ($fields_list as $key=>$value){
				$fname = "get_".$key;
				$res = $machine->$fname();
				if (in_array($key, $display_fields))
					echo ("<td>$res</td>");
			}
		?>
		<td align="center">
<?php
        if (($machine->get_powerswitch() != NULL) and ($machine->get_powertype() != NULL) and ($machine->get_powerslot() != NULL) ) {
		echo "<img src=\"images/icon-start.png\" alt=\"Start " . $machine->get_hostname() . "\" title=\"Start ".$machine->get_hostname() . "\" border=\"0\" " .
                	                "width=\"20\" style=\"padding-right: 3px;\" " .
        	                        "onclick=\"";
	        echo "var r = confirm('This will start " . $machine->get_hostname() . ". Are you sure you want to continue?');" .
	        "if(r==true)" .
	                "{" .
                	        "window.location='index.php?go=power&amp;a_machines[]=" . $machine->get_id() . "&amp;action=start';" .
        	        "}";
	        echo "\" />";
	
		echo "<img src=\"images/icon-restart.png\" alt=\"Restart " . $machine->get_hostname() . "\" title=\"Restart ".$machine->get_hostname() . "\" border=\"0\" " .
                	                "width=\"20\" style=\"padding-right: 3px;\" " .
        	                        "onclick=\"";
	        echo "var r = confirm('This will restart " . $machine->get_hostname() . ". Are you sure you want to continue?');" .
	        "if(r==true)" .
	                "{" .
                	        "window.location='index.php?go=power&amp;a_machines[]=" . $machine->get_id() . "&amp;action=restart';" .
        	        "}";
	        echo "\" />";

	        echo "<img src=\"images/icon-stop.png\" alt=\"Stop " . $machine->get_hostname() . "\" title=\"Stop ".$machine->get_hostname() . "\" border=\"0\" " .
	                                "width=\"20\" style=\"padding-right: 3px;\" " .
        	                        "onclick=\"";
	        echo "var r = confirm('This will stop " . $machine->get_hostname() . ". Are you sure you want to continue?');" .
	        "if(r==true)" .
	                "{" .
	                        "window.location='index.php?go=power&amp;a_machines[]=" . $machine->get_id() . "&amp;action=stop';" .
	                "}";
	        echo "\" />";
	}
	else {
		echo "<img src=\"images/icon-start-grey.png\" alt=\"Powercycling for " . $machine->get_hostname(). "is not supported" . "\" title=\"Powercycling for "
			. $machine->get_hostname() . " is not supported" . "\" border=\"0\" " .
				"width=\"20\" style=\"padding-right: 3px;\" ";
		echo "\" />";

		echo "<img src=\"images/icon-restart-grey.png\" alt=\"Powercycling for " . $machine->get_hostname(). "is not supported" . "\" title=\"Powercycling for "
			. $machine->get_hostname() . " is not supported" . "\" border=\"0\" " .
				"width=\"20\" style=\"padding-right: 3px;\" ";
		echo "\" />";

		echo "<img src=\"images/icon-stop-grey.png\" alt=\"Powercycling for " . $machine->get_hostname() . "is not supported" . "\" title=\"Powercycling for "
			. $machine->get_hostname() . " is not supported" . "\" border=\"0\" " .
				"width=\"20\" style=\"padding-right: 3px;\" ";
		echo "\" />";
	}
?>

<?php if(preg_match ('/^vm\//', $machine->get_type())) { ?>
			<img src="images/icon-reinstall.png" alt="Reinstall this machine" title="Reinstall <?php echo($machine->get_hostname()); ?>" border="0" width="20" style="padding-left: 3px; padding-right: 3px;" onclick="alert('It is not possible to reinstall virtual machine!');"/>
<?php } else { ?>
			<a href="index.php?go=reinstall&amp;a_machines[]=<?php echo($machine->get_id()); ?>"><img src="images/icon-reinstall.png" alt="Reinstall this machine" title="Reinstall <?php echo($machine->get_hostname()); ?>" border="0" width="20" style="padding-left: 3px; padding-right: 3px;" /></a>
<?php } ?>
			<a href="index.php?go=edit_machines&amp;a_machines[]=<?php echo($machine->get_id()); ?>"><img src="images/icon-edit.png" alt="Edit/reserve this machine" title="Edit/reserve <?php echo($machine->get_hostname()); ?>" border="0" width="20" style="padding-right: 3px;" /></a>
<?php
			echo "\t\t\t<img src=\"images/icon-unlock.png\" alt=\"Free up this machine\" title=\"Free up ". $machine->get_hostname()."\" border=\"0\" " .
				"width=\"20\" style=\"padding-right: 3px;\" " .
				"onclick=\"";
			if(trim($machine->get_used_by()) == "" and trim($machine->get_usage()) == "")
			{
				echo "alert('This machine is already free!');";
			}
			else
			{
				echo "var r = confirm('This will clear the \'Used by\' and \'Usage\' fields, making the selected machines free to use by anyone else. Are you sure you want to continue?');" .
					"if(r==true)" .
					"{" .
						"window.location='index.php?go=edit_machines&amp;a_machines[]=" . $machine->get_id() . "&amp;action=clear';" .
					"}";
			}
			echo "\" />\n";
?>
			<a href="index.php?go=send_job&amp;a_machines[]=<?php echo($machine->get_id()); ?>"><img src="images/icon-job.png" alt="Send a job to this machine" title="Send a job to <?php echo($machine->get_hostname()); ?>" border="0" width="20" style="padding-right: 3px;" /></a>
			<a href="http://<?php echo($machine->get_ip_address()); ?>:5801" target="_blank"><img src="images/icon-vnc.png" alt="Open a VNC viewer" title="Open a VNC viewer on <?php echo($machine->get_hostname());?>" border="0" width="20" style="padding-right: 3px;" /></a>
			<a href="http://<?php echo($_SERVER['SERVER_ADDR']); ?>/ajaxterm/?host=<?php echo($machine->get_ip_address()); ?>" target="_blank"><img src="images/icon-terminal.png" alt="Access the terminal" title="Access the terminal on <?php echo($machine->get_hostname());?>" border="0" width="20" style="padding-right: 3px;" /></a>
<?php if(preg_match ('/^vm\//', $machine->get_type())) { ?>
			<img src="images/icon-delete.png" alt="Delete this machine and all related data" title="Delete <?php echo($machine->get_hostname()); ?> and all related data" border="0" width="20" style="padding-right: 3px;" onclick="alert('It is not possible to delete virtual machine in this view! Virtual machine can only be deleted in QA Cloud view.');" /></a>
<?php } else { ?>
			<a href="index.php?go=del_machines&amp;a_machines[]=<?php echo($machine->get_id()); ?>"><img src="images/icon-delete.png" alt="Delete this machine and all related data" title="Delete <?php echo($machine->get_hostname()); ?> and all related data" border="0" width="20" style="padding-right: 3px;" /></a>
<?php } ?>
		</td>
	</tr>
	<?php endforeach; ?>
  </tbody>
</table>
<script type="text/javascript">
<!--
var TSort_Data = new Array ('machines','', '0' <?php echo str_repeat(", 'h'",count($display_fields)+1); ?>);
tsRegister();
-->
</script>
<select name="action">
<!--  <option value="">No action</option> -->
  <option value="send_job">Send job</option>
  <option value="edit">Edit/reserve</option>
  <option value="reinstall">Reinstall</option> 
  <option value="create_group">Add to group</option>
  <option value="group_del_machines">Remove from group</option>
  <option value="vhreinstall">Reinstall as Virtualization Host</option> 
  <option value="upgrade">upgrade to higher</option> 
<!--   <option value="create_autobuild">Add to Autobuild</option> -->
<!--   <option value="delete_autobuild">Remove from Autobuild</option> -->
  <option value="merge_machines">Merge machines(experimental)</option>
  <option value="delete">Delete</option>
</select>
<input type="submit" value="Go">
<a onmouseout="MM_swapImgRestore()" onmouseover="MM_swapImage('qmark1','','../hamsta/images/qmark1.gif',1)">
<img src="../hamsta/images/qmark.gif" name="qmark1" id="qmark1" border="0" width="18" height="20" title="actions to selected machine(s)" onclick="window.open('../hamsta/helps/actions.html', 'channelmode', 'width=550, height=450, top=250, left=450')"/></a>
</form>
<?php
	# Left column, search box
	echo "<div style=\"float: left; width: 425px;\">";
?>
<h2 class="text-medium text-blue bold">Search</h2>
<div class="text-main">Change the fields below and then hit "Search" to filter the above list of machines based on your selections.</div><br />
<form action="index.php?go=machines" method="post">
<table class="sort text-main" style="border: 1px solid #cdcdcd;">
	<tr>
		<th valign="top">hwinfo result: </th>
		<td>
			<select name="s_anything_operator">
				<option value="like" <?php if (request_str("s_anything_operator") == "like") echo('selected'); ?>>contains</option>
				<option value="equals" <?php if (request_str("s_anything_operator") == "equals") echo('selected'); ?>>is</option>
			</select>
			<input name="s_anything" value='<?php echo(request_str("s_anything")); ?>'>
			<a onmouseout="MM_swapImgRestore()" onmouseover="MM_swapImage('qmark2','','../hamsta/images/qmark1.gif',1)">
			<img src="../hamsta/images/qmark.gif" name="qmark2" id="qmark2" border="0" width="18" height="20" title="hwinfo search" onclick="window.open('../hamsta/helps/hwinfo.html', 'channelmode', 'width=550, height=450, top=250, left=450')"/></a>
		</td>
	</tr>
	<tr>
		<th valign="top">Installed Arch: </th>
		<td>
			<select name="architecture">
				<option value="">Any</option>
				<?php foreach(Machine::get_architectures() as $archid => $arch): ?>
					<option value="<?php echo($arch); ?>" <?php if (request_str("architecture") == $arch) echo('selected'); ?>><?php echo($arch); ?></option>
				<?php endforeach;?>
			</select>
		</td>
	</tr>
	<tr>
		<th valign="top">CPU Arch: </th>
		<td>
			<select name="architecture_capable">
				<option value="">Any</option>
				<?php foreach(Machine::get_architectures_capable() as $archid => $arch): ?>
					<option value="<?php echo($arch); ?>" <?php if (request_str("architecture_capable") == $arch) echo('selected'); ?>><?php echo($arch); ?></option>
				<?php endforeach;?>
			</select>
		</td>
	</tr>
	<tr>
		<th valign="top">Status: </th>
		<td>
			<select name="status_string">
				<option value="">Any</option>
				<?php foreach(Machine::get_statuses() as $status_id => $status_string): ?>
					<option value="<?php echo($status_string); ?>" <?php if (request_str("status_string") == $status_string) echo("selected") ?>><?php echo($status_string); ?></option>
				<?php endforeach;?>
			</select>
		</td>
	</tr>
	<tr>
		<th valign="top">Display fields: </th>
		<td>
		<select name="d_fields[]" size=<?php echo sizeof($fields_list);?> multiple>
			  <?php
				foreach ($fields_list as $key=>$value) {
					echo("\t\t\t\t\t<option value=$key");
					if (in_array($key, $display_fields))
						echo(' selected');
					echo (" >$value</option>\n");
				}
			  ?>
			</select>
		</td>
	</tr>
	<tr>
		<td colspan="2" align="center">
			<input type="submit" value="Search" style="background-color: #eeeeee; width: 100%; padding: 3px;" class="text-medium">
		</td>
	</tr>
</table>
<?php
	echo "</div>";
	# Right column, latest features (here temporarily until we get a flashy new global WebUI)
	echo "<div style=\"float: left; width: 425px; margin-left: 20px;\">\n";
		echo "<h2 class=\"text-medium text-blue bold\">Latest Features</h2>\n";
		echo "<div class=\"text-main\">We are always working hard to create new, useful features to make your testing easier. Below, you will find just a few of these new capabilities that have been added recently. Check back here after each release to see what's new!</div><br />\n";
		echo "<div style=\"border: 1px solid #cdcdcd; padding: 5px;\" class=\"text-main\">\n";
			echo "<div style=\"border: 0px solid green;\">\n";
			$totalFeatureCount = 0;
			$maximumToShow = 10;
			foreach($latestFeatures as $release => $featureArray)
			{
				echo ($totalFeatureCount == 0 ? "" : "<br /><br />") . "<div class=\"text-main text-orange bold\">$release Release</div>\n";
				for($i = 0; $i < count($featureArray); $i++)
				{
					# Should we show a "See More" button?
					$totalFeatureCount++;
					if($totalFeatureCount > $maximumToShow)
					{
						echo "\t<div id=\"morefeatures-button\" style=\"border: 0px solid red;\"><br /><a href=\"#\" onclick=\"document.getElementById('morefeatures').style.display = 'block'; document.getElementById('morefeatures-button').style.display = 'none'; document.getElementById('morefeatures-button-2').style.display = 'block';\">See More</a></div>\n";
						echo "</div>\n";
						echo "<div id=\"morefeatures\" style=\"display: none; border: 0px solid blue;\">\n";
					}
					# Actually show the feature
					$descriptionSplit = explode(" -- ", $featureArray[$i], 3);
					echo ($totalFeatureCount != $maximumToShow+1 ? "<br />" : "") . "&bull; <strong>$descriptionSplit[0]:</strong> $descriptionSplit[1] <a href=\"#\" onclick=\"window.open('../hamsta/helps/LatestFeatures.php?release=$release&index=$i', 'channelmode', 'width=550, height=450, top=250, left=450')\" class=\"text-small\">(more details)</a>\n";
				}
			}
			echo "</div>\n";
			if($totalFeatureCount > $maximumToShow)
			{
				echo "<div id=\"morefeatures-button-2\" style=\"display: none; border: 0px solid red;\"><br /><a href=\"#\" onclick=\"document.getElementById('morefeatures').style.display = 'none'; document.getElementById('morefeatures-button').style.display = 'block'; document.getElementById('morefeatures-button-2').style.display = 'none';\">Hide</a></div>\n";
			}
		echo "</div>\n";
	echo "</div>\n";
    echo "<div style=\"clear: left;\">&nbsp;</div>\n"
?>
