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

function checkemail(emailvalue)
{
	var emails=trim(emailvalue)
	emails = emails.toLowerCase();
	emails = emails.replace(/\s*/g,"")

	var filter=/^([a-z0-9._-])+@([a-z0-9_-])+(\.[a-z0-9_-])+/
	var arr_emails=emails.split(",")

	if (emails=="")     return true; //empty email address is valid

	for (i=0; i<arr_emails.length; i++) {
		if (filter.test(arr_emails[i])==false) {
			alert ("Please input a valid email, or leave it blank. \n Invalid email: " + arr_emails[i])
			return false
		}
	}
	return true
}

function checkcheckbox(which){
	var ckpass=false
	if (which.action.options[which.action.selectedIndex].value == "addsut") return true;
	for (i=0;i<which.length;i++) {
                var tempobj=which.elements[i]
                if (tempobj.type=="checkbox" && tempobj.checked) {
			ckpass=true
			break
		}
	}
	if(ckpass==false){
		alert("At least choose one checkbox option.")
		return false;
	}
	return checkemail(which.mailto.value)
}

function chkcompareradios(which) {
	var count=0
	for (i=0; i<which.length;i++) {
		var tempobj=which.elements[i];
		if (tempobj.type=="radio" && tempobj.checked) {
			alert("one radio checked")
			count++;
		}
	}
	if (count==2) {
		return true;
	} else {
		alert("At least choose two radio boxes.\n");
		return false;
	}
}

function checkradio(which)
{
	for(i=0; i<which.length; i++)
	{
		var obj = which.elements[i];
		if( obj.type=="radio" && obj.checked )
			return checkemail(which.mailto.value);
	}
	alert("Choose one radio button");
	return false;
}

function checkcontents(which)
{
	for (i=0;i<which.length;i++) {
		var tempobj=which.elements[i]
		if (tempobj.title.substring(0,8)=="required") {
			if ( (tempobj.type=="text") || (tempobj.type=="textarea") ) {
				if ( (tempobj.name=="jobname") && (tempobj.value.indexOf(" ") >=0) ){
					alert("The job name must be composed by number, letter, underscore or dash")
					return false
				}
				if ((tempobj.value).replace(/(^\s*)|(\s*$)/g, '')=='') {
					alert("Please input required fields of this job section.")
					return false
				}
			}
		}
	}
	return checkemail(which.mailto.value)
}

function checkReinstallDropdownArchitectures()
{
	var repoArch = document.getElementById('repo_archs').options[document.getElementById('repo_archs').selectedIndex].value;
	var sdkArch = document.getElementById('sdk_archs').options[document.getElementById('sdk_archs').selectedIndex].value;
	if(repoArch == '' || sdkArch == '' || repoArch == sdkArch || (repoArch == 'i386' && sdkArch == 'i586') || (repoArch == 'i586' && sdkArch == 'i386')) {
		document.getElementById('repo_archs_warning').innerHTML = '';
		document.getElementById('sdk_archs_warning').innerHTML = '';
	} else {
		document.getElementById('repo_archs_warning').innerHTML = 'Warning';
		document.getElementById('sdk_archs_warning').innerHTML = 'Architectures differ';
	}
}

function chkall(input1,input2)
{
    var objForm = document.forms[input1];
    var objLen = objForm.length;
    for (var iCount = 0; iCount < objLen; iCount++) {
        if (input2.checked == true) {
            if (objForm.elements[iCount].type == "checkbox") {

                objForm.elements[iCount].checked = true;
            }
        } else {
            if (objForm.elements[iCount].type == "checkbox") {
                objForm.elements[iCount].checked = false;
            }
        }
    }
}

function MM_swapImgRestore() 
{ 
	var i,x,a=document.MM_sr; 
	for(i=0;a&&i<a.length&&(x=a[i])&&x.oSrc;i++) 
		x.src=x.oSrc;
}

function MM_preloadImages() 
{
	var d=document; 
	if(d.images){ 
		if(!d.MM_p) d.MM_p=new Array();
		var i,j=d.MM_p.length,a=MM_preloadImages.arguments; 
		for(i=0; i<a.length; i++)
			if (a[i].indexOf("#")!=0) { 
				d.MM_p[j]=new Image; 
				d.MM_p[j++].src=a[i];
			}
	}
}

function MM_findObj(n,d) 
{
	var p,i,x;  
	if(!d) d=document; 
	if((p=n.indexOf("?"))>0&&parent.frames.length) {
		d=parent.frames[n.substring(p+1)].document; 
		n=n.substring(0,p);
	}
	if(!(x=d[n])&&d.all) x=d.all[n]; 
	for (i=0;!x&&i<d.forms.length;i++) x=d.forms[i][n];
	for(i=0;!x&&d.layers&&i<d.layers.length;i++) x=MM_findObj(n,d.layers[i].document);
	if(!x && d.getElementById) x=d.getElementById(n); 
	return x;
}

function MM_swapImage() 
{
	var i,j=0,x,a=MM_swapImage.arguments; 
	document.MM_sr=new Array; 
	for(i=0;i<(a.length-2);i+=3)
		if ((x=MM_findObj(a[i]))!=null) {
			document.MM_sr[j++]=x; 
			if(!x.oSrc) x.oSrc=x.src;
			x.src=a[i+2];
		}
}

function trim(inputstr)
{
	return inputstr.replace(/(\s*)/g, "");
}

function open_access_window(url)
{
        popupWindow = window.open(url,'popUpWindow','height=700,width=800,left=10,top=10,resizable=yes ,scrollbars=yes,toolbar=no,menubar=no,location=no,directories=no,status=yes')
}

function clear_filebox (objid)
{
	var oldobj = document.getElementById(objid);
	var newobj = document.createElement('input');
	newobj.type = 'file';
	newobj.name = oldobj.name;
	newobj.id = oldobj.id;
	oldobj.parentNode.replaceChild(newobj, oldobj);
}
