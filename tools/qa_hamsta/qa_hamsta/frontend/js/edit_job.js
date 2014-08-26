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

var param_num = 0;
var param_real_num = 0;
var param_static = 0;
var option_static = new Array();
var option_num = new Array();
var option_real_num = new Array();
var rpart_count = new Array();

function showHide(idPre, showNum, total) {
	for(e=0; e<total; e++)
	{
		var myTag = 'input' + idPre + e;
		var myTitle = $(myTag).attr('title');
		if(e < showNum) { 
			$(idPre + e).show();
			myTitle = myTitle.replace(/^optional/,"required");
			$(myTag).attr('title', myTitle);
		} else {
			$(idPre + e).hide();
			myTitle = myTitle.replace(/^required/,"optional");
			$(myTag).attr('title', myTitle);
		}
	}
}
$(document).ready(function(){
	$('#param_edit').hide();
	$('#param_div').hide();

	var role_count = document.getElementById('role_count').value;
	var part_count = document.getElementById('part_count').value;
	for(i=0; i<5; i++)
	{
		rpart_count[i] = document.getElementById('rpart_count'+i).value;
		showHide('#rpart_' + i + '_', rpart_count[i], 10);
       //         console.log($('input#rpart_' + i + '_1').attr("title"));
	}
	//$('#singlemachine_form').hide();
	//$('#multimachine_form').show();
	showHide('#role_', role_count, 5);
	showHide('#part_', part_count, 10);
	for(i=0;i<10;i++)
	{
		option_static[i] = 0;
		option_num[i] = 0;
		option_real_num[i] = 0;
	}

//	var smj_count = document.getElementById('smj_count').value;
//	for(i=0; i<smj_count; i++)
//		$('#div_' + i).hide();

});

function editParameters()
{
	$('#param_edit').slideToggle("slow");
	$('#param_div').slideToggle("slow");
}

function showParamConts(n)
{
	$('#div_' + n).slideToggle("slow");
}

var job_static = 0;
var getJobType =  function(select)
{
	var idx = select.selectedIndex, option, value;
        if(idx > -1)
        {
                option = select.options[idx];
                value = option.attributes.value;
                jobtype = (value && value.specified)?option.value:option.text;
                if(jobtype == 1)
		{
			/*
			if(job_static == 0)
			{
				$('#singlemachine_form').slideToggle("slow");
				job_static = 1;
			}
			else
			{
				$('#singlemachine_form').slideToggle("slow");
				$('#multimachine_form').slideToggle("slow");
			}
			*/
			$('#singlemachine_form').show();
			$('#multimachine_form').hide();
                	//$('#jobTypeOpt').remove();

		}
                else if(jobtype == 2)
		{
			/*
			if(job_static == 0)
			{
				$('#singlemachine_form').slideToggle("slow");
				job_static = 1;
			}
			else
			{
				$('#singlemachine_form').slideToggle("slow");
				$('#multimachine_form').slideToggle("slow");
			}
			*/
			$('#singlemachine_form').hide();
			$('#multimachine_form').show();
		}
		else
		{
			//job_static = 0;
			$('#singlemachine_form').hide();
			$('#multimachine_form').hide();

		}
                return jobtype;
        }
        return NULL;
}

var getNumber = function(select, type, total)
{
	console.log(select);
	var idx = select.selectedIndex, option, value;
        console.log("jhao"+idx);
	if(idx > -1)
	{
		//$('#roleNumOpt').remove();
		option = select.options[idx];
		value = option.attributes.value;
		num = (value && value.specified)?option.value:option.text;
                showHide(type+'_', num, total);
		return num;
	}
	return NULL;
}

function addDelOneParam(act, n)
{
        if(param_static == 0)
        {
            param_num = n;
            param_real_num = n;
            param_static = 1;
        }
	var type = document.getElementById('param_type').value;
	if(act == '1') // add one parameter
	{
		if(param_real_num >= 10)
		{
			alert("Sorry, you can't define additional parameters more than 10");
			return null;
		}

		param_num++;
		param_real_num++;
		if(type == "string")
		{
			var app_str = '<tr id = "param_' + param_num + '"><td width="3px"><input type="checkbox" name="param_checked" value="' + param_num + '" title="select and delete it"></td><td width="50px"><input type="hidden" name="param_type[]" value="string"><input type="hidden" name="param_sort[]" value="' + param_num + '">name:</td><td width="50px"><input type="text" name="param_name[]" title="required: Paramter name" size="8px"></td><td width="50px">label:</td><td width="50px"><input type="text" name="param_label[]" title="optional: Paramter label" size="8"></td><td width="50px">value:</td><td colspan="3" width="50px"><input type="text" name="param_default[]" title="required: default value of this parameter" size="26"></td></tr>';
			$('#additional_param').append(app_str);
		}
		if(type == "enum")
		{
			var app_str = '<tr id = "param_' + param_num + '"><td width="3px"><input type="checkbox" name="param_checked" value="' + param_num + '" title="select and delete it"></td><td width="50px"><input type="hidden" name="param_type[]" value="enum"><input type="hidden" name="param_sort[]" value="' + param_num + '">  name:</td><td width="50px"><input type="text" name="param_name[]" title="required: Paramter name" size="8px"></td><td width="50px">label:</td><td width="50px"><input type="text" name="param_label[]" title="optional: Paramter label" size="8"></td><td width="50px">value:</td><td><input type="text" name="param_default[]" title="required: default value of this parameter, should be one of the value of optons below" size="10"></td><td width="125px" align="left"><div>options:&nbsp<input type="button" value="x" style="color:#FF0000;" title="Delete the selected option" onclick="addDelOneOption(0, ' + param_num + ', 0)"><input type="button" value="+" title="add one option for the enumeration parameter" onclick="addDelOneOption(1, ' + param_num + ', 0)"></div><span id="option' + param_num + '"></span></td></tr>';
			$('#additional_param').append(app_str);
		}
		if(type == "textarea")
		{
			var app_str = '<tr id = "param_' + param_num + '"><td width="3px"><input type="checkbox" name="param_checked" value="' + param_num + '" title="select and delete it"></td><td width="50px"><input type="hidden" name="param_type[]" value="textarea"><input type="hidden" name="param_sort[]" value="' + param_num + '">name:</td><td><input type="text" name="param_name[]" title="required: Paramter name" size="8px"></td><td>label:</td><td><input type="text" name="param_label[]" title="optional: Paramter label" size="8"></td><td>value:</td><td colspan="3"><textarea cols="32" rows="5" name="param_default[]" title="required: default value of this parameter" /></td></tr>'
			$('#additional_param').append(app_str);
		}
	}
	if(act == '0') // delete one parameter
	{
		if(param_real_num == 0)
		{
			alert("sorry, there are no any parameter can be deleted");
			return;
		}
		var param_del = document.getElementsByName("param_checked");
		
		var checked = 0;
		for(i=0; i<param_num; i++)
		{
			if(param_del[i].checked == true)
			{
				param_real_num--;
				checked++;
				var j = Number(param_del[i].value);
				$('#param_' + j).remove();
			}
		}
		if(checked == 0)
			alert("sorry, you didn't select any parameter, please select the parameter you want to delete first");
	}
}

function addDelOneOption(act, n, m)
{
	if(option_static[n] == 0)
	{
		option_num[n] = m;
		option_real_num[n] = m;
		option_static[n] = 1;
	}
	if(act == 1) // add one option
	{
		if(option_real_num[n] >= 20)
		{
			alert("sorry, you can not define the options more than 20");
			return;
		}
		option_num[n]++;
		option_real_num[n]++;
		var option_str = '<tr id="option_' + n + '_' + option_num[n] + '"><td><input type="checkbox" name="option_checked' + n + '" value="' + option_num[n] + '" title="select and delete it"></td><td>label:</td><td><input type="text" name="option_' + n + '_label[]" title="required: option label" size="8px"></td><td>value:</td><td><input type="text" name="option_' + n + '_value[]" title="required: option value" size="8px"></td></td></tr>';

		$('#option' + n).append(option_str);
	}
	if(act == 0) // delete some option
	{
		if(option_real_num[n] == 0)
		{
			alert("sorry, there are no any option can be deleted");
			return;
		}
		var option_del = document.getElementsByName('option_checked' + n);

		var checked = 0;
		for( var i=0; i<option_num[n]; i++)
		{
			if(option_del[i].checked == true)
			{
				option_real_num[n]--;
				checked++;
				var j = Number(option_del[i].value);
				$('#option_' + n + '_' + j).remove();
			}
		}	
		if(checked == 0)
			alert("sorry, you didn't select any options, please select the option you want to delete first");
	}
}
