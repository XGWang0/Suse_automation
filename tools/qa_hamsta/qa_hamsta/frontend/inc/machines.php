<?php
	/**
	 * Logic of the machines page.
	 *
	 * Constructs the $machines array containing all machines matching the
	 * search criteria passed in the HTTP request and provides a standard
	 * set of fields to display in $display_fields.
	 */
	
	if (!defined('HAMSTA_FRONTEND')) {
		$go = 'machines';
		return require("index.php");
	}

	switch (request_str("action")) {
		case "edit":
			$go = "edit_machines";
			return require("inc/edit_machines.php");

		case "delete":
			$go = "del_machines";
			return require("inc/del_machines.php");

		case "create_group":
			$go = "create_group";
			return require("inc/create_group.php");
		
		case "group_del_machines":
			$go = "group_del_machines";
			return require("inc/group_del_machines.php");
		
		case "send_job":
			$go = "send_job";
			return require("inc/send_job.php");

	   case "reinstall":
			$go = "reinstall";
			return require("inc/reinstall.php");
	   
	   case "create_autobuild":
			$go = "create_autobuild";
			return require("inc/create_autobuild.php");
	
	   case "delete_autobuild":
			$go = "delete_autobuild";
			return require("inc/delete_autobuild.php");

	   case "vhreinstall":
			$go = "vhreinstall";
			return require("inc/vhreinstall.php");
           case "upgrade":
			$go = "upgrade";
			return require("inc/upgrade.php");
	}
	$searched_fields = array();
	$d_fields = request_array("d_fields");
	$display_fields = ( count($d_fields) ? $d_fields :	# user-selected fields
	( isset($display_fields) ? $display_fields : # fields from config 
	array("status_string", "used_by", "usage", "expires_formated", "product", "architecture_capable", "kernel", "type")
	));
	$a_machines = request_array("a_machines");

	$highlight = request_str("s_anything");
	if (empty($highlight)) $highlight = request_str("s_module_description");
	if (empty($highlight)) $highlight = request_str("s_module_driver");
	if (empty($highlight)) $highlight = request_str("s_module_element_value");
	if (empty($highlight)) $highlight = request_str("s_module_element");
	$highlight = urlencode($highlight);

	$search = new MachineSearch();
	$search->filter_role('SUT');	# Only interested in SUT on this page

	if( isset($fields_hidden) )
	foreach( $fields_hidden as $hide)	{
		unset($fields_list[$hide]);
	}
	foreach ($fields_list as $key=>$value){
		$fname = "filter_".$key;
		$filter = request_str($key);
		if ($filter && method_exists($search,$fname)){
			array_push($display_fields, $key);
			array_push($searched_fields, $value."=".$filter);
			$search->$fname($filter);
		}
	}
	if ($filter = request_str("s_anything")) {
		$op = request_operator("s_anything_operator");
		$search->filter_anything($filter, $op);
		array_push($searched_fields, "Hardware info ".$op." ".$filter);
	}

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
	$machines = $search->query();
	if (request_str("s_group"))
		foreach ($machines as $machine)
			$a_machines[] = $machine->get_id();

	global $latestFeatures;
	$html_title = "Machines";
	if ($searched_fields) {
		$html_title .= "<br><span class=\"text-small text-red normal\">filtered by:";
		foreach ($searched_fields as $c)
			$html_title .= "&emsp;".$c;
		$html_title .= "</span>";
	}
?>
