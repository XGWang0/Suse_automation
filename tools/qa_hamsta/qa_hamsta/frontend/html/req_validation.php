  <!-- a temp file -->
  <tr>
        <td>Also run validation tests?</td>
        <td><input type="checkbox" value="yes" name="startvalidation"<?php if(isset($_POST['startvalidation']) and $_POST['startvalidation'] == "yes"){echo " checked=\"checked\"";} ?> />Yes, run validation tests automatically after the installation</td>
  </tr>
