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
	var tbl = document.getElementById(table);
	var rows = tbl.getElementsByTagName('tr');
	for( var row=1; row<rows.length; row++ ) {
		var cells = rows[row].getElementsByTagName('td');
		var l = cells[1].innerHTML;
		var show_l = document.getElementById('filter_'+l).checked;
		var show_p = true;
		if( processes )	{
			var p = (cells[2].innerHTML ? cells[2].innerHTML : '(none)' );
			var show_p = document.getElementById('filter_'+p).checked;
		}
		rows[row].style.display=(show_l&&show_p ? 'table-row' : 'none');
	}
}
