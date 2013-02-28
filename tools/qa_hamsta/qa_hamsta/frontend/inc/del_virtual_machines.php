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
     * Logic of the del_virtual_machines page
     *
     * Deletes the selected machines.
     */
    if(!defined('HAMSTA_FRONTEND')) {
        $go = 'del_virtual_machines';
        return require("index.php");
    }

    if(request_str("submit"))
    {
        $successfulDeletions = array();
        $failedDeletions = array();
        $allmachines = request_array("a_machines");

	/* check permissions */
	machine_permission_or_redirect($allmachines,array('owner'=>'vm_admin','other'=>'vm_admin_reserved'));

        foreach($allmachines as $machine_id)
        {
            $machine = Machine::get_by_id($machine_id);
	    $machineName = $machine->get_hostname();

	    $vh_id = $machine->get_vh_id();

	    $mac = $machine->get_unique_id();
	    $ip = $machine->get_ip_address();
	    $osspec = ''; # TODO: not urgent
	    
            if($machine->del_machine())
            {
                $successfulDeletions[] = "$machineName";
		
		# send job to VHost to delete machine
		$rand = rand();
                $job = "/tmp/delvm_$rand.xml";
                system("cp /usr/share/hamsta/xml_files/templates/delvm-template.xml $job");
		system("sed -i 's/MACADDR/$mac/g' $job");
                system("sed -i 's/IPADDR/$ip/g' $job");
		system("sed -i 's/OSSPEC/$osspec/g' $job");

		$vh = Machine::get_by_id($vh_id);
		if (!$vh->send_job($job)) {
                        $error = (empty($error) ? "" : $error) . "<p>".$vh->get_hostname().": ".$vh->errmsg."</p>";
		} else {
			Log::create($vh->get_id(), $vh->get_used_by_login(), 'VMDEL', "has deleted virtual machine $machineName.");
                }

            }
            else
            {
                $failedDeletions[] = "$machineName";
            }
        }

		# Send result to the main page
		if(count($failedDeletions) > 0)
		{
                  Notificator::setErrorMessage ("The following machines failed to delete: " . implode(", ", $failedDeletions) . ".");
		}
		if(count($successfulDeletions) > 0)
		{
                  Notificator::setSuccessMessage ("The following machines were successfully deleted: " . implode(", ", $successfulDeletions) . ".");
		}
		
		# Redirect to the main page
		header("Location: index.php");
		exit();
    }
    else if(request_str("cancel"))
    {
              Notificator::setErrorMessage ('Machine deletion was canceled.');
		header("Location: index.php");
		exit();
    }

    $search = new MachineSearch();
    $search->filter_in_array(request_array("a_machines"));

    $machines = $search->query();
    
    $html_title = "Delete virtual machines";
?>
