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
  $go = 'qacloud';
  return require("index.php");
}
?>

<?php foreach ($machines as $machine): ?>
<form action="index.php?go=qacloud" method="post" name="<?php echo "vh_".$machine->get_hostname(); ?>" id="<?php echo "vh_".$machine->get_hostname(); ?>">
<div id="vhost_vms" style="float:left; width:100%;">
  <div id="vhost_details" style="float:left; width:30%;" class="vhost_details <?php if (($machine->get_status_id() == MS_DOWN) && ($machine->is_busy())): ?> crashed_job<?php endif; ?>" >
    <span class="bold">Virt-Host: </span>&nbsp;<span title="<?php echo($machine->get_notes()); ?>">
      <a href="index.php?go=machine_details&amp;id=<?php echo($machine->get_id()); ?>&amp;highlight=<?php echo($highlight); ?>"><?php echo($machine->get_hostname()); ?></a>
    </span>&nbsp;<span class="bold">Actions</span>
    <span>
      <?php if(count($machine->get_children()) > 0) { ?>
        <img src="images/icon-reinstall.png" alt="Reinstall this virtualization host" title="Reinstall <?php echo($machine->get_hostname()); ?>" border="0" width="20" style="padding-left: 3px; padding-right: 3px;" onclick="alert('It is not possible to reinstall virtualization host that contain virtual machine(s)!');"/>
        <?php } else { ?>
        <a href="index.php?go=vhreinstall&amp;a_machines[]=<?php echo($machine->get_id()); ?>"><img src="images/icon-reinstall.png" alt="Reinstall this virtualization host" title="Reinstall <?php echo($machine->get_hostname()); ?>" border="0" width="20" style="padding-left: 3px; padding-right: 3px;" /></a>
      <?php } ?>
      <a href="index.php?go=edit_machines&amp;a_machines[]=<?php echo($machine->get_id()); ?>"><img src="images/icon-edit.png" alt="Edit/reserve this machine" title="Edit/reserve <?php echo($machine->get_hostname()); ?>" border="0" width="20" style="padding-right: 3px;" /></a>
      <?php
        echo "\t\t\t<img src=\"images/icon-unlock.png\" alt=\"Free up this machine\" title=\"Free up ". $machine->get_hostname()."\" border=\"0\" " .
          "width=\"20\" style=\"padding-right: 3px;\" " .
          "onclick=\"";
        if(trim($machine->get_used_by()) == "" and trim($machine->get_usage()) == "") {
            echo "alert('This machine is already free!');";
        } else {
            echo "var r = confirm('This will clear the \'Used by\' and \'Usage\' fields, making the selected machines free to use by anyone else. Are you sure you want to continue?');" .
            "if(r==true)" .
            "{" .
              "window.location='index.php?go=edit_machines&amp;a_machines[]=" . $machine->get_id() . "&amp;action=clear';" .
            "}";
        }
            echo "\" />\n";
        ?>
      <a href="index.php?go=newvm&amp;a_machines[]=<?php echo($machine->get_id()); ?>"><img src="images/icon-newvm.png" alt="Create new virtual machine" title="Create new virtual machine SUT on <?php echo($machine->get_hostname()); ?>" border="0" width="20" style="padding-right: 3px;" /></a>
      <a href="http://<?php echo($machine->get_ip_address()); ?>:5801" target="_blank"><img src="images/icon-vnc.png" alt="Open a VNC viewer" title="Open a VNC viewer on <?php echo($machine->get_hostname());?>" border="0" width="20" style="padding-right: 3px;" /></a>
      <a href="http://<?php echo($_SERVER['SERVER_ADDR']); ?>/ajaxterm/?host=<?php echo($machine->get_ip_address()); ?>" target="_blank"><img src="images/icon-terminal.png" alt="Access the terminal" title="Access the terminal on <?php echo($machine->get_hostname());?>" border="0" width="20" style="padding-right: 3px;" /></a>
      <?php if(count($machine->get_children()) > 0) { ?>
        <img src="images/icon-delete.png" alt="Delete this machine and all related data" title="Delete <?php echo($machine->get_hostname()); ?> and all related data" border="0" width="20" style="padding-right: 3px;" onclick="alert('It is not possible to delete virtualization host that contain virtual machine(s)!');" /></a>
      <?php } else { ?>
        <a href="index.php?go=del_machines&amp;a_machines[]=<?php echo($machine->get_id()); ?>"><img src="images/icon-delete.png" alt="Delete this machine and all related data" title="Delete <?php echo($machine->get_hostname()); ?> and all related data" border="0" width="20" style="padding-right: 3px;" /></a>
      <?php } ?>
      </span>
      <table class="text-medium">
      <?php
        foreach ($fields_list as $key=>$value)
          if (in_array($key, $vh_display_fields)) {
          $fname = "get_".$key;
          $res = $machine->$fname();
          echo("<tr><th>$value</th><td>$res</td></tr>\n");
        }
      ?>
      </table>
  </div>
  <div id="vm_table" style="float:right; width:65%; margin:1em;">
    <table class="list text-main" id="<?php echo "vm_".($machine->get_hostname()); ?>">
      <thead>
      <tr>
      <th><input type="checkbox" onChange='chkall("machine_list", this)'></th>
        <th>Name</th>
          <?php foreach ($fields_list as $key=>$value)
                if (in_array($key, $vm_display_fields))
                  echo("<th>$value</th>");
          ?>
        <th>Actions</th>
      </tr>
      </thead>
      <tbody>
      <?php foreach ($machine->get_children() as $vm): ?>
        <tr
          <?php if (($vm->get_status_id() == MS_DOWN) && ($vm->is_busy())): ?>
            class="crashed_job"
          <?php endif; ?>
        >
          <td><input type="checkbox" name="a_machines[]" value="<?php echo($vm->get_id()); ?>" <?php if (in_array($vm->get_id(), $a_machines)) echo("checked"); ?>></td>
          <td title="<?php echo($vm->get_notes()); ?>"><a href="index.php?go=machine_details&amp;id=<?php echo($vm->get_id()); ?>&amp;highlight=<?php echo($highlight); ?>"><?php echo($vm->get_hostname()); ?></a></td>
          <?php foreach ($fields_list as $key=>$value){
            $fname = "get_".$key;
            $res = $vm->$fname();
            if (in_array($key, $vm_display_fields))
              echo ("<td>$res</td>");
            }
          ?>
          <td align="center">
            <a href="index.php?go=edit_machines&amp;a_machines[]=<?php echo($vm->get_id()); ?>"><img src="images/icon-edit.png" alt="Edit/reserve this machine" title="Edit/reserve <?php echo($vm->get_hostname()); ?>" border="0" width="20" style="padding-right: 3px;" /></a>
            <?php
               echo "\t\t\t<img src=\"images/icon-unlock.png\" alt=\"Free up this machine\" title=\"Free up ". $vm->get_hostname()."\" border=\"0\" " ."width=\"20\" style=\"padding-right: 3px;\" " . "onclick=\"";
                 if(trim($vm->get_used_by()) == "" and trim($vm->get_usage()) == "") {
                   echo "alert('This machine is already free!');";
                 } else {
                   echo "var r = confirm('This will clear the \'Used by\' and \'Usage\' fields, making the selected machines free to use by anyone else. Are you sure you want to continue?');" .
                   "if(r==true) {" .
                     "window.location='index.php?go=edit_machines&amp;a_machines[]=" . $vm->get_id() . "&amp;action=clear';" .
                   "}";
                 }
                   echo "\" />\n";
              ?>
            <a href="index.php?go=send_job&amp;a_machines[]=<?php echo($vm->get_id()); ?>"><img src="images/icon-job.png" alt="Send a job to this machine" title="Send a job to <?php echo($vm->get_hostname()); ?>" border="0" width="20" style="padding-right: 3px;" /></a>
            <a href="http://<?php echo($vm->get_ip_address()); ?>:5801" target="_blank"><img src="images/icon-vnc.png" alt="Open a VNC viewer" title="Open a VNC viewer on <?php echo($vm->get_hostname());?>" border="0" width="20" style="padding-right: 3px;" /></a>
            <a href="http://<?php echo($_SERVER['SERVER_ADDR']); ?>/ajaxterm/?host=<?php echo($vm->get_ip_address()); ?>" target="_blank"><img src="images/icon-terminal.png" alt="Access the terminal" title="Access the terminal on <?php echo($vm->get_hostname());?>" border="0" width="20" style="padding-right: 3px;" /></a>
            <a href="index.php?go=del_virtual_machines&amp;a_machines[]=<?php echo($vm->get_id()); ?>"><img src="images/icon-delete.png" alt="Delete this virtual machine and all related data" title="Delete <?php echo($vm->get_hostname()); ?> and all related data" border="0" width="20" style="padding-right: 3px;" /></a>
          </td>
         </tr>
      <?php endforeach; ?>
      </tbody>
    </table>
    <select name="action">
      <option value="">No action</option>
<!--  <option value="send_job">Send job</option> -->
<!--  <option value="edit">Edit/reserve</option> -->
<!--  <option value="reinstall">Reinstall</option>  -->
<!--  <option value="create_group">Add to group</option> -->
<!--  <option value="group_del_machines">Remove from group</option> -->
<!--  <option value="autopxe">AutoPXE</option> -->
<!--   <option value="create_autobuild">Add to Autobuild</option> -->
<!--   <option value="delete_autobuild">Remove from Autobuild</option> -->
<!--  <option value="delete">Delete</option> -->
    </select>
    <input type="submit" value="Go">
    <a onmouseout="MM_swapImgRestore()" onmouseover="MM_swapImage('qmark1','','../hamsta/images/qmark1.gif',1)">
    <img src="../hamsta/images/qmark.gif" name="qmark1" id="qmark1" border="0" width="18" height="20" title="actions to selected machine(s)" onclick="window.open('../hamsta/helps/actions.html', 'channelmode', 'width=550, height=450, top=250, left=450')"/></a>
  </div>
  <script type="text/javascript">
  <!--
  var TSort_Data = new Array ('<?php echo "vm_".($machine->get_hostname()); ?>','', '0' <?php echo str_repeat(", 'h'",count($vh_display_fields)); ?>);
  tsRegister();
  -->
  </script>
</div>
</form>
<div style="clear both"></div>
<?php endforeach; ?>
<?php
  # Left column, search box
?>
<hr>
<h2 class="text-medium text-blue bold">Search</h2>
<div class="text-main">Change the fields below and then hit "Search" to filter the above list of machines based on your selections.</div><br />
<form action="index.php?go=qacloud" method="post">
<table class="sort text-main" style="border: 1px solid #cdcdcd;">
  <tr>
    <th valign="top">VH hwinfo result: </th>
    <td>
      <select name="s_anything_operator">
        <option value="like" <?php if (request_str("s_anything_operator") == "like") echo('selected'); ?>>contains</option>
        <option value="equals" <?php if (request_str("s_anything_operator") == "equals") echo('selected'); ?>>is</option>
      </select>
      <input name="s_anything" value="<?php echo(request_str("s_anything")); ?>">
      <a onmouseout="MM_swapImgRestore()" onmouseover="MM_swapImage('qmark2','','../hamsta/images/qmark1.gif',1)">
      <img src="../hamsta/images/qmark.gif" name="qmark2" id="qmark2" border="0" width="18" height="20" title="hwinfo search" onclick="window.open('../hamsta/helps/hwinfo.html', 'channelmode', 'width=550, height=450, top=250, left=450')"/></a>
    </td>
  </tr>
<!--  <tr>
    <th valign="top">Installed Arch: </th>
    <td>
      <select name="s_arch">
        <option value="">Any</option>
        <?php foreach(Machine::get_architectures() as $archid => $arch): ?>
          <option value="<?php echo($archid); ?>" <?php if (request_str("s_arch") == $archid) echo('selected'); ?>><?php echo($arch); ?></option>
        <?php endforeach;?>
      </select>
    </td>
  </tr>
  <tr>
    <th valign="top">CPU Arch: </th>
    <td>
      <select name="s_archc">
        <option value="">Any</option>
        <?php foreach(Machine::get_architectures_capable() as $archid => $arch): ?>
          <option value="<?php echo($archid); ?>" <?php if (request_str("s_archc") == $archid) echo('selected'); ?>><?php echo($arch); ?></option>
        <?php endforeach;?>
      </select>
    </td>
  </tr>
  <tr>
    <th valign="top">Status: </th>
    <td>
      <select name="s_status">
        <option value="">Any</option>
        <?php foreach(Machine::get_statuses() as $status_id => $status_string): ?>
          <option value="<?php echo($status_id); ?>" <?php if (request_str("s_status") == $status_id) echo("selected") ?>><?php echo($status_string); ?></option>
        <?php endforeach;?>
      </select>
    </td>
  </tr>  -->
  <tr>
    <th valign="top">Display fields:</th>
    <td>
    <table>
    <thead>
      <tr><th>VH</th><th>VM (SUT)</th></tr>
    </thead>
    <tbody>
    <tr><td>  
    <select name="vh_d_fields[]" size=<?php echo sizeof($fields_list);?> multiple>
        <?php
        foreach ($fields_list as $key=>$value) {
          echo("\t\t\t\t\t<option value=$key");
          if (in_array($key, $vh_display_fields))
            echo(' selected');
          echo (" >$value</option>\n");
        }
        ?>
      </select>
    </td>
    <td>
    <select name="vm_d_fields[]" size=<?php echo sizeof($fields_list);?> multiple>
        <?php
        foreach ($fields_list as $key=>$value) {
          echo("\t\t\t\t\t<option value=$key");
          if (in_array($key, $vm_display_fields))
            echo(' selected');
          echo (" >$value</option>\n");
        }
        ?>
      </select>
    </td></tr>
    </tbody>
    </table>
    </td>
  </tr>
  <tr>
    <td colspan="2" align="center">
      <input type="submit" value="Search" style="background-color: #eeeeee; width: 100%; padding: 3px;" class="text-medium">
    </td>
  </tr>
</table>
<?php
  echo "</div>\n";
  echo "<div style=\"clear: left;\">&nbsp;</div>\n";
?>
</form>
