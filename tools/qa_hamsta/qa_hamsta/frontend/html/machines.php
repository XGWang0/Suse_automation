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

/* Print information about filter if it is used. */
if (isset ($ns_machine_filter->fields)
    && count ($ns_machine_filter->fields) > 0)
  {
    echo ("<form action=\"index.php?go=machines\" method=\"post\">\n");
    echo ("<div>\n");
    /* Styles should be in separate css files. */
    echo ("<span style=\"font-weight: bold; color: #dd4444\">Using filter</span>&nbsp;&nbsp;");
    foreach ($ns_machine_filter->fields as $key => $value)
      {
	/* Fix displaying of description for filtering using hwinfo.
	 *
	 * WARNING! In PHP the continue statement does not work within
	 * switch block nested in foreach loop. Hence if statemens are
	 * used here. Just live with that. */
	if ($key == 's_anything')
	  {
	    continue;
	  }
	else if ($key == 's_anything_operator' && isset ($ns_machine_filter->fields['s_anything']))
	  {
	    $filter_description = "\n\t" . '<span style="font-weight: bold;">Hwinfo</span>';
	    switch ($value)
	      {
	      case "LIKE":
		$filter_description .= ' contains "' . $ns_machine_filter->fields['s_anything'] . '"';
		break;
	      case "=":
		$filter_description .= ' is "' . $ns_machine_filter->fields['s_anything'] . '"';
		break;
	      default:
		/* This shoud not be displayed. Never ever. */
		$value = ' has ';
	      }
	  }
	else
	  {
	    $filter_description = "\n\t" . '<span style="font-weight: bold;">' . $fields_list[$key] . '</span> is "' . $value . '"';
	  }
	
	echo ("<span>$filter_description</span>&nbsp;&nbsp;");
      }


    /* Add a button to clear the filters. */
    echo ("  <input type=\"submit\" value=\"Reset\" name=\"reset\">\n");
    echo ("\n</div>\n");
    echo ("</form>\n");
  }

/* Getting 's_anything' and 's_anything_operator' values for later use. */
if (request_str ('set') == 'Search')
  {
    $s_anything = request_str ('s_anything');
  }
else if (isset ($ns_machine_filter->fields['s_anything']))
  {
    $s_anything = $ns_machine_filter->fields['s_anything'];
  }

if (! empty ($s_anything))
  {
    $s_anything_operator = request_operator("s_anything_operator");

    if (empty ($s_anything_operator)
	&& isset ($ns_machine_filter->fields['s_anything_operator']))
      {
	$s_anything_operator = $ns_machine_filter->fields['s_anything_operator'];
      }
  }

?>

<form action="index.php?go=machines" method="post" name="machine_list" onSubmit="return checkcheckbox(this)">
<table class="list text-main" id="machines">
  <thead>
	<tr>
		<th><input type="checkbox" onChange='chkall("machine_list", this)'></th>
		<th>Hostname</th>
		<th>Status</th>
		<th>Used by</th>
		<?php
			foreach ($fields_list as $key=>$value)
                                if (isset ($display_fields) && in_array($key, $display_fields))
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

		<td><input type="checkbox" name="a_machines[]" value="<?php echo($machine->get_id()); ?>"<?php if (isset ($a_machines) && in_array($machine->get_id(), $a_machines)) echo(' checked="checked"'); ?>></td>

    <td title="<?php echo($machine->get_notes()); ?>"><a href="index.php?go=machine_details&amp;id=<?php echo($machine->get_id()); ?>&amp;highlight=<?php echo($highlight); ?>"><?php echo($machine->get_hostname()); ?></a><?php if ($machine->count_host_collide() >= 2) echo '<img src="images/host-collide.png" class="icon-notification" title="Hostnames collide! Merge or delete machine if MAC was changed, otherwise rename it.">'; ?></td>
		    
    <td><?php echo($machine->get_status_string());
	$users_machine = isset ($user) && $user->getId () == $machine->get_used_by ();
	if ($machine->get_update_status())
	  {
	    if ($config->authentication->use && ! (isset ($user)
			       && (($users_machine && $user->isAllowed ('machine_reinstall'))
				   || ($user->isAllowed ('machine_reinstall_reserved')))))
	      {
		echo('<img src="images/exclamation_gray.png" class="icon-notification" alt="Tools out of date!" title="Tools out of date. You cannot update ' . $machine->get_hostname () . ' if not logged in, without privileges or if it is reserved by another user." onclick="alert(\'You cannot update this machine.\');">');
	      }
	    else
	      {
		echo('<a href="index.php?go=send_job&a_machines[]='.$machine->get_id().'&filename[]='.$config->xml->dir->default.'/hamsta-upgrade-restart.xml&submit=1"><img src="images/exclamation_yellow.png" class="icon-notification" alt="Tools out of date!" title="Click to update ' . $machine->get_hostname () . '"></a>');
	      }
	  }

	if ($machine->get_devel_tools()) echo('<img src="images/gear-cog_blue.png" class="icon-notification" alt="Devel Tools" title="Devel Tools">'); ?></td>
	<?php $used_by_name = $machine->get_used_by_name($config);
                        echo ('<td>' . ( isset ($used_by_name)
                                             ? $used_by_name
                                             : $machine->get_used_by_login())
                              . "</td>\n"); ?>
<?php
  foreach ($fields_list as $key=>$value)
  {
    $fname = "get_".$key;
    $res = $machine->$fname();
    if (isset ($display_fields) && in_array($key, $display_fields))
      echo ("    <td>$res</td>\n");
  }
		?>
		<td align="center">

<?php
 require ('machine_actions.phtml');
?>
          </td>
	</tr>
	<?php endforeach; ?>
  </tbody>
</table>
<script type="text/javascript">
<!--
                          var TSort_Data = new Array ('machines','', '0' <?php echo str_repeat(", 'h'", (isset ($display_fields) ? count($display_fields)+2 : 1)); ?>);
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
  <option value="upgrade">Upgrade to higher</option> 
<!--   <option value="create_autobuild">Add to Autobuild</option> -->
<!--   <option value="delete_autobuild">Remove from Autobuild</option> -->
  <option value="merge_machines">Merge machines</option>
  <option value="delete">Delete</option>
</select>
<input type="submit" value="Go">
<a href="../hamsta/helps/actions.html" target="_blank">
  <img src="../hamsta/images/qmark.png" class="icon-small" name="qmark1" id="qmark1" title="actions to selected machine(s)" />
</a>
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
		<th>hwinfo result: </th>
		<td>
			<select name="s_anything_operator">
				<option value="like"
   <?php if (! empty ($s_anything)
	     && ! empty ($s_anything_operator)
	     && $s_anything_operator == 'LIKE')
	{
	    echo(' selected="selected"');
	}
  ?>>contains</option>
				<option value="equals"
  <?php if (! empty ($s_anything)
	     && ! empty ($s_anything_operator)
	     && $s_anything_operator == "=")
	  {
	    echo(' selected="selected"');
	  }
  ?>>is</option>
			</select>
			<input name="s_anything" value='<?php

	if (!empty ($s_anything))
	  {
		echo ($s_anything);
	  }
?>'>
			<a href="../hamsta/helps/hwinfo.html" target="_blank">
			<img src="../hamsta/images/qmark.png" class="icon-small" name="qmark2" id="qmark2" title="hwinfo search" /></a>
		</td>
	</tr>
	<tr>
		<th valign="top">Installed Arch: </th>
		<td>
			<select name="architecture">
				<option value="">Any</option>
				<?php foreach(Machine::get_architectures() as $archid => $arch): ?>
					<option value="<?php echo($arch); ?>"
  <?php	/* Function from include/Util.php*/
	$arch_reqest = request_str('architecture');
	if (isset ($ns_machine_filter) && machine_filter_value_selected ('architecture', $arch, $ns_machine_filter))
		{
			echo(' selected="selected"');
		}
  ?>><?php echo($arch);
  ?></option>
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
					<option value="<?php echo($arch); ?>"
	  <?php	if (isset ($ns_machine_filter) && machine_filter_value_selected ('architecture_capable', $arch, $ns_machine_filter))
		{
			echo(' selected="selected"');
		}
  ?>><?php echo($arch); ?></option>
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
					<option value="<?php echo($status_string); ?>"
	  <?php if (isset ($ns_machine_filter) && machine_filter_value_selected ('status_string', $status_string, $ns_machine_filter))
	{
		echo(' selected="selected"');
	}
  ?>><?php echo($status_string); ?></option>
				<?php endforeach;?>
			</select>
		</td>
	</tr>
	<tr>
		<th valign="top">Display fields: </th>
		<td>
		<select name="d_fields[]" size=<?php echo sizeof($fields_list);?> multiple="multiple">
		  <?php
			foreach ($fields_list as $key=>$value)
			{
			  /* Due to connection of displayed fields and
			   * filters I had to add an exception
			   * here. */
			  if (in_array ($key, $default_fields_list))
			    {
			      continue;
			    }

			  echo("\t\t\t\t\t<option value=$key");

			  if ( isset ($display_fields ) && in_array($key, $display_fields))
			    {
			      echo(' selected="selected"');
			    }

			  echo (">$value</option>\n");
			}
		  ?>
		</select>
		</td>
	</tr>
	<tr>
		<td colspan="2" align="center">
                  <input type="submit" value="Search" name="set" style="background-color: #eeeeee; width: 100%; padding: 3px;" class="text-medium">
                  <input type="submit" value="Reset" name="reset" style="background-color: #eeeeee; width: 100%; padding: 3px;" class="text-medium">
		</td>
	</tr>
</table>
</form>
</div>
<?php
	/* Right column, latest features (here temporarily until we get a flashy new global WebUI).
         * PK: Will we? */
        /* TODO fix ampersands */
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
