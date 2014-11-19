<?PHP
$roleTemplate = '
<span class="rolespan" id="roletab_ROLE_INDEX"></span>
<div id="role_ROLE_INDEX">
  <a title="ROLE_NAME" id="role_ROLE_INDEX_name" onClick="clickChild(this,\'#Part_ROLE_INDEX0\')" href="#roletab_ROLE_INDEX">ROLE_NAME</a>
  <div class="roletab-content" id="rcontent_ROLE_INDEX">
    <table class="text-main">
      <tbody>
        <tr>
          <td>Role name:</td>
          <td><input type="text" 
                     title="required: role name" 
                     value="ROLE_NAME" 
                     name="rolename[]" 
                     onblur="syncName(this,\'role\')"
                     size="20" id="role_ROLE_INDEX"></td>
        </tr>
        <tr>
          <td>Minimum machines:</td>
          <td>
            <select title="required: Select the minimum number for role ROLE_INDEX" 
                    name="minnumber[]">MINIMUM
            </select>
          </td>
        </tr>
        <tr>
          <td>Maximum machines:</td>
          <td>
            <select title="required: Select the maximum number for role ROLE_INDEX" 
                    name="maxnumber[]">MAXIMUM
            </select>
          </td>
        </tr>
        <tr>
          <td>Debug level:</td>
          <td>
            <select title="required: debug information" name="role_dbglevel[]">DEBUG_LEVEL
            </select>
            default "DEFAULT_LEVEL"
          </td>
        </tr>
        <tr>
          <td>Repository:</td>
          <td><input type="text" value="ROLE_REPO" 
                     title="optional: Extra repo" 
                     placeholder="Enter repo URL" 
                     name="role_repo[]" size="20"></td>
        </tr>
        <tr>
          <td>Needed rpms:</td>
          <td><input type="text" value="ROLE_RPM" 
                     title="optional: seperated by blank" 
                     placeholder="Enter rpm names for the SUT" 
                     name="role_rpm[]" size="20"></td>
        </tr>
        <tr>
          <td>MOTD message:</td>
          <td><input type="text" value="ROLE_MOTD"
                     title="optional: /etc/motd message in SUT" 
                     name="role_motd[]" size="20"></td>
        </tr>
        <tr>
          <td colspan="2">
            <article class="ptabs">ROLE_PART_CONTENT
            </article>
          </td>
        </tr>
      </tbody>
    </table>
  </div>
</div>
';



$partPanel = '
              <div class="ppanels" id="ROLE_PART_ID">
                <input type="radio" checked="checked" 
		       name="ptabs" id="ROLE_PART_LABEL" 
		       onClick="clickChild(this,\'#workerROLE_INDEXPART_INDEX\')">
                <label id="roleROLE_INDEXpart_PART_INDEX" for="ROLE_PART_LABEL">MYPARTNAME</label>
                <div class="ppanel">
                  <article class="stabs">SECTION_CONTENT
                  </article>
                </div>
              </div>
';

$secPanel='
                    <div class="spanels">
                      <input type="radio" name="sectabs" id="SECTION_ID">
                      <label for="SECTION_ID">SECNAME</label>
                      <div class="spanel">
                        <textarea align="left" 
                                  title="optional: write your script here, one command per line." 
                                  placeholder="Please write your script here, one command per line." 
                                  name="commands_content[]"
                                  rows="10"
                                  cols="60">COMMAND_CONTENT</textarea>
                      </div>
                    </div>
';
?>
