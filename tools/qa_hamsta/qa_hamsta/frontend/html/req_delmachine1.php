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

    if (empty($machines)) {
        $_SESSION['message'] = "You did not select any machines for deletion. Please try again.";
        $_SESSION['mtype'] = "fail";
        header("Location: index.php");
        exit();
    }

    $nonVM = array();
    if (request_str("go")=="del_virtual_machines") {
        foreach ($machines as $machine) {
            if($machine->get_role() != 'SUT' or ! preg_match ('/^vm\//', $machine->get_type())) {
                $nonVM[] = $machine->get_hostname();
            }
        }
        if(!empty($nonVM)) {
            echo "<div class=\"text-medium\">" .
            "The following machines are not virtual machines:<br /><br />" .
            "<strong>" . implode(", ", $nonVM) . "</strong><br /><br />" .
            "It is not possible to delete virtual machines which are not virtual machines ;-)" .
            "</div>";
            echo "<form action=\"go=index.php\">\n".
            "<input type=\"submit\" value=\"TurnBack\">\n".
            "</form>\n";
            exit();
        }
    }
?>
