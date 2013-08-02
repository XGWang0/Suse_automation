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
   * Content of the <tt>qacloud</tt> page.
   */
if (!defined('HAMSTA_FRONTEND')) {
  $go = 'qacloud';
  return require("index.php");
}
?>

<?php foreach ($machines as $machine): ?>
<?php $rh = new ReservationsHelper ();
      $rh->getForMachine ($machine);
?>
<form action="index.php?go=qacloud" method="post" name="<?php echo "vh_".$machine->get_hostname(); ?>" id="<?php echo "vh_".$machine->get_hostname(); ?>">
<div id="vhost_vms" style="float:left; width:100%;">
  <div id="vhost_details" style="float:left; width:30%;" class="vhost_details <?php if (($machine->get_status_id() == MS_DOWN) && ($machine->is_busy())): ?> crashed_job<?php endif; ?>" >
    <span class="bold">Virt-Host: </span>&nbsp;<span title="<?php echo($machine->get_notes()); ?>">
      <a href="index.php?go=machine_details&amp;id=<?php echo($machine->get_id()); ?>&amp;highlight=<?php echo($highlight); ?>"><?php echo($machine->get_hostname()); ?></a>
    </span>&nbsp;<span class="bold">Actions</span>
    <span>

<?php
$mid = $machine->get_id ();
$hname = $machine->get_hostname ();
if (count ($machine->get_children ()) < 1) {
	print (task_icon ( array ('url'		=> 'index.php?go=vhreinstall&a_machines[]='
							. $mid,
				  'fullname'	=> 'reinstall',
				  'type'	=> 'reinstall',
				  'object'	=> $hname,
				  'confirm'	=> true
				   )));
}

print (task_icon ( array ('url'		=> 'index.php?go=machine_edit&a_machines[]='
						. $mid,
			  'fullname'	=> 'edit',
			  'type'	=> 'edit',
			  'object'	=> $hname,
			   )));

{ // Do not create global variables
	$enabled = false;
	$allowed = false;
	if (count ($rh->getReservations ())) {
		$enabled = true;
	}
	if( count ($rh->getForMachineUser ($machine, User::getCurrent ()))) {
		$allowed = true;
	}

	print (task_icon ( array ('url'		=> 'index.php?go=machine_edit&a_machines[]='
							. $mid . '&action=clear',
				  'fullname'	=> 'Free up',
				  'type'	=> 'free',
				  'allowed'	=> $allowed,
				  'err_noavail'	=> 'You do not have permissions to free '
							. $hname,
				  'enbl'	=> $enabled,
				  'err_noavail'	=> 'You can not free ' . $hname
				  . ' because it is already free.',
				  'object'	=> $hname,
				  'confirm'	=> true
				   )));
}

print (task_icon ( array ('url'		=> 'index.php?go=newvm&a_machines[]=' . $mid,
			  'type'	=> 'newvm',
			  'fullname'	=> 'Create a new virtual machine on',
			  'object'	=> $hname
			   )));

print (task_icon ( array ('url'		=> 'index.php?go=newvm-win&a_machines[]=' . $mid,
			  'type'	=> 'win',
			  'fullname'	=> 'Create new Windows virtual machine on',
			  'object'	=> $hname
			   )));

?>

      <a href="http://<?php echo($machine->get_ip_address()); ?>:5801" target="_blank"><img src="images/27/icon-vnc.png" alt="Open a VNC viewer" title="Open a VNC viewer on <?php echo($machine->get_hostname());?>" class="machine-actions icon-small"/></a>

      <a href="http://<?php echo($_SERVER['SERVER_ADDR']); ?>/ajaxterm/?host=<?php echo($machine->get_ip_address()); ?>" target="_blank"><img src="images/icon-terminal.png" alt="Access the terminal" title="Access the terminal on <?php echo($machine->get_hostname());?>" class="machine-actions icon-small"/></a>

      <?php if(count($machine->get_children()) > 0) { ?>
        <img src="images/icon-delete.png" alt="Delete this machine and all related data" title="Delete <?php echo($machine->get_hostname()); ?> and all related data" class="machine-actions icon-small" onclick="alert('It is not possible to delete virtualization host that contain virtual machine(s)!');" /></a>
      <?php } else { ?>
        <a href="index.php?go=machine_delete&amp;a_machines[]=<?php echo($machine->get_id()); ?>"><img src="images/icon-delete.png" alt="Delete this machine and all related data" title="Delete <?php echo($machine->get_hostname()); ?> and all related data" class="machine-actions icon-small"/></a>
      <?php } ?>
      </span>
      <table class="text-medium">
      <?php
	foreach ($fields_list as $key=>$value) {
		if (in_array($key, $vh_display_fields)) {
			$res = '';
			$fname = "get_".$key;
			$class = 'ellipsis-no-wrapped cloudtablevalues';
			$title = '';
			if ($key == 'used_by') {
				$rh = new ReservationsHelper ();
				$rh->getForMachine ($machine);
				$res = $rh->prettyPrintUsers ();
				$title = sprintf (' title="%s"', $res);
			} else {
				if (method_exists ($machine, $fname)) {
					$res = $machine->$fname();
					$title = sprintf (' title="%s"', $res);
				}
			}
			if ($key == 'status_string') {
				$class .= ' ' . get_machine_status_class ($machine->get_status_id ());
			}
			printf ('<tr><th class="text-left cloudtableheader">%1$s</th><td><div class="%2$s" %3$s>%4$s</div></td></tr>' . PHP_EOL,
				$value, $class, $title, $res);
		}
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
	<th>Status</th>
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
	  <td><?php echo($vm->get_status_string()); if ($vm->get_update_status ()) echo('<img src="images/exclamation_yellow.png" alt="Tools out of date!" title="Tools out of date(v'.$vm->get_tools_version().')!" width="20" style="float:right; padding-left: 3px;"></img>'); ?></td>
          <?php foreach ($fields_list as $key=>$value) {
            $fname = "get_".$key;
	    $res = '';
	    $title = '';
	    $cls = '';
	    if (method_exists ($vm, $fname)) {
		    $res = $vm->$fname();
	    }
	    if ($key == 'used_by') {
		    $rh->getForMachine ($vm);
		    $users = join (', ', $rh->getUserNames ());
		    $res = '<div class="ellipsis-no-wrapped machine_table_usedby">'
			    . $users . '</div>';
		    $title = $users;
	    }
	    if ($key == 'status_string') {
		    $cls = get_machine_status_class ($vm->get_status_id ());
	    }

            if (in_array($key, $vm_display_fields))
              echo ("<td title=\"$title\" class=\"$cls\">$res</td>");
            }
          ?>
          <td align="center">
<?php

print (virtual_machine_icons ($vm, $user));

?>
          </td>
         </tr>
      <?php endforeach; ?>
      </tbody>
    </table>
    <select name="action">
      <option value="">No action</option>
<!--  <option value="machine_send_job">Send job</option> -->
<!--  <option value="edit">Edit/reserve</option> -->
<!--  <option value="machine_reinstall">Reinstall</option>  -->
<!--  <option value="create_group">Add to group</option> -->
<!--  <option value="group_del_machines">Remove from group</option> -->
<!--  <option value="autopxe">AutoPXE</option> -->
<!--   <option value="create_autobuild">Add to Autobuild</option> -->
<!--   <option value="delete_autobuild">Remove from Autobuild</option> -->
<!--  <option value="delete">Delete</option> -->
    </select>
    <input type="submit" value="Go">
    <a href="../hamsta/helps/actions.html" target="_blank">
      <img src="../hamsta/images/27/qmark.png" class="icon-small" name="qmark1" id="qmark1" title="actions to selected machine(s)" /></a>
  </div>
  <script type="text/javascript">
  //<!--
  var TSort_Data = new Array ('<?php echo "vm_".($machine->get_hostname()); ?>','', '0' <?php echo str_repeat(", 'h'",count($vh_display_fields) + 1); ?>);
  var TSort_Icons = new Array ('<span class="text-blue sorting-arrow">&uArr;</span>', '<span class="text-blue sorting-arrow">&dArr;</span>');
  tsRegister();
  //-->
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
      <a href="../hamsta/helps/hwinfo.html" target="_blank">
        <img src="../hamsta/images/27/qmark.png" class="icon-small" name="qmark2" id="qmark2" title="hwinfo search" /></a>
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
</form>
