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

/* Retrieve an user instance if we can. */
$user = null;
if ( User::isLogged () && User::isRegistered (User::getIdent (), $config) )
  {
    $user = User::getById (User::getIdent (), $config);
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

		case "merge_machines":
			$go = "merge_machines";
			return require("inc/merge_machines.php");

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
           case "start":
			$go = "power";
			return require("inc/power.php");

           case "restart":
			$go = "power";
			return require("inc/power.php");

           case "stop":
			$go = "power";
			return require("inc/power.php");
	   case "upgrade":
			$go = "upgrade";
			return require("inc/upgrade.php");
	}

	$searched_fields = array();
	$d_fields = request_array("d_fields");

	/* Try to get a session namespace to store the displayed
	 * fields setup. */
	try
	  {
	    $ns_machine_fields = new Zend_Session_Namespace ('machineDisplayFields');
	  }
	catch (Zend_Session_Exception $e)
	  {
	    /* This is unfortunate. Might be caused by disabled cookies
	     * or some fancy browser. */
	    $ns_machine_fields = null;
	  }

	/* Try to get a session namespace to store the field values
	 * for displayed machines. */
	try
	  {
	    $ns_machine_filter = new Zend_Session_Namespace ('machineDisplayFilter');
	  }
	catch (Zend_Session_Exception $e)
	  {
	    /* This is unfortunate. Might be caused by disabled cookies
	     * or some fancy browser. */
	    $ns_machine_filter = null;
	  }

	/* Reset fields displayed and filtered in the machine list
	 * table to defaults when user submits the Reset button. */
	if (request_str ('reset') == 'Reset')
	  {
	    unset ($d_fields);
	    if (isset ($ns_machine_fields))
	      {
		$ns_machine_fields->unsetAll ();
	      }

	    if (isset ($ns_machine_filter))
	      {
		$ns_machine_filter->unsetAll ();
	      }
	  }

	/* Get the group filter. It is not sent from a form. */
	$group_filter = request_str ('group');

	/* Set fields displayed in the machine list table.
	 *
	 * First try to get it from the last request, then from the
	 * session and as a last resort set the value to defaults.
	 */
	if (isset ($d_fields) && count ($d_fields) > 0)
	  {
	    $display_fields = $d_fields;
	    /* Save decision to session if possible. */
	    if (isset ($ns_machine_fields))
	      {
		/* Set only to values sent in the request. */
		$ns_machine_fields->unsetAll ();
		$ns_machine_fields->fields = $d_fields;
	      }
	  }
	/* Get the fields array from session namespace. */
	else if (isset ($ns_machine_fields)
		 && isset ($ns_machine_fields->fields))
	  {
		$display_fields = $ns_machine_fields->fields;
	  }

	/* If the value is still not set, use defaults. */
	if (! isset ($display_fields))
	  {
	    $display_fields = array ("usage", "expires_formated",
				     "product",
				     "architecture_capable",
				     "kernel", "type");
	    if (! empty ($group_filter)
		&& isset ($ns_machine_fields))
	      {
		array_push ($display_fields, 'group');
		$ns_machine_fields->fields = $display_fields;
	      }
	  }

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
		if (isset ($ns_machine_fields->fields[$hide]))
		  {
		    unset ($ns_machine_fields->fields[$hide]);
		  }
	}

	/* Skip all this if we have a reset request. */
	if (request_str ('reset') != 'Reset')
	  /*
	   && ( request_str ('set') == 'Search'
	        || isset ($ns_machine_filter->fields)
	        || ! empty ($group_filter) )
	   
	   */
	  {
	    /* Iterate over all available fields (table columns) and apply
	     * filters on it. */
	    foreach ($fields_list as $key => $value)
	      {
		$fname = "filter_" . $key;
		$filter = request_str ($key);

		/* Use filter stored in the session, if it is not in
		 * this request. */
		if (isset ($ns_machine_filter->fields)
		    && empty ($filter)
		    && in_array ($key, array_keys ($ns_machine_filter->fields)))
		  {
		    /* Unset the value if the user sets empty value. */
		    if (request_str ('set') == 'Search'
			&& isset ($ns_machine_filter->fields[$key])
			&& $key != 'group')
		      {
			unset ($ns_machine_filter->fields[$key]);
			unset ($fname);
			unset ($filter);
		      }
		    else
		      {
			$filter = $ns_machine_filter->fields[$key];
		      }
		  }

		/* If the filter method is available we also set the
		 * field to be displayed. */
		if ( ! empty ($filter) && method_exists ($search, $fname)
		     && (request_str ('set') == 'Search'
			 || ($key == 'group')) )
		  {
		    if ( isset ($ns_machine_filter->fields)
			 && ! (in_array ($key, $ns_machine_fields->fields)
			       || in_array ($key, $default_fields_list)))
		      {
			$ns_machine_fields->fields[] = $key;
		      }

		    if (! in_array ($key, $display_fields)
			&& ! in_array ($key, $default_fields_list))
		      {
			array_push ($display_fields, $key);
		      }
		  }

		/* If filter of some sort was used store it in
		 * the session. */
		if (isset ($ns_machine_filter))
		  {
		    if (! empty($filter))
		      {
			$ns_machine_filter->fields[$key] = $filter;
		      }
		    else if ($key == 'group'
			     && isset ($ns_machine_filter->fields['group']))
		      {
			/* Do nothing here. */
		      }
		  }

		if (! empty ($fname) && ! empty ($filter))
		  {
		    $search->$fname ($filter);
		  }
	      }
	  }

	if (request_str ('set') == 'Search')
	  {
	    $filter = request_str("s_anything");
	    $op = request_operator ("s_anything_operator");

	    if (! empty ($filter) && ! empty ($op))
	      {
		if (isset ($ns_machine_filter))
		  {
		    $ns_machine_filter->fields['s_anything'] = $filter;
		    $ns_machine_filter->fields['s_anything_operator'] = $op;
		  }
	      }
	    else
	      {
		if (isset ($ns_machine_filter))
		  {
		    unset ($ns_machine_filter->fields['s_anything']);
		    unset ($ns_machine_filter->fields['s_anything_operator']);
		  }
		unset ($filter);
		unset ($op);
	      }
	  }
	else if (isset ($ns_machine_filter->fields)
		 && isset ($ns_machine_filter->fields['s_anything'])
		 && isset ($ns_machine_filter->fields['s_anything_operator']))
	  {
	    $filter = $ns_machine_filter->fields['s_anything'];
	    $op = $ns_machine_filter->fields['s_anything_operator'];
	  }

	/* If the filter and operators are set, do the filtering. */
	if (isset ($filter) && isset ($op)
	    && ! empty ($filter) && ! empty ($op))
	  {
	    $search->filter_anything ($filter, $op);
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
		$_SESSION['message'] = "Search Result: ";
		foreach ($searched_fields as $c)
			$_SESSION['message'] .= $c.", ";
		$_SESSION['message'] = substr($_SESSION['message'], 0, strlen($_SESSION['message'])-2);
		$_SESSION['mtype'] = "success";
	}
?>
