<?php
    /**
     * Contents of the <tt>send_job</tt> page  
     */
    if (!defined('HAMSTA_FRONTEND')) {
        $go = 'send_job';
        return require("index.php");
    }
	$blockedMachines = array();
	foreach ($machines as $machine) {
		if (($machine->is_busy() == 2) || ($machine->is_busy() == 4)) {
			$blockedMachines[] = $machine->get_hostname();
		}
	}
	if(count($blockedMachines) != 0) {
		echo "<div class=\"text-medium\">" .
			"The following machines are currently either marked as \"Not accepting jobs\" or \"Outdated (Blocked)\":<br /><br />" . 
			"<strong>" . implode(", ", $blockedMachines) . "</strong><br /><br />" .
			"Please go back to free up these machines and then try sending the job again." .
		"</div>";
	} else {

?>
<span class="text-main">(<span class="required">*</span>) required field(s)</span>
<h2 class="text-medium text-blue bold">Pre-defined Jobs</h2>
<p class="text-main">
Pre-defined jobs are configuration tasks or test runs that have been pre-defined and stored on the automation servers. If you want to pre-define a job and add it to this list, please email qa-automation@suse.de
</p>
<form action="index.php?go=send_job" method="post" name="predefinedjobs" onsubmit="return checkcheckbox(this);">
<p class="text-main">
<b>Job(s) will run on the following machine(s): </b>
<?php
    $flag=0;
    foreach ($machines as $machine):
	echo('<input type="hidden" name="a_machines[]" value="'.$machine->get_id().'">');
	if( $flag ) echo ', ';
	echo($machine->get_hostname() );
	$flag=1;
    endforeach;
?>
</p>
<table id="jobs" class="text-main">
    <thead>
	<tr>
	    <th>&nbsp;</th>
	    <th>Job XML</th>
	    <th>Controls</th>
	</tr>
    </thead>
    <?php
# see XML_DIR and XML_WEB_DIR in config.php
    $dir=XML_DIR;
    if(is_dir($dir))
    {
        if($handle = opendir($dir))
        {
            while(($file = readdir($handle)) !== false)
            {
                if($file != "." && $file != ".." && substr($file,-4)=='.xml')
                {
					$jobdoc = new DOMDocument();
					$jobdoc->load( "$dir/$file" );
					$jobxmlnodes = $jobdoc->getElementsByTagName( "job" );
					foreach ( $jobxmlnodes as $xmlnode ) {
						$name = $xmlnode->getElementsByTagName( "name" );
						$jobname = $name->item(0)->nodeValue;
						$description = $xmlnode->getElementsByTagName( "description" );
						$jobdescription = $description->item(0)->nodeValue;
					}
                    echo "    <tr class=\"file_list\">\n";
		    echo "        <td><input type=\"checkbox\" name=\"filename[]\" value=\"$dir/$file\" title=\"pre-defined job:$file\">\n";
                    echo "        <td title=\"$jobdescription\">$jobname</td>\n";
                    echo "        <td class=\"viewXml\"><a href=\"".XML_WEB_DIR."/$file\" target=\"_blank\" title=\"view $file\">(view)</a></td>\n";
                    echo "    </tr>\n";
                }
            }
            closedir($handle);
        }
    }
    ?>
</table>
<br/>
<span class="text-main"><b>Email address: </b></span>
<input type="text" name="mailto" title="optional: send mail if address is given"/>
<a onmouseout="MM_swapImgRestore()" onmouseover="MM_swapImage('qmark1','','../hamsta/images/qmark1.gif',1)">
<img src="../hamsta/images/qmark.gif" name="qmark1" id="qmark1" border="0" width="18" height="20" title="click me for clues of email" onclick="window.open('../hamsta/helps/email.html','channelmode', 'width=550, height=450, top=250, left=450')"/></a>
<br/><br>
<input type="submit" name="submit" value="Send pre-defined job(s)">
</form>
<script type="text/javascript">
<!--
var TSort_Data = new Array ('jobs', '','s','' );
tsRegister();
-->
</script>



<HR>
<h2 class="text-medium text-blue bold">Multi-machine Jobs</h2>
<p class="text-main">
This is a subcategory of pre-defined jobs intended for client/server tests, and for other tests that run on multiple machines.
Jobs in this category have different roles for different machines, you will be asked to assign machines to roles.
</p>
<form action="index.php?go=mm_job" method="post" name="multimachinejobs" onsubmit="return checkradio(this);">
<p class="text-main">
<b>Job(s) will run on the following machine(s): </b>
<?php
    $flag=0;
    foreach ($machines as $machine):
	echo('<input type="hidden" name="a_machines[]" value="'.$machine->get_id().'">');
	if( $flag ) echo ', ';
	echo($machine->get_hostname() );
	$flag=1;
    endforeach;
?>
</p>
<table id="mmjobs" class="text-main">
    <thead>
	<tr>
	    <th>&nbsp;</th>
	    <th>Job XML</th>
	    <th>Controls</th>
	</tr>
    </thead>
    <?php
# see XML_MULTIMACHINE_DIR and XML_MULTIMACHINE_WEB_DIR in config.php
    $dir=XML_MULTIMACHINE_DIR;
    if(is_dir($dir))
    {
        if($handle = opendir($dir))
        {
            while(($file = readdir($handle)) !== false)
            {
                if($file != "." && $file != ".." && substr($file,-4)=='.xml')
                {
                    echo "    <tr class=\"file_list\">\n";
		    echo "        <td><input type=\"radio\" name=\"filename\" value=\"$dir/$file\" title=\"pre-defined job:$file\">\n";
                    echo "        <td>$file</td>\n";
                    echo "        <td class=\"viewXml\"><a href=\"".XML_MULTIMACHINE_WEB_DIR."/$file\" target=\"_blank\" title=\"view $file\">(view)</a></td>\n";
                    echo "    </tr>\n";
                }
            }
            closedir($handle);
        }
    }
    ?>
</table>
<br/>
<span class="text-main"><b>Email address: </b></span>
<input type="text" name="mailto" title="optional: send mail if address is given"/>
<a onmouseout="MM_swapImgRestore()" onmouseover="MM_swapImage('qmark','','../hamsta/images/qmark1.gif',1)">
<img src="../hamsta/images/qmark.gif" name="qmark" id="qmark" border="0" width="18" height="20" title="click me for clues of email" onclick="window.open('../hamsta/helps/email.html','channelmode', 'width=550, height=450, top=250, left=450')"/></a>
<br/><br>
<input type="submit" name="submit" value="Send multi-machine job">
</form>
<script type="text/javascript">
<!--
var TSort_Data = new Array ('mmjobs', '','s','' );
tsRegister();
-->
</script>

<HR>
<h2 class="text-medium text-blue bold">QA-packages Jobs (require SLES install repo and SDK repo)</h2>
<p class="text-main">
QA-packages Jobs are used to launch various test suites on your System Under Test (SUT) machines. Simply select one, or multiple test suites from the list below to run these on the currently selected SUT system(s).
</p>
<form action="index.php?go=qapackagejob" method="POST" name="qapackagejob" onsubmit="return checkcheckbox(this);"> 
<table class="text-main">
    <tr><td><b>Selected job(s) will run on the following machine(s): </b></td><td>
    <?php
        $flag=0;
        foreach ($machines as $machine):
            echo('<input type="hidden" name="a_machines[]" value="'.$machine->get_id().'">');
            if( $flag ) echo ', ';
            echo($machine->get_hostname() );
            $flag=1;
        endforeach;
        echo "</td></tr></table><table class=\"text-main\">";

	$tslist=TSLIST;
	$test_suites="";
	$arr=split (" ", $tslist);
        $i=0;
	sort ($arr);
        foreach ($arr as $value)
        { 
          if ($i%6==0) {echo "<tr>";} 
          echo "<td style=\"padding: 5px;\">" .
              "<input name=testsuite[] type=checkbox value=$value title=\"check one at least\"/>" .
              "$value " .
              "<a href=\"http://qa.suse.de/automation/qa-packages?package=" . urlencode($value) . "#" . urlencode($value) . "\" target=\"_blank\">" .
                  "<img src=\"images/icon-info.png\" alt=\"Click for information\" title=\"Click for information\" width=\"15\" border=\"0\" />" .
              "</a>" .
          "</td>";
          if ($i%6==5) {echo "</tr>";}
	  if ($i==count($arr)) {echo "end</tr>";}
          $i++;
        }
    ?>
<tr><td></td></tr>
<tr><td><input type="checkbox" value="checkall" onclick='chkall("qapackagejob",this)' name=chk>Select all</td></tr>
</table>
<br/>
<span class="text-main"><b>Email address: </b></span>
<input type="text" name="mailto" title="optional: send mail if address is given"/>
<br/><br>
<input type="submit" name="submit" value="Send QA-packages job">
</form>

<HR>
<h2 class="text-medium text-blue bold">Autotest Jobs</h2>
<p class="text-main">
Auto test jobs. Here we only provide typic test for each autotest component. If you want to have fully custom test, please go to http://autotest.suse.cz/afe
</p>
<form action="index.php?go=autotest" method="POST" name="autotest" onsubmit="return checkcheckbox(this);">
<table class="text-main">
    <tr><td><b>Selected job(s) will run on the following machine(s): </b></td><td>
    <?php
        $flag=0;
        foreach ($machines as $machine):
            echo('<input type="hidden" name="a_machines[]" value="'.$machine->get_id().'">');
            if( $flag ) echo ', ';
            echo($machine->get_hostname() );
            $flag=1;
        endforeach;
        echo "</td></tr></table><table class=\"text-main\">";

    $atlist=ATLIST;
    $test_suites="";
    $arr=split (" ", $atlist);
    $i=0;
    sort ($arr);
        foreach ($arr as $value)
        {
          if ($i%6==0) {echo "<tr>";}
          echo "<td style=\"padding: 5px;\"><input name=testsuite[] type=checkbox value=$value title=\"check one at least\"/>$value</td>";
          if ($i%6==5) {echo "</tr>";}
      if ($i==count($arr)) {echo "end</tr>";}
          $i++;
        }
    ?>
<tr><td></td></tr>
<tr><td><input type="checkbox" value="checkall" onclick='chkall("autotest",this)' name=chk>Select all</td></tr>
</table>
<br/>
<span class="text-main"><b>Email address: </b></span>
<input type="text" name="mailto" title="optional: send mail if address is given"/>
<br/><br>
<input type="submit" name="submit" value="Send Autotest job">
</form>

<HR>
<h2 class="text-medium text-blue bold">Custom Jobs</h2>
<p class="text-main">
Custom Jobs are used for running any kind of configuration task that you may need to send to your test systems. To set up and run a configuration task, sipmly fill out and submit this form. If this configuration task is one that you would like to re-use in the future, be sure to check the "Add this job to the pre-defined job list" box so that you can return to this page later and run that same configuration task as a "Pre-defined Job".
</p>
<form action="index.php?go=customjob" method="POST" name="customjob" onSubmit="return checkcontents(this)">
<table class="text-main">
    <tr>
    <td><b>Job will run on the following machine(s): </b></td>
    <td>
    <?php
        $flag=0;
        foreach ($machines as $machine):
            echo('<input type="hidden" name="a_machines[]" value="'.$machine->get_id().'">');
            if( $flag ) echo ', ';
            echo($machine->get_hostname() );
            $flag=1;
        endforeach;
        echo "</td></tr></table><table class=\"text-main\">";
    ?>
    <tr><td>Custom job name: </td>
    <td><input type="text" size="20" name="jobname" title="required: job name"><span class="required">*</span>
    </td></tr>
    <tr><td>Debug level:</td>
    <td>
    <select name="debuglevel" title="required: debug information"> 
      <option value="1">Level-1</option>
      <option value="2">Level-2</option>
      <option value="3" selected="selected">Level-3</option>
      <option value="4">Level-4</option>
      <option value="5">Level-5</option>
      <option value="6">Level-6</option>
      <option value="7">Level-7</option>
      <option value="8">Level-8</option>
      <option value="9">Level-9</option>
      <option value="10">Level-10</option>
    </select> default "level-3"
    </td></tr>
    <tr><td>Description:</td>
    <td><input type="text" size="20" name="description" title="optional: job descption"></td></tr>
    <tr><td>Motd message:</td>
    <td><input type="text" size="20" name="motdmsg" title="optional: /etc/motd message in SUT"></td></tr>
    <tr><td>Email address:</td>
    <td><input type="text" size="20" name="mailto" title="optional: send mail if address is given">
    </td></tr>
    <tr><td>Needed rpms:</td>
    <td><input type="text" size="20" name="rpmlist" title="optional: divided by space, e.g: qa_tools qa_bind"></td></tr>
    <tr><td>Commands (one per line):</td>
    <td><textarea cols="50" rows="10" id="commands" name="commands" title="required: write your script here, one command per line."></textarea><span class="required">*</span>
    </td></tr>
    <tr><td><input type="checkbox" value="addtopredefine" name="addtopredefine">Add this job to the pre-defined job list</td></tr>
    <tr><td><input type="submit" name="submit" value="Send custom job"></td></tr>
</table>
</form>

<?php
}
?>
