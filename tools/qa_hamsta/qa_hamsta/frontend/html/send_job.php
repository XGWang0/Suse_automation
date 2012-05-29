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
     * Contents of the <tt>send_job</tt> page  
     */
    if (!defined('HAMSTA_FRONTEND')) {
        $go = 'send_job';
        return require("index.php");
    }
	if ($openid_auth) {
		$user = User::get_by_openid($_SESSION['OPENID_AUTH']);
	}
	$blockedMachines = array();
	foreach ($machines as $machine) {
		if( ! $machine->has_perm('job') ) {
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

<script type="text/javascript" src="js/edit_job.js"></script>

<span class="text-main">(<span class="required">*</span>) required field(s)</span>
<h2 class="text-medium text-blue bold">Single-machine Jobs</h2>
<p class="text-main">
Single-machine jobs are configuration tasks or test runs that have been stored on the automation servers, this is a subcategory of pre-defined jobs intended for single machine tests. If you want to pre-define a job and add it to this list, please email qa-automation@suse.de
</p>
<form action="index.php?go=send_job" method="post" name="predefinedjobs" onsubmit="return checkcheckbox(this);">
<p class="text-main">
<b>Job(s) will run on the following machine(s): </b>
<?php
    $flag=0;
    $machine_list = "";
    foreach ($machines as $machine):
	echo('<input type="hidden" name="a_machines[]" value="'.$machine->get_id().'">');
	if( $flag ){
		echo ', ';
		echo($machine->get_hostname() );
		$machine_list .= "," . $machine->get_id();
	}
	else{
		echo($machine->get_hostname() );
		$machine_list = $machine->get_id();
	}
	$flag=1;
    endforeach;
?>
</p>
<div id="predefined" class="text-main">
<table id="jobs" class="text-main" width="600px">
	<thead>
	<tr>
	    <th width="10px">&nbsp;</th>
	    <th width="60%">Job XML</th>
	    <th align="centre">Controls</th>
	</tr>
        </thead>
    <?php
# see XML_DIR and XML_WEB_DIR in config.php

    $dir=XML_DIR;
    if(is_dir($dir))
    {
        if($handle = opendir($dir))
        {
	    $sortcount = 0;  # at first, I wanna use the XML file name, but failed, I have to sort the XML and use the sort number.
            while(($file = readdir($handle)) !== false)
            {
                if($file != "." && $file != ".." && substr($file,-4)=='.xml')
		{
			$filebasename = substr($file, 0, -4);

			$xml = simplexml_load_file( "$dir/$file" );
			$jobname = $xml->config->name;
			$jobdescription = $xml->config->description;

			$param_map = get_parameter_maps($xml);
			$count = count($param_map);
					
                    echo "    <tr class=\"file_list\">\n";
		    # echo "        <td><input type=\"checkbox\" name=\"filename[]\" value=\"$dir/$file\" title=\"single-machine job:$file\" onclick=\"showParamConts('$filebasename')\">\n";
		    echo "        <td><input type=\"checkbox\" name=\"filename[]\" value=\"$dir/$file\" title=\"Single-machine job:$file\" onclick=\"showParamConts( $sortcount )\"></td>\n";
                    echo "        <td title=\"$jobdescription\">$file</td>\n";
                    echo "        <td class=\"viewXml\" align=\"center\">\n";
                    echo "            <a href=\"".XML_WEB_DIR."/$file\" target=\"_blank\" title=\"view $file\"><img src=\"images/icon-vnc.png\" alt=\"view\" title=\"view the job XML $file\" border=\"0\" width=\"20\" style=\"padding-right: 3px;\" /></a>\n";
                    echo "            <a href=\"index.php?go=edit_jobs&amp;file=$file&amp;opt=edit&amp;machine_list=$machine_list\" title=\"edit $file\"><img src=\"images/icon-edit.png\" alt=\"edit\" title=\"Edit the job XML $file\" border=\"0\" width=\"20\" style=\"padding-right: 3px;\" /></a>\n";
                    echo "        </td>";
		    echo "     </tr>\n";
                    echo "     <tr class=\"file_list\">\n";
		    echo "        <td colspan=\"3\">\n";
		    if( $count > 0 )
		    {

		    	echo "        <div style=\"margin-left: 40px; margin-top: 2px; padding: 2px 2px 10px 2px; border: 1px solid #cdcdcd\" id=\"div_$sortcount\">\n";
			echo "            <div class=\"text-main\" style=\"padding: 5px 5px 5px 5px\"><b>Edit parameters in the form below.</b></div>\n";
			
			# get the parameter table, avoid the same parameter name in different jobs
			$prefix_name = $filebasename . "_";
			$parameter_table = get_parameter_table($param_map, $prefix_name);

			echo $parameter_table;
			echo "        </div>\n";
		    }

		    echo "        </td>\n";
		    echo "    </tr>\n";

		    $sortcount++;
                }
            }
            closedir($handle);
        }
    }

    ?>
</table>

<table id="jobs_custom" class="text-main" width="600px">
        <thead>
	<tr>
	    <th width="10px">&nbsp;</th>
	    <th width="60%">Custom Job XML</th>
	    <th align="centre">Controls</th>
	</tr>
	</thead>
    <?php
# see XML_DIR and XML_WEB_DIR in config.php
    $dir=XML_DIR_CUSTOM;
    if(is_dir($dir))
    {
        if($handle = opendir($dir))
        {
	    # $sortcount = 0;  # at first, I wanna use the XML file name, but failed, I have to sort the XML and use the sort number.
            while(($file = readdir($handle)) !== false)
            {
                if($file != "." && $file != ".." && substr($file,-4)=='.xml')
		{
			$filebasename = substr($file, 0, -4);

			$xml = simplexml_load_file( "$dir/$file" );
			$jobname = $xml->config->name;
			$jobdescription = $xml->config->description;

			$param_map = get_parameter_maps($xml);
			$count = count($param_map);
					
                    echo "    <tr class=\"file_list\">\n";
		    # echo "        <td><input type=\"checkbox\" name=\"filename[]\" value=\"$dir/$file\" title=\"single-machine job:$file\" onclick=\"showParamConts('$filebasename')\">\n";
		    echo "        <td><input type=\"checkbox\" name=\"filename[]\" value=\"$dir/$file\" title=\"Single-machine custom job:$file\" onclick=\"showParamConts( $sortcount )\"></td>\n";
                    echo "        <td title=\"$jobdescription\">$file</td>\n";
                    echo "        <td class=\"viewXml\" align=\"center\">\n";
                    echo "            <a href=\"".XML_WEB_DIR_CUSTOM."/$file\" target=\"_blank\" title=\"view $file\"><img src=\"images/icon-vnc.png\" alt=\"view\" title=\"view the job XML $file\" border=\"0\" width=\"20\" style=\"padding-right: 3px;\" /></a>\n";
                    echo "            <a href=\"index.php?go=edit_jobs&amp;file=custom/$file&amp;opt=edit&amp;machine_list=$machine_list\" title=\"edit $file\"><img src=\"images/icon-edit.png\" alt=\"edit\" title=\"Edit the job XML $file\" border=\"0\" width=\"20\" style=\"padding-right: 3px;\" /></a>\n";
                    echo "            <a href=\"index.php?go=send_job&amp;file=custom/$file&amp;opt=delete&amp;machine_list=$machine_list\" onclick=\"if(confirm('WARNING: You will delete the custom job XML file, are you sure?')) return true; else return false;\" title=\"delete $file\"><img src=\"images/icon-delete.png\" alt=\"delete\" title=\"Delete the job XML $file\" border=\"0\" width=\"20\" style=\"padding-right: 3px;\" /></a>\n";
                    echo "    </tr class=\"file_list\">\n";
                    echo "    <tr>\n";
		    echo "        <td colspan=\"3\">\n";
		    if( $count > 0 )
		    {

		    	echo "        <div style=\"margin-left: 40px; margin-top: 2px; padding: 2px 2px 10px 2px; border: 1px solid #cdcdcd\" id=\"div_$sortcount\">\n";
			echo "            <div class=\"text-main\" style=\"padding: 5px 5px 5px 5px\"><b>Edit parameters in the form below.</b></div>\n";
			
			# get the parameter table
			
			# define the parameter prefix name
                        # $filebasename is used to distinguish the same parameter name in different jobs
                        # "_custom_" is used to ditinguish the same XML file name in default directory and custom directory
			$prefix_name = $filebasename . "_custom_";
			$parameter_table = get_parameter_table($param_map, $prefix_name);

			echo $parameter_table;
			echo "        </div>\n";
		    }

		    echo "        </td>\n";
		    echo "    </tr>\n";

		    $sortcount++;
                }
            }
            closedir($handle);
        }
    }

    ?>
</table>

</div>
<br/>
<span class="text-main"><b>Email address: </b></span>
<input type="text" name="mailto" title="optional: send mail if address is given" value="<?php if ($openid_auth) { echo $user->get_email(); } ?>" />
<a onmouseout="MM_swapImgRestore()" onmouseover="MM_swapImage('qmark1','','../hamsta/images/qmark1.gif',1)">
<img src="../hamsta/images/qmark.gif" name="qmark1" id="qmark1" border="0" width="18" height="20" title="click me for clues of email" onclick="window.open('../hamsta/helps/email.html','channelmode', 'width=550, height=450, top=250, left=450')"/></a>
<br/><br>
<!-- tell js how much single machine jobs there are. -->
<input type="hidden" id="smj_count" value="<?php echo "$sortcount" ?>">
<input type="submit" name="submit" value="Send Single-machine job(s)">
</form>
<script type="text/javascript">
<!--
//var TSort_Data = new Array ('jobs', '','s','' );
//tsRegister();
//var TSort_Data = new Array ('jobs_custom', '','s','' );
//tsRegister();
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
    $machine_list = "";
    foreach ($machines as $machine):
	echo('<input type="hidden" name="a_machines[]" value="'.$machine->get_id().'">');
	if( $flag ){
		echo ', ';
		echo($machine->get_hostname() );
		$machine_list .= "," . $machine->get_id();
	}
	else{
		echo($machine->get_hostname() );
		$machine_list = $machine->get_id();
	}
	$flag=1;
    endforeach;
?>


</p>
<table id="mmjobs" class="text-main" width="600px">
    <thead>
	<tr>
	    <th width="10px">&nbsp;</th>
	    <th width="60%">Job XML</th>
	    <th align="centre">Controls</th>
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
		    echo "        <td><input type=\"radio\" name=\"filename\" value=\"$dir/$file\" title=\"Multi-machine job:$file\"></td>\n";
                    echo "        <td>$file</td>\n";
                    echo "        <td align=\"center\">";
                    echo "            <a href=\"".XML_MULTIMACHINE_WEB_DIR."/$file\" target=\"_blank\" title=\"view $file\"><img src=\"images/icon-vnc.png\" alt=\"view\" title=\"view the job XML $file\" border=\"0\" width=\"20\" style=\"padding-right: 3px;\" /></a>";
                    echo "            <a href=\"index.php?go=edit_jobs&amp;file=multimachine/$file&amp;opt=edit&amp;machine_list=$machine_list\" title=\"edit $file\"><img src=\"images/icon-edit.png\" alt=\"edit\" title=\"Edit the job XML $file\" border=\"0\" width=\"20\" style=\"padding-right: 3px;\" /></a>";
                    echo "        </td>\n";
                    echo "    </tr>\n";
                }
            }
            closedir($handle);
        }
    }
    ?>
</table>

<?php

$dir=XML_MULTIMACHINE_DIR_CUSTOM;
if(is_dir($dir))
{
?>
<table id="mmjobs_custom" class="text-main" width="600px">
    <thead>
        <tr>
            <th width="10px">&nbsp;</th>
            <th width="60%">Custom Job XML</th>
            <th align="centre">Controls</th>
        </tr>
    </thead>
    <?php
# see XML_MULTIMACHINE_DIR and XML_MULTIMACHINE_WEB_DIR in config.php
    #print "$dir <br />";
    //print "<br /> 2 ----------------------------- <br />machine_targets = $machine_targets <br />";
    if(is_dir($dir))
    {
        if($handle = opendir($dir))
        {
            while(($file = readdir($handle)) !== false)
            {
                if($file != "." && $file != ".." && substr($file,-4)=='.xml')
                {
                    echo "    <tr class=\"file_list\">\n";
                    echo "        <td><input type=\"radio\" name=\"filename\" value=\"$dir/$file\" title=\"Multi-machine custom job:$file\"></td>\n";
                    echo "        <td>$file</td>\n";
                    echo "        <td align=\"center\">";
                    echo "            <a href=\"".XML_MULTIMACHINE_WEB_DIR_CUSTOM."/$file\" target=\"_blank\" title=\"view $file\"><img src=\"images/icon-vnc.png\" alt=\"vire\" title=\"View the job XML $file\" border=\"0\" width=\"20\" style=\"padding-right: 3px;\" /></a>";
                    echo "            <a href=\"index.php?go=edit_jobs&amp;file=multimachine/custom/$file&amp;opt=edit&amp;machine_list=$machine_list\" title=\"edit $file\"><img src=\"images/icon-edit.png\" alt=\"edit\" title=\"Edit the job XML $file\" border=\"0\" width=\"20\" style=\"padding-right: 3px;\" /></a>";
                    echo "            <a href=\"index.php?go=send_job&amp;file=multimachine/custom/$file&amp;opt=delete&amp;machine_list=$machine_list\" onclick=\"if(confirm('WARNING: You will delete the custom job XML file, are you sure?')) return true; else return false;\" title=\"delete $file\"><img src=\"images/icon-delete.png\" alt=\"delete\" title=\"Delete the job XML $file\" border=\"0\" width=\"20\" style=\"padding-right: 3px;\" /></a>";
                    echo "        </td>\n";
                    echo "    </tr>\n";
                }
            }
            closedir($handle);
        }
    }
}
?>
</table>
<br/>
<span class="text-main"><b>Email address: </b></span>
<input type="text" name="mailto" title="optional: send mail if address is given" value="<?php if ($openid_auth) { echo $user->get_email(); } ?>" />
<a onmouseout="MM_swapImgRestore()" onmouseover="MM_swapImage('qmark','','../hamsta/images/qmark1.gif',1)">
<img src="../hamsta/images/qmark.gif" name="qmark" id="qmark" border="0" width="18" height="20" title="click me for clues of email" onclick="window.open('../hamsta/helps/email.html','channelmode', 'width=550, height=450, top=250, left=450')"/></a>
<br/><br>
<input type="submit" name="submit" value="Send multi-machine job">
</form>
<script type="text/javascript">
<!--
var TSort_Data = new Array ('mmjobs', '','s','' );
tsRegister();
var TSort_Data = new Array ('mmjobs_custom', '','s','' );
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
<tr><td><b>UI tests:</b></td></tr>
	<?php
		$UIlist=UILIST;
		$arr=split(" ", $UIlist);
		sort($arr);
		$i=0;
		foreach ($arr as $value) {
			if ($i%6==0) {echo "<tr>\n";}
			echo "<td stype=\"padding: 5px;\">";
			echo "<lable><input name=testsuite[] type=\"checkbox\" value=\"$value\" title=\"check one at least\"/>$value</label>";
			echo "<a href=\"http://qa.suse.de/automation/qa-packages?package=" . urlencode($value) . "#" . urlencode($value) . "\" target=\"_blank\">".
				"<img src=\"images/icon-info.png\" alt=\"Click for information\" title=\"Click for information\" width=\"15\" border=\"0\" /></a>";
			echo "</td>";
			if ($i%6==5) {echo "</tr>\n";}
			$i++;	
		}
	?>
<tr></tr>

<tr><td><input type="checkbox" value="checkall" onclick='chkall("qapackagejob",this)' name=chk>Select all</td></tr>
</table>
<br/>
<span class="text-main"><b>Email address: </b></span>
<input type="text" name="mailto" title="optional: send mail if address is given" value="<?php if ($openid_auth) { echo $user->get_email(); } ?>" />
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
<input type="text" name="mailto" title="optional: send mail if address is given" value="<?php if ($openid_auth) { echo $user->get_email(); } ?>" />
<br/><br>
<input type="submit" name="submit" value="Send Autotest job">
</form>

<HR>
<h2 class="text-medium text-blue bold">Custom Jobs</h2>
<p class="text-main">
Custom Jobs are used for running any kind of configuration task that you may need to send to your test systems. To set up and run a configuration task, sipmly fill out and submit this form. If this configuration task is one that you would like to re-use in the future, be sure to check the "Add this job to the custom job list" box so that you can return to this page later and run that same configuration task as a custom job.
</p>
<p class="text-main">
You can create two type of job: Single-machine job and Multi-machine job, for Single-machine job, you just need configure the command line, and the XML file will be saved as "Single-machine job" if you select to save it by checking the "Add this job to the custom job list"; For Multi-machine job, you need configure some more data for all of roles in the form below, you can set the role number up to 5 according to what your need, the XML file will be saved as "Multi-machine job" if you select to save it. Futhermore, if you select to save you job, you can edit it in the send job page later.
</p>
<form action="index.php?go=customjob" method="POST" name="customjob" onSubmit="return checkcontents(this)">
<table class="text-main">
    <tr>
    <td><b>Job will run on the following machine(s): </b></td>
    <td>
    <?php
    $machine_list="";
    $flag=0;
    foreach ($machines as $machine):
        echo('<input type="hidden" name="a_machines[]" value="'.$machine->get_id().'">');
        if( $flag ){
                echo ', ';
                echo($machine->get_hostname() );
                $machine_list .= "," . $machine->get_id();
        }
        else{
                echo($machine->get_hostname() );
                $machine_list = $machine->get_id();
        }
        $flag=1;
    endforeach;
        echo "</td></tr></table><table class=\"text-main\" width=\"900px\"";
	echo "<input type=\"hidden\" name=\"machine_list\" value=\"$machine_list\">";
    ?>

    <?php require("edit_job.php"); ?>

    <tr><td colspan="2"><input type="checkbox" value="addtoCustomJob" name="addtoCustomJob">Add this job to the custom job list</td></tr>
    <tr><td><input type="submit" name="submit" value="Send custom job"></td></tr>
    <input type="hidden" name="customflag" value="1">
</table>
</form>

<?php
}
?>
