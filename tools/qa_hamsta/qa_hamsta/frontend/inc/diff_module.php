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
     * Logic of the diff_module page 
     */
    if (!defined('HAMSTA_FRONTEND')) {
        $go = 'module_details';
        return require("index.php");
    }

    $module_name = request_str("name");

    $configuration1 = Configuration::get_by_id(request_int("config1"));
    $configuration2 = Configuration::get_by_id(request_int("config2"));

    $module1 = $configuration1->get_module($module_name);
    $module2 = $configuration2->get_module($module_name);

    $elements = array();
    foreach($module1->get_parts() as $part_id => $part) {
        foreach($part as $element => $value) {
            if (empty($elements[$part_id]) || !in_array($element, $elements[$part_id]))
                $elements[$part_id][] = $element;
        }
    }
    foreach($module2->get_parts() as $part_id => $part) {
        foreach($part as $element => $value) {
            if (empty($elements[$part_id]) || !in_array($element, $elements[$part_id]))
                $elements[$part_id][] = $element;
        }
    }

    $html_title = "Differences in ". $module_name;

?>
