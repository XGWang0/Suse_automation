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

	function update_def_inst_opt(id)
	{
		// parameters
		var serial_console_device_per_machine = document.getElementById("consoledevice"+id).value;
		var serial_console_speed_per_machine = document.getElementById("consolespeed"+id).value;
		var serial_console_enable = document.getElementById("consolesetdefault"+id);
		var default_install_options = document.getElementById("default_options"+id).value;

		// clear all whitespace and create an array out of the options
		default_install_options = default_install_options.replace(/(^\s*)|(\s*$)/g,"");
		var all_default_options = default_install_options.split(/\s+/g);

		// remove the console option, if it exists
		var remainingOptions = new Array();
		for (option in all_default_options)
		{
			if(all_default_options[option].indexOf("console=") == -1)
			{
				remainingOptions.push(all_default_options[option]);
			}
		}

		// add the new console option (if enabled is checked)
		if(serial_console_enable.checked == true)
		{
			remainingOptions.push("console=" + serial_console_device_per_machine + "," + serial_console_speed_per_machine);
		}

		// set the new value
		default_install_options = remainingOptions.join(" ");
		default_install_options = default_install_options.replace(/(^\s*)|(\s*$)/g,"");
		document.getElementById("default_options"+id).value = default_install_options;
	}
	function trig_serial_console_field(id)
	{
		 var default_option_per_machine_id = document.getElementById("default_options"+id);		
		 var serial_console_device_per_machine_id = document.getElementById("consoledevice"+id);
                 var serial_console_speed_per_machine_id = document.getElementById("consolespeed"+id);
                 var serial_console_enable = document.getElementById("consolesetdefault"+id);
                 var find = default_option_per_machine_id.value.indexOf("console=");
		
		// default option field does not contains console field		
		if( find == -1)
		{
			serial_console_enable.checked = false;
		}
		else
		{
			var equal_index = default_option_per_machine_id.value.indexOf("=",find);	
			var comma_index =  default_option_per_machine_id.value.indexOf(",",find);
			if(comma_index != -1)
			{
				var end_index =  default_option_per_machine_id.value.indexOf(" ", equal_index);
				if( end_index != -1)
				{
					var serial_console_whole = default_option_per_machine_id.value.substring(equal_index+1,end_index);
				}
				else
				{
					var serial_console_whole = default_option_per_machine_id.value.substring(equal_index+1,default_option_per_machine_id.value.length);
				}
				var device_and_speed = serial_console_whole.split(",");
				var serial_console_device = device_and_speed.slice(0, device_and_speed.length-1);
				var serial_console_speed = device_and_speed[device_and_speed.length-1];
				serial_console_device_per_machine_id.value = serial_console_device;
				serial_console_speed_per_machine_id.value = serial_console_speed;
				serial_console_enable.checked = true;
			}
			else
			{
					serial_console_device_per_machine_id.value = "";
					serial_console_speed_per_machine_id.value = "";	
					serial_console_enable.checked = false;
			}
		}
	}

