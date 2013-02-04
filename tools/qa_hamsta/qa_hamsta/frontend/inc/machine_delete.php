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
     * Logic of the machine_delete page
     *
     * Deletes the selected machines.
     */
    if(!defined('HAMSTA_FRONTEND')) {
        $go = 'machine_delete';
        return require("index.php");
    }

    if(request_str("submit"))
    {
        $successfulDeletions = array();
        $failedDeletions = array();
        $allmachines = request_array("a_machines");
        foreach($allmachines as $machine_id)
        {
            $machine = Machine::get_by_id($machine_id);
            $machineName = $machine->get_hostname();
            if($machine->del_machine())
            {
                $successfulDeletions[] = "$machineName";
            }
            else
            {
                $failedDeletions[] = "$machineName";
            }
        }

		# Send result to the main page
		if(count($failedDeletions) > 0)
		{
			$_SESSION['message'] = "The following machines failed to delete: " . implode(", ", $failedDeletions) . ".";
			$_SESSION['mtype'] = "error";
		}
		if(count($successfulDeletions) > 0)
		{
			$_SESSION['message'] = "The following machines were successfully deleted: " . implode(", ", $successfulDeletions) . ".";
			$_SESSION['mtype'] = "success";
		}
		
		# Redirect to the main page
		header("Location: index.php");
		exit();
    }
    else if(request_str("cancel"))
    {
		$_SESSION['message'] = "Machine deletion was canceled.";
		$_SESSION['mtype'] = "fail";
		header("Location: index.php");
		exit();
    }

    $search = new MachineSearch();
    $search->filter_in_array(request_array("a_machines"));

    $machines = $search->query();

/* Check if user has privileges to delete a machines. */
if ( $config->authentication->use )
  {
    if ( User::isLogged () && User::isRegistered (User::getIdent (), $config) )
      {
        $user = User::getById (User::getIdent (), $config);
        if ( $user->isAllowed ('machine_delete') || $user->isAllowed ('machine_delete_reserved') )
          {
            foreach ($machines as $machine)
              {
                if ( ! ( $machine->get_used_by_login () == $user->getLogin () 
                         || $user->isAllowed ('machine_delete_reserved')) )
                  {
                    Notificator::setErrorMessage ("You cannot delete a machine that is not reserved"
                                                  . " or is reserved by other user.");
                    header ("Location: index.php?go=machines");
                    exit ();
                  }
              }
          }
        else
          {
            Notificator::setErrorMessage ("You do not have privileges to delete a machine.");
            header ("Location: index.php?go=machines");
            exit ();
          }
      }
    else
      {
        Notificator::setErrorMessage ("You have to be logged in and registered to delete a machine.");
        header ("Location: index.php?go=machines");
        exit ();
      }
  }
    
    $html_title = "Delete machines";
?>
