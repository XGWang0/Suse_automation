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
	switch (request_str("action")) {
		case "machine_edit":
			$go = "machine_edit";
			return require("inc/machine_edit.php");

		case "machine_delete":
			$go = "machine_delete";
			return require("inc/machine_delete.php");

		case "create_group":
			$go = "create_group";
			return require("inc/create_group.php");
		
		case "group_del_machines":
			$go = "group_del_machines";
			return require("inc/group_del_machines.php");
		
		case "machine_send_job":
			$go = "machine_send_job";
			return require("inc/machine_send_job.php");

		case "merge_machines":
			$go = "merge_machines";
			return require("inc/merge_machines.php");

		case "machine_config":
			$go = "machine_config";
			return require("inc/machine_config.php");

	   case "machine_reinstall":
			$go = "machine_reinstall";
			return require("inc/machine_reinstall.php");
	   
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
	   case "addsut":
			$go = "addsut";
			return require("inc/addsut.php");
	   case 'machine_reserve':
			$go = 'machine_reserve';
			return require ('inc/machine_reserve.php');
           case 'release_machine_for_master':
			$go = "release_machine_for_master";
			return require ('inc/release_machine_for_master.php');
	}

	$searched_fields = array();
	$d_fields = array();
	# Check which Display Field is checked, push to $d_fields
	foreach ($fields_list as $key=>$value)
        {
            /* Due to connection of displayed fields and
             * filters I had to add an exception
             * here. */
            if (in_array ($key, $default_fields_list))
            {
                continue;
            }
	    $check_field = request_str("DF_".$key);
            if ( $check_field == "on" )
	    {
		array_push($d_fields,$key);
	    }
	}

        /* The var $navi_or_form_request_flag  is used to differentiate 
           where the request to display the machine list from.
           0: means from the click of "Machines" menu at the top of the website or just http://ip/hamsta
           1: means from the "display field" show button click, which is to change the display setting.
        */
        $navi_or_form_request_flag = 0;
        $check_field = request_str("flage_for_display_set");
        if ( $check_field == "on" )
            {
                $navi_or_form_request_flag = 1;
            }

	$search = new MachineSearch();
	$search->filter_role('SUT');	# Only interested in SUT on this page

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
	 * if the request is from form, then set display_fields as well as session data to what is set, none is allowed.
	 * else if history session data is stored, then use stored session data as display_fields
	 * else it is the first login or logout,then set the value to defaults.
	 */
        if($navi_or_form_request_flag)
        {
            $display_fields = $d_fields;
            // Save decision to session if possible. 
            // Set only to values sent in the request. 
            if (isset ($ns_machine_fields) && isset ($ns_machine_fields->fields))
                {
                   $ns_machine_fields->unsetAll ();
                   $ns_machine_fields->fields = $d_fields;
                }
        }
        else
        {
            if (isset ($ns_machine_fields) && isset ($ns_machine_fields->fields))
                {
                   $display_fields = $ns_machine_fields->fields;
                }
            else
                {
                  if (!isset ($display_fields))
                    {
                        $display_fields = array ("usage", "expires_formated",
                                             "product",
                                             "architecture_capable",
                                             "kernel");
                        if ( ! empty ($group_filter) )
                         {
                                array_push ($display_fields, 'group');
                         }

                        if ( isset ($ns_machine_fields) )
                        {
                                $ns_machine_fields->unsetAll ();
                                $ns_machine_fields->fields = $display_fields;
                         }
                     }
                }
        }


	$a_machines = request_array("a_machines");

	$highlight = request_str("s_anything");
	if (empty($highlight)) $highlight = request_str("s_module_description");
	if (empty($highlight)) $highlight = request_str("s_module_driver");
	if (empty($highlight)) $highlight = request_str("s_module_element_value");
	if (empty($highlight)) $highlight = request_str("s_module_element");
	$highlight = urlencode($highlight);

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
	{
		/* Iterate over all available fields (table columns) and apply
		 * filters on it. */
		foreach ($fields_list as $key => $value)
		{
			$fname = "filter_" . $key;
			//$filter = request_str ($key);
			$filter = "";
	
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
					if ($key == 'used_by')
					{
						$filters = $ns_machine_filter->fields[$key];
						if (isset($filters))
						{
							$u = User::getCurrent();
							foreach ($filters as $k => $v)
							{
								if ($k=='my' && $v==$u->getId())
								{
									$search->filter_reservation($u, 'my');
								}
								if ($k=='free' && $v=='on')
								{
									$search->filter_reservation($u, 'free');
								}
								if ($k=='others' && $v=='on')
								{
									$search->filter_reservation($u, 'others');
								}
							}
						}
					}
					else
					{
						$filter = $ns_machine_filter->fields[$key];
					}
				}
			}
			else 
			{
				if ($key == 'group')
				{
					$filter = request_str ($key);
					if ( ! empty($filter) )
						$ns_machine_filter->fields[$key] = $filter;
				}
			}
	
			/* If the filter method is available we also set the
			 * field to be displayed. */

			if ( ! empty ($filter) && method_exists ($search, $fname))
					//&& (request_str ('set') == 'Search'
				//		|| ($key == 'group')) )
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

			if (! empty ($fname) && ! empty ($filter)
					&& method_exists ($search, $fname))
			{
				$search->$fname ($filter);
			}
		}
	}
	

	if (request_str ('set') == 'Search')
	{
		$flag_no_srch = true;
		/* add search for rough reservation, such as, my, free, others*/
		$advanced_search = request_str("show_advanced"); 
		$my = request_str("my");
		$free = request_str("free");
		$others = request_str("others");
		$u = User::getCurrent();
		$selected_searches = array();
		if ( !empty($my) && $my=="on" )
		{
			$search->filter_reservation($u, 'my');
			$selected_searches['my'] = $u->getId();
		}
	
		if ( !empty($free) && $free=="on" )
		{
			$search->filter_reservation($u, 'free');
			$selected_searches['free'] = $free;
		}
	
		if ( !empty($others) && $others=="on" )
		{
			$search->filter_reservation($u, 'others');
			$selected_searches['others'] = $others;
		}

		if (count($selected_searches) > 0)
		{
			$ns_machine_filter->fields["used_by"] = $selected_searches;
			$flag_no_srch = false;
		}

		//add advanced search here
		if (isset($advanced_search) && ! empty($advanced_search))
		{
			$flag_no_srch = false;
			/* Iterate over all available fields (table columns) and apply
			 * filters on it. */
			foreach ($fields_list as $key => $value)
			{
				$fname = "filter_" . $key;
				$filter = request_str ($key);
		
				/* Use filter stored in the session, if it is not in
				 * this request. */
/*
				if (isset ($ns_machine_filter->fields)
						&& empty ($filter)
						&& in_array ($key, array_keys ($ns_machine_filter->fields)))
				{
					// Unset the value if the user sets empty value. /
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
*/
				/* If the filter method is available we also set the
				 * field to be displayed. */
				if ( ! empty ($filter) && method_exists ($search, $fname))
						//&& (request_str ('set') == 'Search'
						//	|| ($key == 'group')) )
				{
					if ( isset ($ns_machine_filter->fields) && 
						! (in_array ($key, $ns_machine_fields->fields) || 
							in_array ($key, $default_fields_list)))
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
					if (! empty($filter) && method_exists ($search, $fname))
					{
						$ns_machine_filter->fields[$key] = $filter;
					}
				}

		
				if (! empty ($fname) && ! empty ($filter)
						&& method_exists ($search, $fname))
				{
					$search->$fname ($filter);
				}
			}
		}

		//end of advanced search
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
		
		$modules_names = request_is_array("s_module") ? request_array("s_module") : request_str("s_module") ? (array) request_str("s_module") : array();

		$modules_descriptions = request_is_array("s_module_description") ? request_array("s_module_description") : request_str("s_module_description") ? (array) request_str("s_module_description") : array();

		$modules_drivers = request_is_array("s_module_driver") ? request_array("s_module_driver") : request_str("s_module_driver") ? (array) request_str("s_module_driver") : array();

		$modules_elements = request_is_array("s_module_element") ? request_array("s_module_element") : request_str("s_module_element") ? (array) request_str("s_module_element") : array();

		$modules_element_values = request_is_array("s_module_element_value") ? request_array("s_module_element_value") : request_str("s_module_element_value") ? (array) request_str("s_module_element_value") : array();
	
		if (count($modules_names)>0)
		{
			if (isset ($ns_machine_filter))
			{
				$ns_machine_filter->fields['s_module'] = $modules_names;
				if (isset($modules_descriptions) && count ($modules_descriptions)>0 )
					$ns_machine_filter->fields['s_module_description'] = $modules_descriptions;
				if (isset($modules_drivers) && count ($modules_drivers)>0 )
					$ns_machine_filter->fields['s_module_driver'] = $modules_drivers;
				if (isset($modules_elements) && count ($modules_elements)>0 )
					$ns_machine_filter->fields['s_module_element'] = $modules_elements;
				if (isset($modules_element_values) && count ($modules_element_values)>0 )
					$ns_machine_filter->fields['s_module_element_value'] = $modules_element_values;
				else{}
			}
		}
		else 
		{
			// clean up session variables
			if (isset ($ns_machine_filter))
			{
				unset ($ns_machine_filter->fields['s_module']);
				unset ($ns_machine_filter->fields['s_module_description']);
				unset ($ns_machine_filter->fields['s_module_driver']);
				unset ($ns_machine_filter->fields['s_module_element']);
				unset ($ns_machine_filter->fields['s_module_element_value']);
			}
			unset ($modules_names);
			unset ($modules_descriptions);
			unset ($modules_drivers);
			unset ($modules_elements);
			unset ($modules_element_values);
		}

	}
	else if (isset ($ns_machine_filter->fields))
	{
		if(isset ($ns_machine_filter->fields['s_anything']) 
			&& isset ($ns_machine_filter->fields['s_anything_operator']))
		{
			$filter = $ns_machine_filter->fields['s_anything'];
			$op = $ns_machine_filter->fields['s_anything_operator'];
		}
		else if (isset ($ns_machine_filter->fields['s_module'])
			&&(isset ($ns_machine_filter->fields['s_module_descritpion'])
			|| isset ($ns_machine_filter->fields['s_module_driver'])
			|| isset ($ns_machine_filter->fields['s_module_element'])
			|| isset ($ns_machine_filter->fields['s_module_element_value'])))
		{
			$modules_names = $ns_machine_filter->fields['s_module'];
			$modules_descriptions	= (isset ($ns_machine_filter->fields['s_module_descritpion'])) ?
				$ns_machine_filter->fields['s_module_description'] : array();
			$modules_drivers	= (isset ($ns_machine_filter->fields['s_module_driver'])) ?
				$ns_machine_filter->fields['s_module_driver'] : array();
			$modules_elements	= (isset ($ns_machine_filter->fields['s_module_element'])) ?
				$ns_machine_filter->fields['s_module_element'] : array();
			$modules_element_values	= (isset ($ns_machine_filter->fields['s_module_element_value'])) ?
				$ns_machine_filter->fields['s_module_element_value'] : array();
		}
	}
	/* If the filter and operators are set, do the filtering. */
	if (isset ($filter) && isset ($op)
	    && ! empty ($filter) && ! empty ($op))
	  {
	    $search->filter_anything ($filter, $op);
	  }

	if (isset ($modules_names) && is_array($modules_names))
	{
		foreach ($modules_names as $i => $module_name) {
			if ((count($modules_descriptions)>0) && ($filter = $modules_descriptions[$i])) {
				$search->filter_module_description($module_name, $filter);
			}
			if ((count($modules_drivers)>0) && ($filter = $modules_drivers[$i])) {
				$search->filter_module_driver($module_name, $filter);
			}
			if ((count($modules_elements)>0) && ($filter = $modules_elements[$i])) {
				$search->filter_module_element($module_name, $filter, $modules_element_values[$i]);
			}
		}
	}

	$machines = $search->query();

	// apply fulltext search
	if (request_str ('set') == 'Search')
	{
	
		$fulltext = request_str('fulltext');
		$s_hidden_field = request_str('searchall');
		$hide_match_field = request_str('hidematch');
	}
	else
	{
		//if the search criteria is store in session, apply it.
		if (isset($ns_machine_filter))
		{
			$fulltext = isset($ns_machine_filter->fields['fulltext']) ? 
					$ns_machine_filter->fields['fulltext'] : null;
			$s_hidden_field = isset($ns_machine_filter->fields['search_hidden_field']) ? 
					$ns_machine_filter->fields['search_hidden_field'] : null;
			$hide_match_field = isset($ns_machine_filter->fields['hide_match_field']) ? 
					$ns_machine_filter->fields['hide_match_field'] : null;
		}
	}
	
	if (isset($fulltext) && ! empty($fulltext))
	{
		$machines = fulltext_search($machines, $fulltext, $s_hidden_field, $hide_match_field);
		$flag_no_srch = false;
	}
	else
	{
		$ns_machine_filter->fields["fulltext"] = null;
		unset($ns_machine_filter->fields["fulltext"]);
	}

	if (isset($flag_no_srch) && $flag_no_srch == true)
	{
		/*
		   if there is no search condition specified, clean ns_machine_filter and $ns_machine_filed
		 */
		if (isset ($ns_machine_fields))
		{
			$ns_machine_fields->unsetAll ();
		}
	
		if (isset ($ns_machine_filter))
		{
			$ns_machine_filter->unsetAll ();
		}
	}

	if (request_str("s_group"))
		foreach ($machines as $machine)
			$a_machines[] = $machine->get_id();

	$html_title = "Machines";

	if ($searched_fields) {
		$_SESSION['message'] = "Search Result: ";
		foreach ($searched_fields as $c)
			$_SESSION['message'] .= $c.", ";
		$_SESSION['message'] = substr($_SESSION['message'], 0, strlen($_SESSION['message'])-2);
		$_SESSION['mtype'] = "success";
	}

	function fulltext_search($machines, $fulltext, $s_hidden_field, $hide_match_field)
	{
		global $ns_machine_filter;
		global $default_fields_list;
		global $display_fields;
		global $fields_list;
		
		if (! isset($machines) || count($machines) == 0)	
			return array();

		$ns_machine_filter->fields["fulltext"] = $fulltext;
		require_once('lib/MachineFilter.php');
		if (isset($s_hidden_field) && !empty($s_hidden_field))
		{
			$ns_machine_filter->fields["search_hidden_field"] = $s_hidden_field;
			$mf = new MachineFilter($machines, $fulltext, array_keys($fields_list));
		}
		else
		{
			$tmp_fields_list = array_merge($default_fields_list, $display_fields);
			$tmp_fields_list = array_unique($tmp_fields_list);
			$mf = new MachineFilter($machines, $fulltext, $tmp_fields_list);
		}
		$machines = $mf->filter();
		$match_fields = $mf->getMatchFields();
		if (!isset($hide_match_field) || empty($hide_match_field))
		{
			foreach ($match_fields as $match_field)
			{
				if (!in_array($match_field, $display_fields) && !in_array($match_field, $default_fields_list))
				{
					array_push($display_fields, $match_field);
				}
			}
		}
		if (isset($hide_match_field) && !empty($hide_match_field))
			$ns_machine_filter->fields["hide_match_field"] = $hide_match_field;
	
		return $machines;

	}
?>
