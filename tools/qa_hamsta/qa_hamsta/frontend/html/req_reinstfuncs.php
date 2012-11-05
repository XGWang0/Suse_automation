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
?>

<script>
var sled_text = ["desktop-base"];
var sled_gnome = ["<?php echo (str_replace (" ", "\", \"", $config->lists->gnome->default));?>"];
var sled_kde = ["<?php echo (str_replace (" ", "\", \"", $config->lists->kde->default));?>"];
var old_repo_product = "<?php if(isset($_POST["repo_products"])){echo $_POST["repo_products"];}?>";
var old_repo_arch = "<?php if(isset($_POST["repo_archs"])){echo $_POST["repo_archs"];}?>";
var old_sdk_product = "<?php if(isset($_POST["sdk_products"])){echo $_POST["sdk_products"];}?>";
var old_sdk_arch = "<?php if(isset($_POST["sdk_archs"])){echo $_POST["sdk_archs"];}?>";

// sdkid & sdkrcodeid
var sdkid = 1
var sdkrcodeid = 1;

// Iterate $data and insert all options to select box $id
var insert_options = function (id, data, old_selected){
	$(id).empty();
	$(id).append('<option value=""></option>');
	$.each(data, function(i, item){
		$(id).append('<option value="' + item + '">' + item + '</option>');
	});//each
	$(id).val(old_selected);
	$(id).change();
}

var insert_checkboxes = function (id, data, typicmode, old_selected){
    $(id).empty();
    $.each(data, function(i, item){
        $(id).append('<label style="display: block; width: 200; float: left;"><input type="checkbox" name="patterns[]" onchange="insert_modified_flag()" value=' + item + ' id=pt_' + item + ' />' + item + '</label>');
    });//each
    $(id).val(old_selected);
    $(id).change();
}

var insert_modified_flag = function() {
        modified = document.getElementById('patterns_modified');
        modified.innerHTML = '* Modified';
}

var remove_modified_flag = function() {
        modified = document.getElementById('patterns_modified');
        modified.innerHTML = '';
}

var changepattern = function() {
    if ($("#typicmode").attr("value") == "text")
        plist = sled_text;
    else if ($("#typicmode").attr("value") == "gnome")
        plist = sled_gnome
    else if ($("#typicmode").attr("value") == "kde")
        plist = sled_kde
    if (producttype != "sled")
        for (i=0;i<plist.length;i++)
            plist[i] = plist[i].replace("desktop-", "");
    if ($("#typicmode").attr("value") == "full")
	    plist = fullpatternlist;
    $.each(fullpatternlist, function(i, item){
        $("#pt_"+item).attr("checked", false);
    }) 
    $.each(plist, function(i, item){
	    $("#pt_"+item).attr("checked", true);
    })
    remove_modified_flag();
}

var get_repo_archs = function() {
	old_repo_product =  $("#repo_products option:selected").text();
	var para= { product: $("#repo_products option:selected").text(),
		capable: "<?php echo $machine->get_architecture_capable(); ?>"};
	$.getJSON("html/search_repo.php", para, function(data){
		if ($("#repo_products").attr("value") != "") {
			insert_options("#repo_archs", data, old_repo_arch);
		}
	});
	return false;
};

var get_sdk_archs = function() {
    old_sdk_product =  $("#sdk_products option:selected").text();
    var para= { product: $("#sdk_products option:selected").text(),
        capable: "<?php echo $machine->get_architecture_capable(); ?>"};
    $.getJSON("html/search_sdk.php", para, function(data){
        if ($("#sdk_products").attr("value") != "") {
            insert_options("#sdk_archs", data, old_sdk_arch);
        }
    });
    return false;
};

var get_repo_urls = function (){
    old_repo_arch = $("#repo_archs option:selected").text();
    var para= {
        product: $("#repo_products option:selected").text(), 
        arch: $("#repo_archs option:selected").text()
    };
    $.getJSON("html/search_repo.php", para, function(data) {
        if (para['arch'] == "") {
            $("#repo_producturl").attr("value", "");
        } else {
            $("#repo_producturl").attr("value", data[0]);
	    if (typeof fullpatternlist == 'undefined') {
		    fullpatternlist = data[1];
	    } else {
		    fullpatternlist = fullpatternlist.concat(data[1]);
	    }
            insert_checkboxes("#available_patterns", fullpatternlist);
            if (data[0].toLowerCase().match("sled")) {
                $("#typicmode").attr("value", "gnome");
                producttype = 'sled';
            } else {
                $("#typicmode").attr("value", "text");
                producttype = 'others';
            }
            changepattern();
        }
    });
    return false;
};

var get_sdk_urls = function (){
    old_sdk_arch =  $("#sdk_archs option:selected").text();
    var para= { product: $("#sdk_products option:selected").text(), 
        arch: $("#sdk_archs option:selected").text()};
    $.getJSON("html/search_sdk.php", para, function(data){
        if (para['arch'] == "")
            $("#sdk_producturl").attr("value", "");
        else {
            $("#sdk_producturl").attr("value", data[0]);
            insert_checkboxes("#sdk_pattern_1", data[1]);
        }
    });
    return false;
};

var anotherrepo = function (){
    sdkid += 1;
    $('#additional_repo').append('SDK #'+ sdkid  +': <input type="text" name="addon_url[]" id="addon_url_' + sdkid +'" size="70" /> &emsp;<button type="button" onclick="anotherrepo()"> + </button><br />');
    var sdk_pattern_name = 'sdk_pattern_' + sdkid;
    var addon_url_name = '#addon_url_' + sdkid;
    $(addon_url_name).blur(function() {
	    var url = $(addon_url_name).val();
	    $.get("html/refresh_patterns.php", { product_url: url }, function(data) { retrieve_patterns(data, sdk_pattern_name, url); });
    });
}

var anotherrcode = function (){
    sdkrcodeid += 1;
    $('#additional_rcode').append('Registration Code for SDK repo #' + sdkrcodeid  + ': <input type="text" name="rcode[]" size="20" /><input type="button" onclick="anotherrcode('+ sdkrcodeid +')" value="+" /><br />');
}

var anotherdisk = function (){
    $('#additional_disk').append('<br>Virtual Disk type: <select id="virtdisktypes" name="virtdisktypes[]"><?php foreach ($virtdisktypes as $type) { echo "<option value=\"$type\">$type</option>"; } ?></select>&nbsp;&nbsp;&nbsp;Virtual Disk size (GB): <input type="text" id="virtdisksizes" name="virtdisksizes[]" size="4">&nbsp;(put a dot "." for default size)&nbsp;&nbsp;<input type="button" size="5" onclick="anotherdisk()" value="+">');
}

var showvirtdisk = function () {
    $('#virtdisk').slideToggle("slow");
}

$("#repo_products").change(get_repo_archs);
$("#repo_archs").change(get_repo_urls);
$("#sdk_products").change(get_sdk_archs);
$("#sdk_archs").change(get_sdk_urls);


$(document).ready(function(){
	// Setup ajax messaging
	$('#message')
	    .ajaxStart(function() {
	      $(this).text("Loading...");
	    }).ajaxStop(function() {
	      $(this).empty();
	    });

	// Reinstall with updates options
	$('#startupdate')
		.change(function() {
			var updateVal = $('#startupdate').val();
			if(updateVal == 'update-smt') {
				$('#updateoptions-smt').slideDown();
				$('#updateoptions-reg').hide();
			} else if(updateVal == 'update-reg') {
				$('#updateoptions-smt').hide();
				$('#updateoptions-reg').slideDown();
			} else {
				$('#updateoptions-smt').hide();
				$('#updateoptions-reg').hide();
			}
		});

	// For dropdown lists, load products
	$.getJSON("html/search_repo.php", function(data){
		insert_options("#repo_products", data, old_repo_product);
	});
    $.getJSON("html/search_sdk.php", function(data){
        insert_options("#sdk_products", data, old_sdk_product);
    });
});

var retrieve_patterns = function (data, sdk_name, url) {
	var patterns_vals = data.replace(/^\s+|\s+$/g, '').split("\n");
	if (!document.getElementById(sdk_name)) {
		$('#sdk_patterns').append('<div id="' + sdk_name + '"></div>');
	}
	if (patterns_vals[0] != '' || patterns_vals.length > 1) {
		insert_checkboxes('#' + sdk_name, patterns_vals);
		if (typeof fullpatternlist == 'undefined') {
			fullpatternlist = patterns_vals;
		} else {
			fullpatternlist = fullpatternlist.concat(patterns_vals);
		}
		if (url.toLowerCase().match("sled")) {
			$("#typicmode").attr("value", "gnome");
			producttype = 'sled';
		} else {
			$("#typicmode").attr("value", "text");
			producttype = 'others';
		}
		changepattern();
	} else {
		$('#' + sdk_name).empty();
	}
};
</script>
