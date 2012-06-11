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
    if(!defined('HAMSTA_FRONTEND')) {
	$go = 'power';
	return require("index.php");
    }

    $html_return_string = "<br> <FORM><INPUT TYPE=\"button\" VALUE=\"Back\" onClick=\"history.go(-1);return true;\"></FORM>";

    if ($result == "powerswitch_description_error") {
	if ($machine->get_powertype() == "apc") {
		echo "Powerswitch description for apc controlled host <i>".$machine->get_hostname()."</i> is not in valid form (".$machine->get_powerswitch().").<br> It should be \"community@host\"";
		echo $html_return_string;
	}
	else if ($machine->get_powertype() == "ipmi") {
		echo "Powerswitch description for ipmi controlled host <i>".$machine->get_hostname()."</i> is not in valid form (".$machine->get_powerswitch().").<br> It should be \"user:password@host\"";
		echo $html_return_string;
	}
	else if ($machine->get_powertype() == "hmc") {
		echo "Powerswitch description for IBM iseries hmc controlled host <i>".$machine->get_hostname()."<i> is not in valid form (".$machine->get_powerswitch().").<br> It should be \"user:password@host\"";
		echo $html_return_string;
	}
	else if ($machine->get_powertype() == "amt") {
		echo "Powerswitch description for intel AMT controlled host <i>".$machine->get_hostname()."</i> is not in valid form (".$machine->get_powerswitch().").<br> It should be \"password@host\"";
		echo $html_return_string;
	}
	else if ($machine->get_powertype() == "virsh") {
		echo "Powerswitch description for virtual machine <i>".$machine->get_hostname()."</i> is not in valid form (".$machine->get_powerswitch().").<br> It should be \"user:pass@host\"";
		echo $html_return_string;
	}
    }

    else if ($result == "powerswitch_description_error") {
	if ($machine->get_powertype() == "hmc") {
		echo "Powerslot description for IBM iseries hmc controlled host <i>".$machine->get_hostname()."</i> is not in valid form (".$machine->get_powerslot().").<br> It should be \"machine-id\"";
		echo $html_return_string;
	}
	if ($machine->get_powertype() == "virsh") {
		echo "Powerslot description for virtual machine <i>".$machine->get_hostname()."</i> is not in valid form (".$machine->get_powerslot().").<br> It should be \"virtualization type-domain (ie qemu-vm1\"";
		echo $html_return_string;
	}
    }

    else if ($result == NULL) {
		echo "Action succeeded";
		echo $html_return_string;
    }

    else {
	echo "Unexpected result: $result";
	echo $html_return_string;
    }
?>
