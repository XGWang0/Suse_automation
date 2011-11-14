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
     * Logic of the qacloud page.
     *
     * Constructs the $machines array containing all machines matching the
     * search criteria passed in the HTTP request and provides a standard
     * set of fields to display in $display_fields.
     */
    
    if (!defined('HAMSTA_FRONTEND')) {
        $go = 'qacloud';
        return require("index.php");
    }


    switch (request_str("action")) {
        case "edit":
            $go = "edit_machines";
            return require("inc/edit_machines.php");

        case "delete":
            $go = "del_machines";
            return require("inc/del_machines.php");

        case "send_job":
            $go = "send_job";
            return require("inc/send_job.php");

	   case "reinstall":
	        $go = "reinstall";
	        return require("inc/reinstall.php");
    }

    if (!($vh_display_fields = request_array("vh_d_fields"))) {
        $vh_display_fields = array("status_string", "used_by", "usage", "product", "type", "architecture_capable", "kernel");
    }

    if (!($vm_display_fields = request_array("vm_d_fields"))) {
        $vm_display_fields = array("status_string", "used_by", "usage", "product", "type", "architecture_capable", "kernel");
    }

    if ($d_module = request_str("d_module")) {
        $vh_display_fields[] = "d_module";
    }
    
    $a_machines = request_array("a_machines");

    $highlight = request_str("s_anything");
    if (empty($highlight)) $highlight = request_str("s_module_description");
    if (empty($highlight)) $highlight = request_str("s_module_driver");
    if (empty($highlight)) $highlight = request_str("s_module_element_value");
    if (empty($highlight)) $highlight = request_str("s_module_element");
    $highlight = urlencode($highlight);

    $search = new MachineSearch();

    if( isset($fields_hidden) )
	foreach( $fields_hidden as $hide)	{
	    unset($fields_list[$hide]);
	}

    if ($filter = request_str("s_arch"))        $search->filter_architecture($filter);
	if ($filter = request_str("s_archc"))       $search->filter_architecture_capable($filter);
    if ($filter = request_str("s_maintainer"))  $search->filter_maintainer($filter);
    if ($filter = request_str("s_status"))      $search->filter_status($filter);
    if ($filter = request_str("s_group"))       $search->filter_group($filter);

    if ($filter = request_str("s_anything"))    $search->filter_anything($filter, request_operator("s_anything_operator"));

    $modules_names = request_is_array("s_module") ? request_array("s_module") : (array) request_str("s_module");
    $modules_descriptions = request_is_array("s_module_description") ? request_array("s_module_description") : (array) request_str("s_module_description");
    $modules_drivers = request_is_array("s_module_driver") ? request_array("s_module_driver") : (array) request_str("s_module_driver");
    $modules_elements = request_is_array("s_module_element") ? request_array("s_module_element") : (array) request_str("s_module_element");
    $modules_element_values = request_is_array("s_module_element_value") ? request_array("s_module_element_value") : (array) request_str("s_module_element_value");
    
    foreach ($modules_names as $i => $module_name) {
        if ($filter = $modules_descriptions[$i]) {
            $search->filter_module_description($module_name, $filter);
        }
        if ($filter = $modules_drivers[$i]) {
            $search->filter_module_driver($module_name, $filter);
        }
        if ($filter = $modules_elements[$i]) {
            $search->filter_module_element($module_name, $filter, $modules_element_values[$i]);
        }
    }

    $search->filter_role('VH'); 
    $machines = $search->query();
    foreach ($machines as $machine) {
        $machine->get_children();
    }

    if (request_str("s_group")) {
        foreach ($machines as $machine) {
            $a_machines[] = $machine->get_id();
        }
    }

	global $latestFeatures;
    
    $html_title = "QA Cloud";
?>
