<?php
    /**
     * Logic of the create_group page
     *
     * Get all machines that should be used for the creation of a new group
     * and create this group, if the form was submitted.
     */
    if (!defined('HAMSTA_FRONTEND')) {
        $go = 'create_group';
        return require("index.php");
    }

	# See if this is an edit or an add
	if(isset($_GET['action']) and $_GET['action'] == "edit")
	{
		$action = "edit";
		$group = Group::get_by_name($_GET['group']);
		if($group == null)
		{
			echo "<div class=\"failmessage\">Unable to retrieve group data. Please try again.</div>";
		}
		$name = $group->get_name();
		$id = $group->get_id();
		$description = $group->get_description();
	}
	else
	{
		$action = "add";
	}

    $search = new MachineSearch();
    $search->filter_in_array(request_array("a_machines"));
    $machines = $search->query();
    
    if (request_str("submit")) {
        $failed = 0;
        switch(request_str("action")) {
            case "create":
                $name = request_str("name");
                if (!$name) {
                    $error = "You must enter a group name.";
                    break;
                }
                
                $description = request_str("description");
				$groupCreateResult = Group::create($name, $description, $machines);
				if($groupCreateResult == -2)
				{
					echo "<div class=\"failmessage\">There is already a group with that name! Please try again.</div>";
				}
				else if($groupCreateResult < 0)
				{
					echo "<div class=\"failmessage\">There was an unknown error creating the group. Please try again.</div>";
				}
				else
				{
					echo "<div class=\"successmessage\">Group created!</div>";
				}
                break;

            case "edit":
				$action = "edit";
                $name = request_str("name");
				$id = request_str("id");
				$description = request_str("description");
				$group = Group::get_by_id($id);

				# Make sure this is a valid group before proceeding
				if($group == null)
				{
					echo "<div class=\"failmessage\">Unable to retrieve group data. Please try again.</div>";
				}
				else
				{
					if (!$name) {
						$error = "You must enter a group name.";
						$name = $group->get_name();
						break;
					}
					$groupCreateResult = $group->edit($name, $description);
					if($groupCreateResult == -2)
					{
						echo "<div class=\"failmessage\">There is already a group with that name! Please try again.</div>";
					}
					else if($groupCreateResult < 0)
					{
						echo "<div class=\"failmessage\">There was an unknown error editing the group. Please try again.</div>";
					}
					else
					{
						echo "<div class=\"successmessage\">Group modified!</div>";
					}
				}
                break;

            case "add":
                $name = request_str("add_group");
                $group = Group::get_by_name($name);

                if (is_null($group)) {
                    $error = "The selected group to add the machines to does not exist.";
                } else {
                    foreach($machines as $machine) {
                        if (!$group->add_machine($machine)) {
                            $failed++;
                        }
                    }
                }
                break;
        }
            
        if (empty($error)) {
            if ($failed) {
                $error = $failed . " machine(s) could not be added (possibly were already member?)";
            }
        
            $go = "groups";
            return require('inc/groups.php');
        }
    }

    $html_title = "Add to group";
?>
