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
     * Contents of the <tt>edit_job</tt> page  
     */
?>

<?php
    # edit job from a parametrized job XML file
    # $existFileName = "/usr/share/hamsta/xml_files/multimachine/qa_parameter.xml";
    if(isset($real_file))
        $existFileName = $real_file;

    # define the default data of job XML file
    $jobInfo = array( 'name'=>'',
                      'level'=>'3',
                      'description'=>"Enter job description",
                      'motd'=>'Enter your job MOTD message',
                      'mailto'=>(isset($user) ? $user->getEmail() : 'hamsta@suse.com'),
      	              'reboot'=>0,
                      'rpmlist'=>'',
               );
    $sections = array('worker','finish','abort','kill'); 
    $roleCount = 1;
    $paramCount = 0;
    $totalRoles = 5;
    $totalParts = 10;
    $partCount = 1;
    $jobPartMap = array( array("name" => "", "id" => 1) );
    $jobRoleMap = array( array(
                          'name' => '',
                          'min' => '',
                          'max' => '',
                          'level' => '',
                          'repo' => '',
                          'motd' => '',
                          'rpm' => '',
                          'part_id' => array(1) )
   );

    # if defined "existFileName", it means that it is come from a existing XML file, parse it
    if(isset($existFileName) && ($existFileName != "") && (file_exists($existFileName)))
    {
        if(($xml = simplexml_load_file($existFileName)) != false)
        {
            # get general information
            $jobInfo['name']  = $xml->config->name;
            $jobInfo['level'] = $xml->config->debuglevel;
            $jobInfo['description'] = $xml->config->description;
            $jobInfo['motd'] = $xml->config->motd;
            $jobInfo['mailto'] = $xml->config->mail;
            $jobInfo['reboot'] = $xml->config->reboot;
            foreach($xml->config->rpm as $rpm) {
                $jobInfo['rpmlist'] .= "$rpm ";
            }
            # get parameter map
            $jobParamMap = get_parameter_maps($xml);
            $paramCount = count($jobParamMap);

            # get part map
            $partCount = count($xml->parts->part);
            $i = 0;
            foreach($xml->parts->part as $part) {
                $jobPartMap[$i++] = array(
                                           'name' => $part['name'],
                                           'id' => $part['id']
                );
            }


            # get role map
            $i = 0;
            $roleCount = count($xml->roles->role);
            if($roleCount > 0) {
                foreach($xml->roles->role as $role)
                {
                    //if($role['name'] == "server") var_dump($role);
                    $jobRoleMap[$i] = array(
                                              'name'=>$role['name'],
                                              'min'=>$role['num_min'], 
                                              'max'=>$role['num_max'],
                                              'level'=>$role->config->debuglevel,
                                              'repo'=>$role->config->repository,
                                              'motd'=>$role->config->motd,
                                              'rpm' => ''
                                        );
                    foreach($role->config->rpm as $rpm) {
                        $jobRoleMap[$i]['rpm'] .= "$rpm ";
                    }
                    $role_name = $role['name'];
                    $c=0;
                    foreach($role->commands as $command) {
                        $jobRoleMap[$i]['part_id'][$c] = $command->attributes()->part_id; 
                        foreach( $sections as $sec ) {
                            $j = 0;
                            if(isset($command->$sec)) {
                        	# get command map
                                foreach($command->$sec->command as $cmd)
                                {
                                    $jobCommandMap[$i][$c][$sec][$j++] = array('action'=>$cmd['execution'],
                                                                               'commands'=>$cmd);
                                }
                                //$commandCount[$i][$sec] = count($jobCommandMap);
                            }
                        }
                        $c++;
                    }
                    $i++;
                }
                # sort parameter by key "id"
                foreach ($jobRoleMap as $key=>$value) {
         #           $roleSortKey[$key] = $value['id'];
                }
                #array_multisort($roleSortKey, SORT_NUMERIC, $jobRoleMap);
                $roleCount = count($jobRoleMap);
            }
                print "<input type=\"hidden\" name=\"existfilename\" value=\"$existFileName\">";
        }
    }

    ?>

    <tr><td width="40%">Job name: </td>
    <td><input type="text" size="20" name="jobname" title="required: job name, must be composed by number, letter, underscore or dash" required placeholder="Enter name for the job" value="<?php if (! empty ($jobInfo['name'])) echo $jobInfo['name']; ?>">
    </td></tr>
    <tr><td>Debug level:</td>
    <td>
    <select name="debuglevel" title="required: debug information">
      <?php
      $default_level = $jobInfo['level']?$jobInfo['level']:3;
      for($i=0;$i<10;$i++)
      {
          if($default_level == "$i")
              echo "<option value=\"$i\" selected=\"selected\">Level-$i</option>";
          else
              echo "<option value=\"$i\">Level-$i</option>";
      }
      ?>
    </select> <?php echo "default \"level-$default_level\""; ?>
    </td></tr >
    <tr>
    <td>Description:</td>
    <td><input type="text" size="20" name="description" placeholder="Enter description for the job" title="optional: job description" value="<?php echo $jobInfo['description']; ?>"></td>
    </tr>
    <tr>
    <td>Motd message:</td>
    <td><input type="text" size="20" name="motdmsg" placeholder="Enter MOTD for the SUT" title="optional: /etc/motd message in SUT" value="<?php echo $jobInfo['motd']; ?>"></td>
    </tr>
    <tr>
    <td>Email address:</td>
    <td><input type="email" size="20" name="mailto" placeholder="user@domain.com" title="optional: send mail if address is given" value="<?php echo $jobInfo['mailto']; ?>"></td>
    </tr>
    <tr>
    <td>Needed rpms:</td>
    <td><input type="text" size="20" name="rpmlist" placeholder="rpm1 rpm2 rpm3" title="optional: divided by space, e.g: qa_tools qa_bind" value="<?php echo $jobInfo['rpmlist']; ?>"></td></tr>
    <tr>
    <td><label for="reboot-option">Reboot</label>:</td>
    <td><input id="reboot-option" type="checkbox" size="20" name="reboot" title="optional: set it if job reboot the machine" value=1 "<?php if($jobInfo['reboot']==1) echo ' checked=\"checked\"'; ?>"></td>
    </tr>
    <tr><td>Job Parts:</td>
    <td>
      <input type="hidden" id="part_count" value="<?php echo $partCount?>">
      <?php
      echo '<select name="partnumber" title="required: part number, from 1 to '.
           $totalParts.'" onChange="getNumber(partnumber, \'#part\', '.$totalParts.');">';
      for($j=1;$j<=$totalParts;$j++)
      {
          if(($partCount !=0) && ($j==$partCount))
              echo "<option value=\"$j\" selected=\"selected\">$j</option>";
          else
              echo "<option value=\"$j\">$j</option>";
      }
      ?>
      </select>
    </td>
    </tr>
    <tr><td colspan="2">
    <div>
    <?php
        for($i=0;$i<$totalParts;$i++) {
            $myPartname = ($i<$partCount)?$jobPartMap[$i]['name']:"";
            $myId = ($i<$partCount)?$jobPartMap[$i]['id']:($i+1);
            echo "<div id=\"part_$i\"><p>Part ".$myId.":";
            echo '<input id="part_'.$i.'" style=\"span-left:100px\" type="text" size="20" name="job_parts[]" placeholder="Enter part name" title="required: Given a part name" value="'.$myPartname.'"></p></div>';
        }
    ?>
    </div>
    </td></tr>
    <!-- Additional parameters -->
    <tr>
    <td>
    <input id="edit-parameters" type="checkbox" name="param_flag" value="paramFlag" title="Edit additional Parameters" onclick="editParameters()">
    <label for="edit-parameters">Edit addtional parameters</label>
    </td>
    <td>
    <div id="param_edit">
        <select id="param_type" name="param_type" title="required: please chose one parameter type">
                <option value="string">string</option>
                <option value="enum">enum</option>
                <option value="textarea">textarea</option>
        </select>&nbsp;
        <input type="button" value="x" style="color:red;" size="1px" title="Delete one selected parameter" onclick="addDelOneParam(0, <?php echo $paramCount; ?>)">
        <input type="button" value="+" size="1px" title="Add one parameter" onclick="addDelOneParam(1, <?php echo $paramCount; ?>)">
    </div>
    </td>
    </tr>
    <tr>
    <td colspan="2">
    <div id="param_div"><b>Edit your addtional parameter here:</b><br /><br />
    <table class="text-main">
    <?php
    if($paramCount > 0) # if it is edit a parameter job XML file
    {
        $paramNo = 1;
        $option_num = array();
        foreach($jobParamMap as $param) # get all of current parameter variables
        {
            $type = trim($param['type']);
            $name = trim($param['name']);
            $label = trim($param['label']);

            if($label == "")
                $label = $name;
            $default = trim($param['default']);

            $content = $param['content'];
            if($content == "")
                $content = $default;
            $content_split = explode("\n", $content);

            $content_default = "";
            foreach($content_split as $content_line)
            {
                if(($content_line = trim($content_line)) == "")
                    continue;
                $content_default .= $content_line . "\n";
            }

            $optlist = $param['option'];
            $option_num[$paramNo] = 0;

            if($type == "string")
                echo "<tr id = param_" . $paramNo . "><td width=\"3px\"><input type=\"checkbox\" name=\"param_checked\" value=" . $paramNo . " title=\"select and delete it\"></td><td width=\"50px\"><input type=\"hidden\" name=\"param_type[]\" value=\"string\"  ><input type=\"hidden\" name=\"param_sort[]\" value=\"" . $paramNo . "\">name:</td><td width=\"50px\"><input type=\"text\" name=\"param_name[]\" title=\"required: Paramter name\" value=\"" . $name . "\" size=\"8px\"></td><td width=\"50px\">label:</td><td width=\"50px\"><input type=\"text\" name=\"param_label[]\" title=\"optional: Paramter label\" value=\"" . $label . "\" size=\"8\"></td><td width=\"50px\">value:</td><td colspan=\"3\" width=\"50px\"><input type=\"text\" name=\"param_default[]\" title=\"required: default value of this parameter\" value=" . $content . " size=\"26\"></td></tr>";

            if($type == "enum")
            {
                $optionNum = count($optlist);

                echo "<tr id = param_" . $paramNo . "><td width=\"3px\"><input type=\"checkbox\" name=\"param_checked\" value=" . $paramNo . " title=\"select and delete it\"></td><td width=\"50px\"><input type=\"hidden\" name=\"param_type[]\" value=\"enum\"    ><input type=\"hidden\" name=\"param_sort[]\" value=\"" . $paramNo . "\">name:</td><td width=\"50px\"><input type=\"text\" name=\"param_name[]\" title=\"required: Paramter name\" value=\"" . $name . "\" size=\"8px\"></td><td width=\"50px\">label:</td><td width=\"50px\"><input type=\"text\" name=\"param_label[]\" title=\"optional: Paramter label\" value=\"" . $label . "\" size=\"8\"></td><td width=\"50px\">value:</td><td><input type=\"text\" name=\"param_default[]\" title=\"required: default value of this parameter, should be one of the value of optons below\" value=\"" . $default . "\" size=\"10\"></td><td width=\"125px\" align=\"left\"><div>options:&nbsp<input type=\"button\" value=\"x\" style=\"color:#FF0000;\" title=\"Delete the selected option\" onclick=\"addDelOneOption(0, " . $paramNo . ", " . $optionNum . ")\"><input type=\"button\" value=\"+\" title=\"add one option for the enumeration parameter\" onclick=\"addDelOneOption(1, " . $paramNo . ", " . $optionNum . ")\"><table class=\"text-main\">";
                foreach($optlist as $option)
                {
                    $option_num[$paramNo]++;
                    $label = $option['label'];
                    $value = $option['value'];
                     echo "<tr id = option_" . $paramNo  . "_" . $option_num[$paramNo] . "><td><input type=\"checkbox\" name=\"option_checked" . $paramNo . "\" value=\"" . $option_num[$paramNo] . "\" title=\"select and delete it\"></td><td>label:</td><td><input type=\"text\" name=\"option_" . $paramNo . "_label[]\" title=\"required: option label\" value=\"" . $label . "\" size=\"8px\"></td><td>value:</td><td><input type=\"text\" name=\"option_" . $paramNo . "_value[]\" title=\"required: option value\" value=\"" . $value . "\" size=\"8px\"></td></tr>";
                    
                }

                echo "</table></div><span id=\"option" . $paramNo . "\"></span></td></tr>";

            }

            if($type == "textarea")
                echo "<tr id = param_$paramNo>".
                     '<td width="3px">'.
                     '<input type="checkbox" name="param_checked" value=' . $paramNo . ' title="select and delete it">'.
                     '</td>'.
                     '<td width="50px">'.
                     '<input type="hidden" name="param_type[]" value="textarea">'.
                     '<input type="hidden" name="param_sort[]" value="' . $paramNo . '">name:'.
                     '</td><td width="50px">'.
                     '<input type="text" name="param_name[]" title="required: Paramter name" value="' . $name . '" size="8px">'.
                     '</td>'.
                     '<td width="50px">label:</td>'.
                     '<td width="50px">'.
                     '<input type="text" name="param_label[]" title="optional: Paramter label" value="' . $label . '" size="8">'.
                     '</td>'.
                     '<td width="50px">value:</td>'.
                     '<td colspan="5">'.
                     '<textarea cols="30" rows="5" name="param_default[]" title="required: default value of this parameter">'.
                     $content_default. '</textarea></td></tr>';
            ;

            # Define any other type of parameter here

            $paramNo++;
        }
    }
    ?>
    </table>
    <span id="additional_param"></span></td></tr>
    </div>
    <tr><td colspan="2">
    <input type="hidden" id="role_count" value="<?php echo $roleCount?>">
    </td></tr>
    <tr><td colspan="2">
<!--
    <div id="singlemachine_form">
    <table class="text-main" width="900px">
    <tr><td width="40%">Commands (one per line):</td>
-->
    <?php
/*
    if($commandCount > 0)
        $commands = trim($jobCommandMap[0]['commands']);
    else
        $commands = "#!/bin/sh\necho custom job";
    echo "<td><textarea cols=\"50\" rows=\"10\" id=\"commands\" name=\"commands_content_single\" title=\"required: write your script here, one command per line.\">$commands</textarea><span class=\"required\">*</span>";
*/
    ?>
<!--
    </td></tr>
    </table></div>
-->
    </td></tr>
    
    <tr><td colspan="2">
    <div id="multimachine_form">
    <table class="text-main" width="900px">
    <tr><td width="40%">Role number:</td>
    <td>
      <?php
      echo '<select name="rolenumber" title="required: role number, from 1 to '.
           $totalRoles.'" onChange="getNumber(rolenumber,\'#role\', '.$totalRoles.');">';
      for($j=1;$j<=$totalRoles;$j++)
      {
          if(($roleCount !=0) && ($j==$roleCount))
              echo "<option value=\"$j\" selected=\"selected\">$j</option>";
          else
              echo "<option value=\"$j\">$j</option>";
      }
      ?>
    </select>
    </td></tr>
    <tr><td colspan="2">
    <div class="rt-container">
    <?php
    for($i=0; $i<$totalRoles; $i++)
    {
        if($i<$roleCount) {
	    $name = ($jobRoleMap[$i]['name'] == "")?($i+1):$jobRoleMap[$i]['name'];
	    $min = ($jobRoleMap[$i]['min'] == "")?1:$jobRoleMap[$i]['min'];
	    $max = ($jobRoleMap[$i]['max'] == "")?2:$jobRoleMap[$i]['max'];
            $part_id = $jobRoleMap[$i]['part_id'];
        }
        else {
            $name = $i+1;
            $min = 1;
            $max = 2;
            $part_id = array( 1 );
            $jobRoleMap[$i]['motd'] = "";
            $jobRoleMap[$i]['rpm'] = "";
            $jobRoleMap[$i]['level'] = "";
            $jobRoleMap[$i]['repo'] = "";
        }
//        echo "<div id=\"role_$i\">";
        echo "<span id=\"roletab_$i\" class=\"rolespan\"></span>";
        echo "<div id=\"role_$i\">\n";
        echo "<a href=\"#roletab_$i\" title=\"Role_$name\">Role_$name</a>";
        echo "<div id=\"rcontent_$i\" class=\"roletab-content\">";
        echo "<table class=\"text-main\">\n";
        //echo "<tr><td colspan=\"2\"><hr style=\"border:1px dashed\"></td><tr>\n";
        //echo "<tr><td colspan=\"2\"><b>Edit SUT Role #$i:</b></td><tr>\n";
        echo "<tr><td>Role name: </td>";
        echo "<td><input id=\"role_$i\" type=\"text\" size=\"20\" name=\"rolename[]\" value=\"$name\" title=\"required: role name\"></td>\n";
        echo "</tr>\n";
        echo "<tr><td>Minimum machines: </td>";
        echo "<td><select name=\"minnumber[]\" title=\"required: Select the minimum number for role $i\">";
        for($j=1;$j<=10;$j++)
        {
            if($j==$min)
                echo "<option value=\"$j\" selected=\"selected\">$j</option>";
            else
                echo "<option value=\"$j\">$j</option>";
        }
        echo "</select></td></tr>\n";
        echo "<tr><td>Maximum machines: </td>";
        echo "<td><select name=\"maxnumber[]\" title=\"required: Select the maximum number for role $i\">";
        for($j=1;$j<=20;$j++)
        {
            if($j == $max)
                echo "<option value=\"$j\" selected=\"selected\">$j</option>";
            else
                echo "<option value=\"$j\">$j</option>";
        }
        echo "</select></td></tr>\n";
        echo "<tr><td>Debug level:</td>";
        echo '<td><select name="role_dbglevel[]" title="required: debug information">';
        $default_level = $jobRoleMap[$i]['level'] ? $jobRoleMap[$i]['level'] : 3;
        for($l=0;$l<10;$l++)
        {
            if($default_level == "$l")
                echo "<option value=\"$l\" selected=\"selected\">Level-$l</option>";
            else
                echo "<option value=\"$l\">Level-$l</option>";
        }
        echo "</select>default \"level-$default_level\"";
        echo '</td></tr >';
        echo "<tr><td>Motd message:</td>";
        echo '<td><input type="text" size="20" name="role_motd[]" placeholder="Enter MOTD for the SUT" title="optional: /etc/motd message in SUT" value='.$jobRoleMap[$i]['motd'].'></td>';
        echo '</tr>';
        echo "<tr><td>Repository:</td>";
        echo '<td><input type="text" size="20" name="role_repo[]" placeholder="Enter repo for the SUT" title="optional: Extra repo" value='.$jobRoleMap[$i]['repo'].'></td>';
        echo '</tr>';
        echo "<tr><td>Needed rpms:</td>";
        echo '<td><input type="text" size="20" name="role_rpm[]" placeholder="Enter rpm names for the SUT" title="optional: seperated by blank" value='.$jobRoleMap[$i]['rpm'].'></td>';
        echo '</tr>';
        echo '<tr><td>Job Parts:</td>';
        echo '<td>';
        $part_num = count($part_id);
        echo '<input type="hidden" id="rpart_count'.$i.'" value="'.$part_num.'">';
        echo '<select name="roleparts[]" title="required: part number, from 1 to '.
             $totalParts.'" onChange="getNumber(this, \'#rpart_'.$i.'\', '.$totalParts.');">';
        for($j=1;$j<=$totalParts;$j++)
        {
            if(($partCount !=0) && ($j==$part_num))
                echo "<option value=\"$j\" selected=\"selected\">$j</option>";
            else
                echo "<option value=\"$j\">$j</option>";
        }
        echo '</select></td></tr>';
        echo '<tr><td colspan="2">';
        echo '<article class="ptabs">';
        for($c=0;$c<$totalParts;$c++) {
            $myPartName = ($c < $part_num)?$part_id[$c]:"#"; 
            $myPartId = ($c < $part_num)?$part_id[$c]:""; 
            echo '<div id="rpart_'.$i.'_'.$c.'" class="ppanels">';
            echo '<input id="Part_' . "$i$c" . '" type="radio" name="ptabs"';
            if( $c==0 ) echo ' checked="checked"';
            echo '><label for="Part_' . "$i$c" . '">Part_' . $myPartName.'</label>';
            echo '<div class="ppanel">';
            echo '<label>Part ID:</label>';
            echo '<input type="text" id="rpart_'.$i.'_'.$c.'" size="20" name="'.
                 $name.'_ptid[]" placeholder="Enter part id" title="required: part id" value="'.$myPartId.'">';
            // construct commands panel 
            echo '<article class="stabs">';
            foreach( $sections as $sec ) {
                echo '<div class="spanels">';
                echo '<input id="' . "$sec$i$myPartName" . '" name="sectabs" type="radio"';
                if( $sec == "worker") echo ' checked="checked"';
                echo '><label for="' . "$sec$i$myPartName" . '">'.$sec.'</label>';
      	        $commands = (isset($jobCommandMap[$i][$c][$sec][0]['commands'])?
                                    $jobCommandMap[$i][$c][$sec][0]['commands']:"");
                echo '<div class="spanel"><textarea 
                      cols="60" rows="10" 
                      align="left" 
                      name="commands_content_multiple[]" 
                      placeholder="Please write your script here, one command per line." 
                      title="optional: write your script here, one command per line.">';
                echo $commands;
                echo '</textarea></div>';
                echo "</div>";
            }
            echo "</article>";
            echo "</div>\n";
            echo "</div>";
        }
        echo "</article></td></tr>";
        echo "</table></div></div>\n";
    }

    ?>
    </div></td></tr>
    </table></div>  <!-- End of mm_form area -->

