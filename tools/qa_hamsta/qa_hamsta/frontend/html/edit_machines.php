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
   * Contents of the <tt>edit_machines</tt> page 
   */
if (!defined('HAMSTA_FRONTEND')) {
  $go = 'edit_machines';
  return require("index.php");
 }

        /* We are going to output all fields and data for the machines. So first we collect it. */
	$table = array();
	$tableHeadings = array("Name", "*Perm", "Used By", "Usage", "Usage Expires (days)", "Maintainer", "Affiliation", "Notes", "Power Switch", "Power type", "Power slot", "Serial Console", "Console Device", "Console Speed", "Enable Console", "Default Install Options");
	$show_column = array("usage", "expires", "maintainer_string", "affiliation", "anomaly", "powerswitch", "powertype", "powerslot", "serialconsole");	
	$machineCounter = 0;
	foreach ($machines as $machine) {

		$machine_id = $machine->get_id();
		$counterAddValue = $machineCounter*count($tableHeadings) + 1;
		$column = array();
		/* If the user is not logged in or authorized, disable some fields.  */
		$disabled_console = isset ($user) && $user->isAllowed ('machine_edit_console') ? '' : "disabled=\"disabled\"";
                $disabled_powercycling = isset ($user) && $user->isAllowed ('machine_edit_powercycling') ? '' : "disabled=\"disabled\"";
                $disabled_editation = isset ($user) && $user->isAllowed ('machine_edit_reserved') ? '' : "disabled=\"disabled\"";
                $disabled_maintainer = isset ($user) && $user->isAllowed ('machine_edit_maintainer') ? '' : "disabled=\"disabled\"";
                
		# Hostname/ID
		$hostname = $machine->get_hostname();
		$column[] = "<a href=\"index.php?go=machine_details&amp;id=" . $machine_id . "\" tabindex=" . $counterAddValue++ . ">" . $hostname . "</a>" .
			"<input type=\"hidden\" name=\"a_machines[]\" value=\"" . $machine_id . "\" />";

		# Perm
                $column[] = "<input type=\"checkbox\" name=\"perm_" . $machine_id . "[]\" " . ($machine->has_perm("job")?" checked=\"checked\"" : "") . " value=\"job\" >job" .
                        "<input type=\"checkbox\" name=\"perm_" . $machine_id . "[]\" " . ($machine->has_perm("install")?" checked=\"checked\"":"") . " value=\"install\" >install".
                        "<input type=\"checkbox\" name=\"perm_" . $machine_id . "[]\" " . ($machine->has_perm("partition")?" checked=\"checked\"":"") . " value=\"partition\"  >partition".
                        "<input type=\"checkbox\" name=\"perm_" . $machine_id . "[]\" " . ($machine->has_perm("boot")?" checked=\"checked\"" : "") . " value=\"boot\"  >boot";

                /* Used by */
		$item_list = request_array("used_by");
		if (array_key_exists($machine->get_id(), $item_list)) {
			$valuer = $item_list[$machine->get_id()];
		}

		if (!isset($valuer)) {
			$valuer = $machine->get_used_by_login();
		}

		if (!isset($valuer) && isset($user)) {
			$valuer = $user->getLogin();
		}

                $used_by = User::getByLogin($valuer, $config);

                /* If the user has privileges to modify a reserved
                 * machine, she can change the user of the machine. */
                if ( ! $config->authentication->use
                     || (isset ($user) && $user->isAllowed ('machine_edit_reserved')) )
                  {
                    $all_users = User::getAllUsers ($config);
                    $to_column = "<input name=\"used_by[" . $machine->get_id()
                      . "]\" value=\"$valuer\" style=\"width: 200px;\" tabindex="
                      . $counterAddValue++ . " type=\"text\" />";
                    if ( count ($all_users) > 0 )
                      $to_column = "<select name=\"used_by[" . $machine->get_id()
                        . "]\" style=\"width: 200px;\" tabindex="
                        . $counterAddValue . ">\n";

                      foreach ($all_users as $user)
                        {
                          $to_column .= "      <option value=\""
                            . $user->getLogin () . "\""
                            . ( ($user->getLogin () == $valuer)
                                ? " selected=\"selected\"" : "" )
                            . ">"
                            . ( strlen ($user->getName ()) == 0
                                ? $user->getLogin () : $user->getName () )
                            . "</option>\n";
                        }
                      $to_column .= "  </select>\n";
                    $counterAddValue++;
                    $column[] = $to_column;
                  }
                else
                  {
                    $column[] = "<input name=\"used_by[" . $machine->get_id()
                      . "]\" value=\"$valuer\" style=\"width: 200px;\" tabindex="
                      . $counterAddValue++ . " type=\"hidden\" />"
                      . ( ( isset ($used_by)
                            && $used_by->getName() != '' )
                          ? $used_by->getName()
                          : $valuer );
                  }
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
                            $column[] = "<input name=\"$namer\" value=\"$valuer\" $disabled_maintainer style=\"width: 200px;\" tabindex=" . $counterAddValue++ . ">";
                          }
                        else if ($item == 'serialconsole')
			  {
			    $column[] = "<input name=\"$namer\" value=\"$valuer\" $disabled_console style=\"width: 200px;\" tabindex=" . $counterAddValue++ . ">";
			  }
                        else if ( in_array ($item, Array ('powerswitch',
                                                          'powertype',
                                                          'powerslot')) )
                          {
                            $column[] = "<input name=\"$namer\" value=\"$valuer\" $disabled_powercycling style=\"width: 200px;\" tabindex=" . $counterAddValue++ . ">";
                          }
			else
			  {
			    $column[] = "<input name=\"$namer\" value=\"$valuer\" style=\"width: 200px;\" tabindex=" . $counterAddValue++ . ">";
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

		$column[] = "<input name=\"consoledevice[" . $machine->get_id() . "]\" $disabled_console id=\"consoledevice" . $machine->get_id() . "\" value=\"" . $consoledevice . "\" style=\"width: 200px;\" tabindex=" . $counterAddValue++ . " onkeyup=\"update_def_inst_opt(" . $machine->get_id() . ");\">";

		# Console speed
		$consolespeeds = request_array('consolespeed');
		if (array_key_exists($machine->get_id(), $consolespeeds)) {
			$consolespeed = $consolespeeds[$machine->get_id()];
		}
		if (!isset($consolespeed)) {
			$consolespeed = $machine->get_consolespeed();
		}
		$column[] = "<input name=\"consolespeed[" . $machine->get_id() . "]\" $disabled_console id=\"consolespeed" . $machine->get_id() . "\" value=\"" . $consolespeed . "\" style=\"width: 200px;\" tabindex=" . $counterAddValue++ . " onkeyup=\"update_def_inst_opt(" . $machine->get_id() . ");\">";
		
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
		$column[] = "<input name=\"default_options[" . $machine->get_id() . "]\" $disabled_editation id=\"default_options" . $machine->get_id() . "\" value=\"" . $def_inst_opt . "\" style=\"width: 200px;\" tabindex=" . $counterAddValue++ . " onchange=\"trig_serial_console_field(" . $machine->get_id() . ");\">";

		# Add to main table
		$table[] = $column;

		$machineCounter++;
	}

?>
<script type="text/javascript" src="js/edit_machine.js"></script>
<form name='edit_machine' action="index.php?go=edit_machines" method="post">
<table name='table_cell' class="list text-main">
<?php
	for ($i = 0; $i < count($tableHeadings); $i++) {
		echo "\n  <tr>";
			echo "\n    <th>" . $tableHeadings[$i] . "</th>";
			for ($j = 0; $j < count($machines); $j++) {
				echo "\n    <td>" . $table[$j][$i] . "</td>";
			}
		echo "\n  </tr>";
	}
?>

</table>
<input type="submit" name="submit" value="Change">
<br />
<p class="text-small"><strong>*</strong> "Not accepting jobs" or "Outdated (Blocked)" status will make this system ignore any jobs that are sent from the Hamsta front-end, while "Reinstall deny" status will only process normal jobs.</p>
</form>
