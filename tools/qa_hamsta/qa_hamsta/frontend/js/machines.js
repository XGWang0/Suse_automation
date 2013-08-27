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

