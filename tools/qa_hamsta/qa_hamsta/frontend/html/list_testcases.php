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
     * Contents of the <tt>list_testcases</tt> page 
     */
    if (!defined('HAMSTA_FRONTEND')) {
        $go = 'machine_edit';
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
