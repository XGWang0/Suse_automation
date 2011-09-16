<?php
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
