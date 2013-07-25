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
    echo ("<span class=\"bold text-red\">Using filter</span>&nbsp;&nbsp;");
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
	    $filter_description = "\n\t" . '<span class="bold">Hwinfo</span>';
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
	    /* Used by contains user id but login has to be displayed. */
	    if ($key == 'used_by')
	    {
		    if ( isset($value) && ($value == 'free' || $value == 'others'))
		    {
			//do nothing special
		    }
		    else
		    {
			    $usr = User::getById ($value, $config);
			    $value = $usr->getLogin ();	
		    }
	    }
	    $filter_description = "\n\t" . '<span class="bold">' . $fields_list[$key] . '</span> is "' . $value . '"';
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
<form id="filter" method="post">
                <div>
                        Machines:
      <?php
			if (isset($ns_machine_filter->fields) && isset($ns_machine_filter->fields["used_by"]))
			{
				$rough_filter_value = $ns_machine_filter->fields["used_by"];
			}
                        if ( isset($user))
                        {
				if (isset($rough_filter_value) && ($user->getId() == $rough_filter_value))
					echo "<input type=\"checkbox\" name=\"my\" id=\"my\" checked/>";
				else
					echo "<input type=\"checkbox\" name=\"my\" id=\"my\"/>";
				echo "<label for=\"my\">my</label>";
                        }
			if (isset($rough_filter_value) && 'free'==$rough_filter_value)
                        	echo "<input type='checkbox' name='free' id='free' checked/>";
			else
                        	echo "<input type='checkbox' name='free' id='free'/>";
	?>
                        <label for="free">free</label>
<?php
			if (isset($rough_filter_value) && 'others'==$rough_filter_value)
                        	echo "<input type='checkbox' name='others' id='others' checked/>";
			else
                        	echo "<input type='checkbox' name='others' id='others'/>";
?>
                        <label for="others">others</label>

                        <label for="show_advanced" id="label_advanced">&dArr; advanced &dArr;</label>
                        <input type="checkbox" name="show_advanced" id="show_advanced" class="hider"/>
                        <div id="advanced">
                                <table id="adv_tbl">
					<tr>
						<th>Search in hwinfo: </th>
						<td>
                        				<input type="checkbox" name="searchhwinfo" id="searchhwinfo" checked/>
						</td>
					</tr>
                                        <tr id='hwinfo_search_ret'>
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
							?>'/>
                                                </td>
                                        </tr>
                                        <tr>
                                                <th valign="top">Installed Arch: </th>
                                                <td>
                                                        <select name="architecture">
                                                                <option value="">Any</option>
								<?php foreach(Machine::get_architectures() as $archid => $arch): ?>
                                        			<option value="<?php echo($arch); ?>"
  								<?php /* Function from include/Util.php*/
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
                                                                <option value="" selected="selected">Any</option>
								<?php foreach(Machine::get_architectures_capable() as $archid => $arch): ?>
                                        			<option value="<?php echo($arch); ?>"
          							<?php if (isset ($ns_machine_filter) && machine_filter_value_selected ('architecture_capable', $arch, $ns_machine_filter))
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
                                        <tr><th>Type</th><td><select name="type">
						<?php foreach(Machine::get_all_hwtype() as $type): ?>
						<option value="<?php echo($type); ?>"
						<?php if (isset ($ns_machine_filter) && machine_filter_value_selected ('type', $type, $ns_machine_filter))
						{
							echo(' selected="selected"');
						}
						?>><?php echo($type); ?></option>
                                                <?php endforeach;?>
                                                        </select></td></tr>
                                </table>

                        </div>
                </div>
                <div>
                        <nobr>
                        <div id="fulltext_input">
                                <input type="text" id="fulltext" name="fulltext" class="inputctrl" placeholder="Fulltext search"/>
                                <input type="button" value="x" name="x" id="x" class="inputctrl"/>
                                <input type="submit" value="Search" name="set" id="submit" class="inputctrl"/>
                        </div>
                        <input type="checkbox" name="searchall" id="searchall"/><label for="searchall" id="searchlabel">Search hidden field</label>

                       <input type="checkbox" name="displmatch" id="displmatch"/><label for="displmatch" id="displabel">Hide matching columns</label>
</nobr>
                </div>
</form>
<div id="blindwall"> </div>
<form action="index.php?go=machines" method="post" name="machine_list" onSubmit="return checkcheckbox(this)">
<table class="list text-main" id="machines">
  <thead>
	<tr>
		<th><input type="checkbox" onChange='chkall("machine_list", this)'></th>
		<th><?php print ($fields_list['hostname']); ?></th>
		<th><?php print ($fields_list['status_string']); ?></th>
		<th><?php print ($fields_list['used_by']); ?></th>
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

    <td title="<?php echo($machine->get_notes()); ?>"><a href="index.php?go=machine_details&amp;id=<?php echo($machine->get_id()); ?>&amp;highlight=<?php echo($highlight); ?>"><?php echo($machine->get_hostname()); ?></a><?php if ($machine->count_host_collide() >= 2) echo '<img src="images/27/host-collide.png" class="icon-notification" title="Hostnames collide! Merge or delete machine if MAC was changed, otherwise rename it.">'; ?></td>
		    
    <td class="<?php print (get_machine_status_class ($machine->get_status_id ())); ?>"><?php echo($machine->get_status_string());
	$rh = new ReservationsHelper ();
	if (isset ($machine) && isset ($user)) {
		$users_machine = $rh->getForMachineUser ($machine, $user);
	}
	if ($machine->get_update_status())
	  {
	    if ($config->authentication->use && ! (isset ($user)
		&& ((isset ($users_machine) && $user->isAllowed ('machine_reinstall'))
				   || ($user->isAllowed ('machine_reinstall_reserved')))))
	      {
		echo('<img src="images/27/exclamation_gray.png" class="icon-notification" alt="Tools out of date!" title="Tools out of date. You cannot update ' . $machine->get_hostname () . ' if not logged in, without privileges or if it is reserved by another user." onclick="alert(\'You cannot update this machine.\');">');
	      }
	    else
	      {
		echo('<a href="index.php?go=machine_send_job&a_machines[]='.$machine->get_id().'&filename[]='.$config->xml->dir->default.'/hamsta-upgrade-restart.xml&submit=1"><img src="images/27/exclamation_yellow.png" class="icon-notification" alt="Tools out of date!" title="Click to update ' . $machine->get_hostname () . '"></a>');
	      }
	  }

	if ($machine->get_devel_tools()) echo('<img src="images/27/gear-cog_blue.png" class="icon-notification" alt="Devel Tools" title="Devel Tools">'); ?></td>
<?php
$rh = new ReservationsHelper ($machine);
$users_string = $rh->prettyPrintUsers ();
print ('<td title="' . $users_string
       . '"><div class="ellipsis-no-wrapped machine_table_usedby">'
       . $users_string . "</div></td>\n");

foreach ($fields_list as $key=>$value)
{
	$res = '';
	$fname = "get_".$key;
	if (method_exists ($machine, $fname)) {
		$res = $machine->$fname();
	}
	if (isset ($display_fields) && in_array($key, $display_fields))
		echo ("\t<td>$res</td>\n");
}
?>
		<td align="center">

<?php print machine_icons($machine,$user); ?>
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

var height = $(window).height(); 
var width = $(window).width(); 
var originLeft = $("#filter").css("left");
var hoverThreshold = $("#header").height() + $("#filter").height() + $("h1").height();
var originTheadWidth = $('#machines thead').width();
var isChrome = navigator.userAgent.toLowerCase().match(/chrome/) != null;
//console.log('hoverthreshold ' + hoverThreshold);
$(window).scroll(function(){
    var scrollTop = $(window).scrollTop();
    if (scrollTop > hoverThreshold)
    {
        $('#filter').css("z-index", 10).css("position", "fixed").css('top', '0px');
	if (isChrome)
		$("#machines thead").css("z-index",9).css("position","fixed").css("top","102px"); 
        else
		$("#machines thead").css("z-index",9).css("position","fixed").css("top","87px"); 
	$("#machines tr:first-child td").each(function(index) {
            var ind = index + 1;
            if ( $(this).width() > $("#machines th:nth-child("+ind+")").width() )
               	$("#machines th:nth-child("+ind+")").css("width",$(this).width());
            else
                $(this).css("width",$("#machines th:nth-child("+ind+")").width());
        });
	if (isChrome)
        	$("#blindwall").css("position","fixed").css("display","inline").css("z-index",8).css("width","100%").css("height","102px").css("top","0px");
	else 
        	$("#blindwall").css("position","fixed").css("display","inline").css("z-index",8).css("width","100%").css("height","87px").css("top","0px");
    }
    else
    {
        $('#filter').css("z-index", 10).css("position", "relative").css("left", originLeft);
	$("#machines thead").css("z-index",0).css("position","relative");
        $("#blindwall").css("position","relative").css("display","none").css("z-index",-1);
    }
});

$("#searchhwinfo").click(function(){
    if ($(this).is(':checked'))
    {
        $("#hwinfo_search_ret").css('display', '');	
    }
    else
    {
        $("#hwinfo_search_ret").css('display', 'none');	
    }
});
</script>
</form>
<input type="checkbox" id="actionCheck">
<label id="action" class="action" for="actionCheck">
<form id="action">
<h3>&darr;  Action  &darr;</h3>
<input type="checkbox" id="blkAni">
<label class="noani" for="blkAni">
<select name="action">
<!--  <option value="">No action</option> -->
  <option value="machine_send_job">Send job</option>
  <option value="addsut">Add SUT</option>
  <option value="edit">Edit/reserve</option>
  <option value="machine_reinstall">Reinstall</option>
  <option value="create_group">Add to group</option>
  <option value="group_del_machines">Remove from group</option>
  <option value="vhreinstall">Reinstall as Virtualization Host</option>
  <option value="upgrade">Upgrade to higher</option>
<!--   <option value="create_autobuild">Add to Autobuild</option> -->
<!--   <option value="delete_autobuild">Remove from Autobuild</option> -->
  <option value="merge_machines">Merge machines</option>
  <option value="machine_config">Configure machines</option>
  <option value="delete">Delete</option>
</select>
</label>
<br/>
<input type="submit" value="Go">
</form>
</label>
<input type="checkbox" id="fieldsCheck">
<label id="fields" class="fields" for="fieldsCheck">
<form id="fields" method="post">
        <h3>&darr;  Display fields  &darr;</h3>
        <input type="checkbox" id="blkAni">
	<label class="noani" for="blkAni">
	<div id="fields_list">
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
                    echo("\t\t\t\t\t<input type=\"checkbox\" name=\"DF_$key\" id=$key");
                    if ( isset ($display_fields ) && in_array($key, $display_fields))
                    {
                        echo(' checked="checked">');
                    }
                    echo("<label for=$key>$value</label><br>");
                }
        ?>
        </div>
	</label>
        <input type="submit" value="show"/>
</form>
</label>
