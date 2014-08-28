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
     * Logic of the edit_jobs page 
     *
     * Edit the job XML file.
     */

    if (!defined('HAMSTA_FRONTEND'))
    {
        $go = 'edit_jobs';
        return require("index.php");
    }
    $errors = array();
    $file = request_str("file");
    $opt = request_str("opt");
    $machine_list = request_str("machine_list");
    $perm=array('perm'=>'job_edit');
    permission_or_disabled($perm);

    if (request_str("cancel") == "Cancel")
    {
	header("Location: index.php?go=machine_send_job&machine_list=$machine_list");
	exit ();
    }

    if($file != "")
    {
        $real_file = $config->xml->dir->default . "/" . $file;
        $file_dir = dirname($real_file);

        if(substr($file_dir, -6) != "custom")
            $new_file_dir = $file_dir . "/custom";
        else
            $new_file_dir = $file_dir;

        $file_name = substr(basename($real_file), 0, -4);
        $rand = rand();
        $new_file = "/tmp/" . $file_name . "_" . $rand . ".xml";
    }
    else
        $errors[] = "You didn't define any file to be edit.";

    if($opt != "edit")
        $errors[] = "The option is not what is expected: $edit";
    $file_content = "";

    if(!file_exists($real_file))
        $errors[] = "Can not find the file: $real_file";

    if(request_str("submit"))
    {
        permission_or_redirect($perm);
        require("inc/job_create.php");

	if(count($errors) == 0) {
            header("Location: index.php?go=machine_send_job&machine_list=$machine_list");
	    Notificator::setSuccessMessage ('A custom job has been created.');
	    exit ();
	}
    }

    $html_title = "Edit jobs";
    if (count($errors) != 0) {
        $_SESSION['message'] = implode("\n", $errors);
        $_SESSION['mtype'] = "fail";
    }
?>

