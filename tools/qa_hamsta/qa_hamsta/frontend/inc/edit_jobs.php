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

    if($file != "")
    {
        $real_file = XML_DIR . "/" . $file;
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

    $option = request_str("opt");
    $machine_list = request_str("machine_list");

    if($option != "edit")
        $errors[] = "The option is not what is expected: $edit";
    $file_content = "";

    if(!file_exists($real_file))
        $errors[] = "Can not find the file: $real_file";
    else
        $file_content = file_get_contents($real_file);

    if(request_str("submit"))
    {
        $new_file_name = trim(request_str("new_file_name"));
        $new_file_content = request_str("new_file_content");
        $new_file_dir = request_str("new_file_dir");

        if(!is_dir($new_file_dir))
        {
            if(mkdir($new_file_dir) == false )
                $errors[] = "Can not create directory: $new_file_dir";
        }

        $new_file_content = preg_replace('/&[^; ]{0,6}.?/e', "((substr('\\0', -1) == ';') ? '\\0' : '&amp;'.substr('\\0', 1))", $new_file_content);

        if(preg_match("/^[0-9a-zA-Z_]+$/", $new_file_name))  # validate the file name user input
        {
            $new_real_file = $new_file_dir . "/" . $new_file_name . ".xml";
            file_put_contents($new_file, $new_file_content);

	    if(xml_read($new_file))  # validate the XML data user input
	    {
                system("cp $new_file $new_real_file");
	        header("Location: index.php?go=send_job&machine_list=$machine_list");
	    }
            else
                $errors[] = "The XML data you input is not valid, please try to edit again!";
            if(file_exists($new_file))
                unlink($new_file);
        }
        else
                $errors[] = "The file name you input is invalid! It must be composed by number, letter or underscroe.";
    }

    $html_title = "Edit jobs";
    if (count($errors) != 0) {
        $_SESSION['message'] = implode("\n", $errors);
        $_SESSION['mtype'] = "fail";
    }
?>

