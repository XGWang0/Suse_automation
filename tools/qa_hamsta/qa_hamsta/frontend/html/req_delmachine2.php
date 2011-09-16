<ul>
  <?php foreach ($machines as $machine): ?>
  <li><input type="hidden" name="a_machines[]" value="<?php echo($machine->get_id()); ?>"><a href="index.php?go=machine_details&amp;id=<?php echo($machine->get_id()); ?>"><?php echo($machine->get_hostname()); ?></a></li>
  <?php endforeach; ?>
</ul>
<p>Are you sure that this is what you want to do?</p>
<?php
    echo "<div class=\"text-medium\">\n";
    (count($machines) > 1) ? $name="them" : $name="it";
    echo "<input type=\"submit\" name=\"cancel\" value=\"No, keep $name.\">\n";
    echo "<input type=\"submit\" name=\"submit\" value=\"Yes, delete $name.\">\n";
    echo "</div>\n";
?>
