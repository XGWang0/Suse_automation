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

function filter_init(table,filterdiv,processes)
{
	var tbl = document.getElementById(table);
	var rows = tbl.getElementsByTagName('tr');
	var lvl = [];
	var ps = [];
	for( var row=1; row<rows.length; row++ ) {
		var cells = rows[row].getElementsByTagName('td');
		var l = cells[1].innerHTML;
		lvl[l] = (lvl[l] ? lvl[l]+1 : 1);
		if( processes )	{
			var p = (cells[2].innerHTML ? cells[2].innerHTML : '(none)');
			ps[p] = (ps[p] ? ps[p]+1 : 1);
		}
	}
	var h = "";
	h+="Type : \n";
	for( var i in lvl) {
		h+='<span class="'+i+'"><input type="checkbox" id="filter_'+i+'" checked="checked" onclick="filter_refresh('+"'"+table+"',"+processes+')"/><label for="filter_'+i+'">'+i+"</label></span>\n";
	}
	if( processes )	{
		h+="<br/>\nProcesses : \n";
		for( var p in ps) {
			h+='<input type="checkbox" id="filter_'+p+'" checked="checked" onclick="filter_refresh('+"'"+table+"',"+processes+')"/><label for="filter_'+p+'">'+p+"</label>\n";
		}
	}
	h+="<br/>\n";
	var filter_div = document.getElementById(filterdiv);
	filter_div.innerHTML = h;
	filter_refresh(table);
}

function filter_refresh(table,processes)
{
	var filter_id=table.substr(7);
	filter_id="#log_filter"+filter_id;
	var tbl = document.getElementById(table);
	var rows = tbl.getElementsByTagName('tr');
	for( var row=1; row<rows.length; row++ ) {
		var cells = rows[row].getElementsByTagName('td');
		var l = cells[1].innerHTML;
		var show_l = $(filter_id).find('input#filter_'+ l)[0].checked ;
		var show_p = true;
		if( processes )	{
			var p = (cells[2].innerHTML ? cells[2].innerHTML : '(none)' );
			var show_p = document.getElementById('filter_'+p).checked;
		}
		rows[row].style.display=(show_l&&show_p ? 'table-row' : 'none');
	}
}
