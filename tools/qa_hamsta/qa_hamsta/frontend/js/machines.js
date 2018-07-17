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
function tableAlign(){
    var scrollTop = $(window).scrollTop();
    var scrollLeft = $(window).scrollLeft();
    var machinesLeft = parseInt($("#machines").css("margin-left").replace(/px/,""))+parseInt($("#content").css("padding-left").replace(/px/,""));
    if (scrollTop > hoverThreshold)
    {
        $('#filter').addClass("float");
	$("#blindwall").removeClass("hidden");
	if (isChrome) {
		$("#blindwall").addClass("show ChromeHeight");
	} else {
		$("#blindwall").addClass("show otherHeight");
        }
	$("#machines thead").removeClass("plain").addClass("float").css("top",$("#blindwall").height()); 
        $("#machines thead").css("left",machinesLeft - scrollLeft + "px");
	if ( originWidth + machinesLeft + browserWidthBorder > $("body").width() )
		$("body").width(originWidth + machinesLeft + browserWidthBorder);
	if ( $("#machines tbody").width() > $("#machines thead").width() )
               $("#machines thead").width($("#machines tbody").width());
        else
               $("#machines tbody").width($("#machines thead").width());
	$("#machines tr:first-child td").each(function(index) {
            var ind = index + 1;
            if ( $(this).width() > $("#machines th:nth-child("+ind+")").width() )
               	$("#machines th:nth-child("+ind+")").width($(this).width());
            else
                $(this).width($("#machines th:nth-child("+ind+")").width());
        });
    }
    else
    {
    	$("body").width(($(window).width() + browserWidthBorder > screenRes)?$(window).width():(screenRes - browserWidthBorder));
	$('#filter').removeClass("float");
	$("#machines thead").removeClass("float").addClass("plain");
        $("#blindwall").addClass("hidden").removeClass("show otherHeight ChromeHeight");
    }
}
function extToggle(chkbox) {
        $("table#extlist").fadeToggle("fast");
        if( chkbox.checked == false )
                $("label#lblmore").html('&nbsp&nbsp&nbsp&dArr; '+(sutCnt-2).toString()+' more &uArr;');
        else
                $("label#lblmore").html("&nbsp&nbsp&nbsp&dArr; Hide more &uArr;");
}
function catSpace(Num) {
	var mystr = "";
	for(var i = 0; i < Num; i++ ) 
		mystr += "&nbsp";
	return mystr;
}
function appendToList(id) { 
        sutList['"'+id+'"'] = '<input type="checkbox" checked="checked" onChange=\'attachToTab(this,"'+id+'")\'>';
			sutList['"'+id+'"'] += '<label title='+machines[id]+'>';
			sutList['"'+id+'"'] += machines[id].substr(0,13);
			if( machines[id].length < 13 )
				sutList['"'+id+'"'] += catSpace(13-machines[id].length);
			sutList['"'+id+'"'] +='</label>';
}
function renderHtml(visual) {
        var outHtml = "&nbsp";
	if(sutCnt <= 0) {
                $("div#chkedsut").text("");
        } else {
                $("div#chkedsut").text(sutCnt);
                if(sutCnt <= 3) {
                        for(var ind in sutList) {
                                if( sutList[ind] != null ) {
                                        outHtml += sutList[ind];
                                }
                        }
                } else {
                        var attached = 0;
                        for(var ind in sutList) {
                                if( sutList[ind] != null ) {
                                        if(attached < 2) {
                                                outHtml += sutList[ind];
                                                attached ++;
                                        }
                                        if(attached == 2) {
                                                if( visual == "table" )
                                                        lbTxt = "Hide";
                                                else
                                                        lbTxt = (sutCnt-attached).toString();
                                                outHtml += '<input type="checkbox" id="showmore" onChange=\'extToggle(this)\' ';
                                                if( visual == "table" )
                                                        outHtml += 'checked="checked" ';
                                                outHtml += '><label for="showmore" id="lblmore">&nbsp&nbsp&nbsp&dArr; '+lbTxt+' more &uArr;</label>';
                                                outHtml += '<table id="extlist" style="display:'+visual+'">';
                                                attached ++;
                                                continue;
                                        }
                                        if(attached > 2) {
                                                attached ++;
                                                if( attached % 3 == 1)
                                                        outHtml += '<tr>';
                                                outHtml += '<td>'+sutList[ind]+'</td>';
                                                if( attached % 3 == 0 || attached == sutCnt + 1)
                                                        outHtml += '</tr>';
                                        }
                                        if(attached == sutCnt + 1)
                                                outHtml += '</table>';
                                }
                        }

                }
        }
	return outHtml;
}
function attachToTab(chkbox,host_id) {
        var outHtml = "&nbsp";
        var extAttr = "none";
        if( chkbox.id == "checkall" ) {
                if( chkbox.checked == true )
                        sutCnt = 0;
                for( var id in machines ) {
                    if(chkbox.checked == true) {
                        sutCnt ++;
			appendToList(id);
                    } else {
                        sutCnt --;
                        sutList['"'+id+'"'] = null;
                    }
                }
        } else {
                if(chkbox.checked == true) {
                        sutCnt ++;
			appendToList(host_id);
                } else {
                        sutCnt --;
                        sutList['"'+host_id+'"'] = null;
                        $("input[value='"+host_id+"']").attr("checked",false);
                        if(sutCnt == 0)
                                $("input#checkall").attr("checked",false);
                }
                if( $("table#extlist").css("display") == "table" )
                        extAttr = $("table#extlist").css("display");
        }
        $("div#chkedlist").html(renderHtml(extAttr));
}


