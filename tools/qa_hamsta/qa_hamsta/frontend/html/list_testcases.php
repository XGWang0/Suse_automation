<?php
    /**
     * Contents of the <tt>list_testcases</tt> page 
     */
    if (!defined('HAMSTA_FRONTEND')) {
        $go = 'edit_machines';
        return require("index.php");
    }
//    error_reporting(E_ALL | E_STRICT);

?>

<h2>List all testcases</h2>
<h6>Hint: job file creation is alpha code and may not work as expected, contact <a href="mailto:pkirsch@suse.de">me</a><h6>
<form action="index.php?go=list_testcases" method="post">
<table class="list">
    <tr>
        <th>Testsuite</th>
        <th>Expand</th>
        <th>Run?</th>
    </tr>
 <?php while($row=mysql_fetch_array($result_testsuitenames)) {
	 echo "<TR><TD>$row[0]</TD> <TD><a href='index.php?go=list_testcases&show_testcases=$row[0]'>$row[0]</a> </TD><TD><input type=\"checkbox\" name=\"runthem[]\" value=\"$row[0]\"></input></TD> </TR> ";
	 if (isset($show_testcases))
	 if($show_testcases == $row[0]) {
		// print the testcases in a sub table
	?>
	<TR>
		<TD></TD>
	<TD>
	<p>	<table class="list">
		<tr>
        	<th>Testcase</th>
        	<th>Run?</th>
		</tr>
	<?php
		while($testcase_row=mysql_fetch_array($result_testcases)) {
		echo "<TR><TD>$testcase_row[0]</TD> <TD><input type=\"checkbox\" name=\"runthem_testcase[]\" value=\"$testcase_row[0]\"></input></TD> </TR> ";
		}
	?> </TABLE></p>
	</TD></TR>

 <?php
	 }
	}
 ?>
 </table>

<input type="submit" name="submit" value="Run">

</form>
