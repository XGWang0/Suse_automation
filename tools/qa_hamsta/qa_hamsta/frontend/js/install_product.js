<?php
/* pkacer@suse.com: This file has to be included a php file because it
 * contains some PHP code: require ('<this-file-path>');.
 * That should be fixed in near future.
 */
?>
//<!--
var sled_text = ["desktop-base"];
var sled_gnome = ["<?php echo (str_replace (" ", "\", \"", $config->lists->gnome->default));?>"];
var sled_kde = ["<?php echo (str_replace (" ", "\", \"", $config->lists->kde->default));?>"];
var old_repo_product = "<?php if(isset($_POST["repo_products"])){echo $_POST["repo_products"];}?>";
var old_repo_arch = "<?php if(isset($_POST["repo_archs"])){echo $_POST["repo_archs"];}?>";
var old_addon_product = "<?php if(isset($_POST["addon_products"])){echo $_POST["addon_products"];}?>";
var old_addon_arch = "<?php if(isset($_POST["addon_archs"])){echo $_POST["addon_archs"];}?>";

// addonid & addoncodeid
var addonid = 1
var addoncodeid = 1;
var product_patterns = [];
var all_patterns = [];
var product_type = 'others';
var kexec_manually_selected = false;

// Iterate $data and insert all options to select box $id
function insert_options (id, data, old_selected) {
    $(id).empty();
    $(id).append('<option value=""></option>');
    $.each(data, function(i, item){
	$(id).append('<option value="' + item + '">' + item + '</option>');
    });//each
    $(id).val(old_selected);
    $(id).change();
}

function auto_set_kexec (value) {
    $('#kexecnote').empty ();
    if (! kexec_manually_selected) {
	$('#kexecboot').attr ('checked', false);
    }
    var product_regex = /opensuse-\d+\.\d+/i;
    var matched = value.match (product_regex);
    var parts = [];
    if (matched[0]) {
	parts = matched[0].split (/-/g);
	if (parts.length >= 2 && parts[1] > 12) {
	    $('#kexecboot').attr ('checked', true);
	    $('#kexecnote').append ('You have selected a product that requires'
				    + ' a Kexec because it uses grub2.');
	}
    }
}

/* Insert check boxes to provided patterns. */
function insert_checkboxes (id, data, typicmode, old_selected){
    $(id).empty();
    $.each(data, function(i, item){
        $(id).append('<label class="patterns">'
		     + '<input type="checkbox" name="patterns[]"'
		     + ' onchange="insert_modified_flag()" value="'
		     + item + '" id="pt_' + item + '" />' + item + '</label>');
    });//each
    $(id).val(old_selected);
    $(id).change();
}

/* Just a shortcut to uniformly display the list of patterns has been
 * modified (some of them checked). */
function insert_modified_flag () {
        $("#patterns_modified").text ("* Modified");
}

/* Shortcut to remove the modified notification. */
function remove_modified_flag () {
        $("#patterns_modified").empty();
}

/* Set value of the preset group of selected patterns in the dropdown
 * list. */
function set_preset_type_value (type) {
    $("#typicmode").val(type);
}

/* Get value of the preset group of selected patterns from the
 * dropdown list. */
function get_preset_type_value () {
    return $("#typicmode").val();
}

/* Replace string to_be_replaced in all packages by replace. */
function replace_string_in_packages (packages_list, to_be_replaced, replace) {
    for (i = 0; i < packages_list.length; i++)
        packages_list[i] = packages_list[i].replace(to_be_replaced, replace);
    return packages_list;
}

/* Pre-select some of the patterns according to the value of the
 * preselected type dropdown list. */
function change_patterns () {
    var preset_type = get_preset_type_value ();
    var plist = [];

    switch (preset_type) {
    case "text":
	plist = sled_text;
	break;
    case "gnome":
        plist = sled_gnome;
	break;
    case "kde":
        plist = sled_kde;
	break;
    case "full-distro":
	plist = product_patterns;
	break;
    case "full":
	plist = product_patterns;
	break;
    default:
	// Keep the list unmodified.
    }

    if (product_type != "sled") {
	plist = replace_string_in_packages (plist, "desktop-", "");
    }
    /* Uncheck all patterns. */
    $.each(product_patterns, function(i, item) {
        $("#pt_"+item).attr("checked", false);
    });

    /* Check the required patterns. */
    $.each(plist, function(i, item) {
	$("#pt_"+item).attr("checked", true);
    });

    remove_modified_flag();
}

/** Sets proper available architectures depending on the product
 * type. Expected values for product_type are 'repo' or 'addon'.
 */
function get_archs (product_type) {
    /* Get architecture of the machine. */
    var para = {
        product: $("#" + product_type + "_products").val(),
	capable: "<?php echo $machine->get_architecture_capable(); ?>"
    };

    switch (product_type) {
    case 'repo':
	para['prod_type'] = "distro";
        old_repo_product = para['product'];
        if (old_repo_product.length == 0) {
	    $("#repo_archs").empty();
            $("#available_patterns").empty();
	    return false;
        }
	break;
    case 'addon':
	para['prod_type'] = "addon";
        old_addon_product = para['product'];
        if (old_addon_product.length == 0) {
	    $("#addon_archs").empty();
            $("#addon_pattern_1").empty();
	    return false;
        }
	break;
    default:
	return;
    }

    $.getJSON("html/search_repo.php", para,
              function(data) {
	          insert_options("#" + product_type + "_archs", data, old_repo_arch);
              });

    return false;
}

function get_urls (product_type, arch_type) {
    var para = {
        product: $("#" + product_type + "_products").val(),
        //arch: $("#"  + product_type + "_archs").val()
        arch: arch_type
    };
    var patterns_id = "";
    switch (product_type) {
    case 'repo':
	para['prod_type'] = "distro";
        old_repo_arch = para['arch'];
        patterns_id = "#available_patterns";
        if (old_repo_arch.length == 0) {
	    $("#available_patterns").empty();
	    $("#repo_producturl").empty();
	    return;
        }
	break;
    case 'addon':
	para['prod_type'] = "addon";
        old_addon_arch = para['arch'];
        patterns_id = "#addon_pattern_1";
        if (old_addon_arch.length == 0) {
	    $("#addon_pattern_1").empty();
            $("#addon_producturl").empty();
            return;
        }
	break;
    default:
	return;
    }

    $.getJSON("html/search_repo.php", para,
              function(data) {
                  if (para['arch'] == "") {
	              $("#" + product_type + "_producturl").empty();
                  } else {
                      $("#" + product_type + "_producturl").val(data[0]);
		      $("#" + product_type + "_producturl").change();
                  }
              });
    return false;
}

/**
 * Function takes a list of patterns and adds them to the displayed
 * list of patterns and sets up proper pattern pre-selections
 * depending on the type of the package.
 */
function retrieve_patterns (data, product_name, url, prod_type) {
    var patterns_vals = data.replace(/^\s+|\s+$/g, '').split("\n");
    if (!document.getElementById(product_name)) {
	$('#addon_patterns').append('<div id="' + product_name + '"></div>');
    }
    if (patterns_vals[0] != '' || patterns_vals.length > 1) {
        /* Global variable: array of all distro patterns. */
        if (product_patterns.length == 0) {
            product_patterns = patterns_vals;
        }
	insert_checkboxes('#' + product_name, patterns_vals);
	if (prod_type == 'distro') {
	    if (url.toLowerCase().match("sled")) {
		set_preset_type_value ("gnome");
		product_type = 'sled';
	    } else {
		set_preset_type_value ("text");
		product_type = 'others';
	    }
	    change_patterns (patterns_vals);
	}
	return true;
    } else {
	$('#' + product_name).empty();
	return false;
    }
};

/**
 * Function gets the patterns from the URL contained in the val of the
 * element with pattern_field_id id and adds them to the newly created
 * element with new_element_id.
 *
 * product_field_id ID of he element containing URL with leading '#'.
 * new_element_id ID of the inserted element without leading '#'.
 * prod_type Type of the product (distro or addon).
 */
function get_patterns (product_field_id, new_element_id, prod_type) {
    var prod_url = $(product_field_id).val();
    /* Custom checking if the pattern is OK. Better be replaced by
     * some library. There is plugin for jQuery but it knows only the
     * first format and we need the other as well. Maybe it could be
     * overriden, though. */
    if (prod_url.length == 0) {
	$("#" + new_element_id).empty();
    } else if (/^(https?|s?ftp):\/\/[\w-]+\.[\w\.-]+/i.test(prod_url)) {
	/* Next sybling that has id mininotification. */
	$(product_field_id + " ~ #mininotification").empty();
	/* Retrieve not cached patterns directly from repository. */
	$.get('html/refresh_patterns.php',
	      { product_url : prod_url },
	      function (data) {
		  if (! retrieve_patterns (data, new_element_id,
					   prod_url, prod_type)) {
		      $(product_field_id + " ~ #mininotification")
			  .text("No patterns were retrieved. Check your URL.");
		  }
	      }
	     );
    } else if (/^(nfs|smb):\/\/[\w-]+\.[\w\.-]+/i.test(prod_url)) {
	$(product_field_id + " ~ #mininotification")
	    .text("Can not load patterns for this protocol.");
	$("#" + new_element_id).empty();
    } else {
	$(product_field_id + " ~ #mininotification")
	    .text("To refresh patterns the URL field has to contain correct address.");
	$("#" + new_element_id).empty();
    }
    remove_modified_flag();
}

function remove_repo (addon_number) {
    $('#addon_row_' + addon_number).remove();
    $('#addon_pattern_' + addon_number).remove();
    addonid -= 1;
}

function anotherrepo () {
    addonid += 1;
    var addon_refresh_button_id = "addon_" + addonid + "_refresh_button";
    var addon_url_name = '#addon_url_' + addonid;
    var addon_pattern_name = 'addon_pattern_' + addonid;

    $('#additional_repo').append('<span id="addon_row_' + addonid + '">Add-on #' + addonid
				 + ': <input type="text" name="addon_url[]" id="addon_url_'
				 + addonid + '" size="70" /> <button type="button" onclick="remove_repo('
				 + addonid + ')">'
				 + ' - </button> <span id="mininotification" class="text-red text-small bold">'
				 + '</span><br /></span>');
    $(addon_url_name).change ( function() {
	get_patterns (addon_url_name, addon_pattern_name, 'addon');
    });
}

var anotherrcode = function (){
    addoncodeid += 1;
    $('#additional_rcode').append('Registration Code for add-on repo #'
				  + addoncodeid
				  + ': <input type="text" name="rcode[]" size="20" />'
				  + '<input type="button" onclick="anotherrcode('
				  + addoncodeid +')" value="+" /><br />');
}

var anotherdisk = function (){
    $('#additional_disk').append('<br>Virtual Disk type: <select id="virtdisktypes" name="virtdisktypes[]">'
				 + '<?php foreach ($virtdisktypes as $type) { echo "<option value=\"$type\">$type</option>"; } ?>'
				 + '</select>&nbsp;&nbsp;&nbsp;Virtual Disk size (GB): <input type="text"'
				 + ' id="virtdisksizes" name="virtdisksizes[]" size="4">&nbsp;'
				 + '(put a dot "." for default size)&nbsp;&nbsp;<input type="button"'
				 + ' size="5" onclick="anotherdisk()" value="+">');
}

var showvirtdisk = function () {
    $('#virtdisk').slideToggle("slow");
}

$(document).ready(function() {
    // Setup ajax messaging
    $(document)
	.ajaxStart(function() {
	    $('#message').text("Loading content...");
	}).ajaxStop(function() {
	    $('#message').empty();
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
    $.getJSON("html/search_repo.php", { prod_type : "distro" }, function(data) {
	insert_options("#repo_products", data, old_repo_product);
    });

    $.getJSON("html/search_repo.php", { prod_type : "addon" }, function(data) {
	insert_options("#addon_products", data, old_addon_product);
    });

    /* Register events for specified form parts. */
    $("#repo_products").change( function () {
        if ($("#repo_products").val())
            get_urls ('repo', 'x86_64');
    });

    /*$("#repo_archs").change( function () {
	get_urls ('repo');
    });
    */

    $("#addon_products").change( function () {
	if ($("#addon_products").val())
            get_urls ('addon', 'x86_64');

    });

    /*$("#addon_archs").change( function () {
	get_urls('addon');
    });
    */
    $("#repo_producturl").change ( function () {
	get_patterns ('#repo_producturl', 'available_patterns', 'distro');
	auto_set_kexec ($(this).val ());
    });

    $("#addon_producturl").change ( function () {
	get_patterns ('#addon_producturl', 'addon_pattern_1', 'addon');
    });

    $("#typicmode").change(function () {
	change_patterns ();
    });

    $('#kexecboot').change(function () {
	kexec_manually_selected = $(this).attr ('checked');
    });

    $("input[name='product_arch']").change(function(){
        if ($("input[name='product_arch']:checked").val() == 'i586')
        {
	    get_urls ('repo', 'i386');
        }
        else if ($("input[name='product_arch']:checked").val() == 'x86_64')
        {
	    get_urls ('repo', 'x86_64');
        }
        else
	{}
    });

});
//-->

