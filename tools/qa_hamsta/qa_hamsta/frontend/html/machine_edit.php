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
   * Contents of the <tt>machine_edit</tt> page 
   */
if (!defined('HAMSTA_FRONTEND')) {
  $go = 'machine_edit';
  return require("index.php");
 }

/* We are going to output all fields and data for the machines. So first we collect it. */
$table = array();
$tableHeadings = array ('Name',
			'*Perm',
			$edit_fields['used_by'],
			$edit_fields['usage'],
			$edit_fields['maintainer_string'],
			$edit_fields['affiliation'],
			$edit_fields['anomaly'],
			$edit_fields['powerswitch'],
			$edit_fields['powertype'],
			$edit_fields['powerslot'],
			$edit_fields['serialconsole'],
			$edit_fields['consoledevice'],
			$edit_fields['consolespeed'],
			$edit_fields['consolesetdefault'],
			'Default Install Options'
	);
$show_column = array("usage", "maintainer_string", "affiliation", "anomaly", "powerswitch", "powertype", "powerslot", "serialconsole");
$machineCounter = 0;
$useAuth = $config->authentication->use;
$current_user = User::getCurrent ();
$all_users = User::getAllUsers ();
$rh = new ReservationsHelper ();

foreach ($machines as $machine) {
	/* Get all reservations for this machine. */
	$rh->getForMachine ($machine);

	$machine_id = $machine->get_id();
	$counterAddValue = $machineCounter*count($tableHeadings) + 1;
	$column = array();
	/* If the user is not logged in or authorized, disable some fields.  */
	$disabled_console = (! $useAuth || (isset ($user) && $user->isAllowed ('machine_edit_console'))) ? '' : "disabled=\"disabled\"";
	$disabled_powercycling = (! $useAuth || (isset ($user) && $user->isAllowed ('machine_edit_powercycling'))) ? '' : "disabled=\"disabled\"";
	$disabled_edit = (! $useAuth || (isset ($user) && $user->isAllowed ('machine_edit_reserved'))) ? '' : "disabled=\"disabled\"";
	$disabled_maintainer = (! $useAuth || (isset ($user) && $user->isAllowed ('machine_edit_maintainer'))) ? '' : "disabled=\"disabled\"";

	# Hostname/ID
		$hostname = $machine->get_hostname();
	$column[] = "<a href=\"index.php?go=machine_details&amp;id=" . $machine_id . "\" tabindex=" . $counterAddValue++ . ">" . $hostname . "</a>" .
		"<input type=\"hidden\" name=\"a_machines[]\" value=\"" . $machine_id . "\" />";

	# Perm
                $column[] = "<input type=\"checkbox\" name=\"perm_" . $machine_id . "[]\" " . ($machine->has_perm("job")?" checked=\"checked\"" : "") . " value=\"job\" >job" .
		"<input type=\"checkbox\" name=\"perm_" . $machine_id . "[]\" " . ($machine->has_perm("install")?" checked=\"checked\"":"") . " value=\"install\" >install".
		"<input type=\"checkbox\" name=\"perm_" . $machine_id . "[]\" " . ($machine->has_perm("partition")?" checked=\"checked\"":"") . " value=\"partition\"  >partition".
		"<input type=\"checkbox\" name=\"perm_" . $machine_id . "[]\" " . ($machine->has_perm("boot")?" checked=\"checked\"" : "") . " value=\"boot\"  >boot";

	/* User reservations */
	$logged_user_line = '';
	$user_lines = array ();
	$counterAddValue++;
	foreach ($all_users as $usr) {
		$is_res = $rh->isReservator ($usr);
		$expires = '';
		$note = '';
		if ($is_res) {
			$res = $rh->getForMachineUser ($machine, $usr);
			$expires = $rh->getFormattedDate ($res->getExpires ());
			$note = $res->getUserNote ();
		}

		$checkbox_id = 'used_by_' . $machine->get_id () . '[]';
		$machine_user_id = $machine->get_id () . '[' . $usr->getId () . ']';
		$expires_id = 'expires_' . $machine_user_id;
		$user_note_id = 'user_note_' . $machine_user_id;
		$checked = ($is_res ? ' checked="checked"' : '' );
		$user_text  = '      <input type="checkbox" '
			. 'name="' . $checkbox_id . '" tabindex="'
			. $counterAddValue . '" value="'
			. $usr->getId () . '"' . $checked . '>'
			. '<span class="username">'
			. $usr->getNameOrLogin ()
			. '</span>' . PHP_EOL
			. '<span class="userdet">' . PHP_EOL
			. '<input type="date" pattern="\d{4}-\d{2}-\d{2}"'
			. ' min="' . date ('Y-m-d', time() + 24 * 3600). '"'
			. ' title="YYYY-MM-DD" class="machineedit dateornote" name="'
			. $expires_id . '" value="' . $expires . '" placeholder="Date of expiration: YYYY-MM-DD"/>'
			. '<input type="text" class="machineedit" maxlength=64'
			. ' name="' . $user_note_id . '" value="' . $note
			. '" placeholder="Enter your personal note"/>' . PHP_EOL
			. '</span>';
		/* Put logged in user at the top of the list. */
		if ($usr->equals ($current_user)) {
			$logged_user_line = $user_text;
		} else {
		/* Checkbox, expires and user name or login */
			$user_lines[] =  $user_text;
		}
	}

	$to_column = $logged_user_line;
	$how_many_other = count ($all_users) - 1;
	if (isset ($user) && $how_many_other) {
		$to_column .= '<div><input type="checkbox" name="show_others"/>Share with other '
			. $how_many_other . ($how_many_other > 1 ? ' users' : ' user');
	}
	$to_column .= '<div id="other_users" class="other_users">' . PHP_EOL;
	if (count ($user_lines)) {
		$to_column .= '<div>';
		$to_column .= join ('</div>' . PHP_EOL . '<div>' . PHP_EOL, $user_lines) . PHP_EOL;
		$to_column .= '</div>';
	}
	if (isset ($user) && $how_many_other) { // Closes the div with many users
		$to_column .= '</div>';
	}
	$to_column .= '</div>' . PHP_EOL;

	$counterAddValue++;
	$column[] = $to_column;
	$valuer = NULL;

	# Common columns (configurable)
		foreach ($show_column as $item) {
			$getstring = "get_".$item;
			$item_list = request_array($item);
			if (array_key_exists($machine->get_id(), $item_list)) {
				$valuer = $item_list[$machine->get_id()];
			}

			if (!isset($valuer)) {
				$valuer = $machine->$getstring();
			}

			$namer = $item . "[" . $machine->get_id() . "]";

                        if ($item == 'maintainer_string')
			{
				$column[] = "<input name=\"$namer\" value=\"$valuer\" $disabled_maintainer class=\"machineedit\" tabindex=" . $counterAddValue++ . ">";
			}
                        else if ($item == 'serialconsole')
			{
				$column[] = "<input name=\"$namer\" value=\"$valuer\" $disabled_console class=\"machineedit\" tabindex=" . $counterAddValue++ . ">";
			}
                        else if ( in_array ($item, Array ('powerswitch',
                                                          'powertype',
                                                          'powerslot')) )
			{
				$column[] = "<input name=\"$namer\" value=\"$valuer\" $disabled_powercycling class=\"machineedit\" tabindex=" . $counterAddValue++ . ">";
			}
			else if ($item == 'affiliation')
			{
				$column[] = "<input name=\"$namer\" value=\"$valuer\" $disabled_edit class=\"machineedit\" tabindex=" . $counterAddValue++ . ">";
			}
			else if ($item == 'usage')
			{
				$column[] = "<input type=\"text\" maxlength=64 name=\"$namer\" value=\"$valuer\" class=\"machineedit\" tabindex=" . $counterAddValue++ . ">";
			}
			else
			{
				$column[] = "<input name=\"$namer\" value=\"$valuer\" class=\"machineedit\" tabindex=" . $counterAddValue++ . ">";
			}

			$valuer = NULL;
		}

	# Console device
		$consoledevices = request_array('consoledevice');
	if (array_key_exists($machine->get_id(), $consoledevices)) {
		$consoledevice = $consoledevices[$machine->get_id()];
	}
	if (!isset($consoledevice)) {
		$consoledevice = $machine->get_consoledevice();
	}

	$column[] = "<input name=\"consoledevice[" . $machine->get_id() . "]\" $disabled_console id=\"consoledevice" . $machine->get_id() . "\" value=\"" . $consoledevice . "\" class=\"machineedit\" tabindex=" . $counterAddValue++ . " onkeyup=\"update_def_inst_opt(" . $machine->get_id() . ");\">";

	# Console speed
		$consolespeeds = request_array('consolespeed');
	if (array_key_exists($machine->get_id(), $consolespeeds)) {
		$consolespeed = $consolespeeds[$machine->get_id()];
	}
	if (!isset($consolespeed)) {
		$consolespeed = $machine->get_consolespeed();
	}
	$column[] = "<input name=\"consolespeed[" . $machine->get_id() . "]\" $disabled_console id=\"consolespeed" . $machine->get_id() . "\" value=\"" . $consolespeed . "\" class=\"machineedit\" tabindex=" . $counterAddValue++ . " onkeyup=\"update_def_inst_opt(" . $machine->get_id() . ");\">";
		
	# Enable console (careful, checkboxes that aren't checked don't show up as isset in PHP)
		if (isset($_POST['submit'])) { # They submitted the form, so we use if they checked it or not
			$consolesetdefaults = request_array('consolesetdefault');
			if (array_key_exists($machine->get_id(), $consolesetdefaults)) {
				$consolesetdefault = $consolesetdefaults[$machine->get_id()];

				# If they actually checked the form, otherwise just leave it empty
				if ($consolesetdefault == "enable_console") {
					$consolesetdefault = "1";
				}
			}
		}
		else { # They did not submit the form, so we use what was in the database
				$consolesetdefault = $machine->get_consolesetdefault();
		}
	if (!isset($consolesetdefault)) {
		$consolesetdefault = 0;
	}
	$column[] = "<input name=\"consolesetdefault[" . $machine->get_id() . "]\" $disabled_console id=\"consolesetdefault" . $machine->get_id() . "\" value=\"enable_console\" type=\"checkbox\"" . ($consolesetdefault == "1" ? " checked=\"checked\"" : "") . " tabindex=" . $counterAddValue++ . " onclick=\"update_def_inst_opt(" . $machine->get_id() . ");\">";

	# Default install options
		$def_inst_opts = request_array('default_options');
	if (array_key_exists($machine->get_id(), $def_inst_opts)) {
		$def_inst_opt = $def_inst_opts[$machine->get_id()];
	}
	if (!isset($def_inst_opt)) {
		$def_inst_opt = $machine->get_def_inst_opt();
	}
	$column[] = "<input name=\"default_options[" . $machine->get_id() . "]\" $disabled_edit id=\"default_options" . $machine->get_id() . "\" value=\"" . $def_inst_opt . "\" class=\"machineedit\" tabindex=" . $counterAddValue++ . " onchange=\"trig_serial_console_field(" . $machine->get_id() . ");\">";

	# Add to main table
		$table[] = $column;

	$machineCounter++;
}

?>
<script type="text/javascript" src="js/edit_machine.js"></script>
<form name='machine_edit' action="index.php?go=machine_edit" method="post">
<table name='table_cell' class="list text-main">
<?php
	for ($i = 0; $i < count($tableHeadings); $i++) {
		echo "\n  <tr>";
			echo "\n    <th>" . $tableHeadings[$i] . "</th>";
			for ($j = 0; $j < count($machines); $j++) {
				echo "\n    <td>\n" . $table[$j][$i] . "</td>";
			}
		echo "\n  </tr>";
	}
?>

</table>
<input type="submit" name="submit" value="Change">
</form>
<p class="text-small"><strong>*</strong> "Not accepting jobs" or "Outdated (Blocked)" status will make this system ignore any jobs that are sent from the Hamsta front-end, while "Reinstall deny" status will only process normal jobs.</p>

