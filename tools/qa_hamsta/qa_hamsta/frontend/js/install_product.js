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

// Iterate $data and insert all options to select box $id
function insert_options (id, data, old_selected) {
    $(id).empty();
    $(id).append('<option value=""></option>');
    $.each(data, function(i, item) {
	$(id).append('<option value="' + item + '">' + item + '</option>');
    });//each
    $(id).val(old_selected);
    $(id).change();
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
        capable: "<?php echo ((isset ($machine) ? $machine->get_architecture_capable() : '')); ?>"
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

function get_urls (product_type, arch_type, addon_products_id, addon_products_url_id) {

    var para = {
        product: $("#" + product_type + "_products").val(),
        //arch: $("#"  + product_type + "_archs").val()
        arch: arch_type
    };

    if (addon_products_id) {
        para.product = $("#" + addon_products_id).val();
    }

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
                      if (addon_products_url_id) {
                          $("#" + addon_products_url_id).val(data[0]);
                          $("#" + addon_products_url_id).change();
                      } else {
			  if ($("#" + product_type + "_producturl").length) {
                              $("#" + product_type + "_producturl").val(data[0]);
                              $("#" + product_type + "_producturl").change();
			  } else {
			      /* AutoPXE page */
			      $("#" + product_type + "url").val(data[0]);
                              $("#" + product_type + "url").change();
			  }
                      }
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

function guessProductCode(url) {
    if (!url)
        return;
    
    var slesPtn = new RegExp('sles', 'i');
    var sledPtn = new RegExp('sled', 'i');
    if (slesPtn.test(url)) 
    {
    $('#regprefix_prod').val('sles');
    }
    else if (sledPtn.test(url))
    {
    $('#regprefix_prod').val('sled');
    }
}

function removeMachine(id, node) {

    if (!id)
        return;
    var machines = $(".machine_name");
    if (machines.length == 1)
    {
        return;
    }

    $(node).parent().remove();
    $("input[name='a_machines[]']").each(function(index, m){
        if (m.value == id)
        {
            $(m).remove();
        }
    });
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
        $("select[name*='addon_products']").each(function(index, value){
       insert_options($(this), data, old_addon_product);
        });
    });
    
    /*Register events for select addon products*/ 
    $("select[name*='addon_products']").each(function(index, value){
            var addon_id = index +1;
            var addon_products_id      =  "addon_products_" + addon_id;
            var addon_products_url_id  =  "addon_products_url_"+ addon_id;
            var addon_arch_name = 'addon' + addon_id + 'arch';
            $(this).bind('change', {id: "addon_products_"+addon_id}, function () {
                if ($(this).val())
                {
                    var arch = $(this).val();
                    var arch = $("input:radio[name="+ addon_arch_name +"]:checked").val();
                    if (/x86_64/.test(arch))
                        get_urls ('addon', 'x86_64', addon_products_id, addon_products_url_id);
                    else if (/i[1-9]86/.test(arch))
                        get_urls ('addon', 'i586', addon_products_id, addon_products_url_id);
                    else
                        get_urls ('addon', 'x86_64', addon_products_id, addon_products_url_id);
                }
             });

            $("input[name=addon"+addon_id+"arch]").bind('change', {id: "addon_products_url_"+addon_id}, function () {
                if ($(this).val())
                {
                    var arch = $(this).val();
                    if (/x86_64/.test(arch))
                        get_urls ('addon', 'x86_64', addon_products_id, addon_products_url_id);
                    else if (/i[1-9]86/.test(arch))
                        get_urls ('addon', 'i586', addon_products_id, addon_products_url_id);
                    else
                        get_urls ('addon', 'x86_64', addon_products_id, addon_products_url_id);
                }
                });
            });

    /* Register events for pattens change */
    $("input[id*='addon_products_url']").each(function(index, value){
        var addon_id = index + 1;
        var addon_pattern_name = 'addon_pattern_' + addon_id;
    $(this).bind('change', {id: "addon_products_url_"+addon_id}, function () {
           get_patterns ("#addon_products_url_"+addon_id  , addon_pattern_name, 'addon');
        });
    });

    /* Register events for specified form parts. */
    $("#repo_products").change( function () {
        if ($("#repo_products").val()) {
            var arch = $("input[name='product_arch']:checked").val();
            if (arch) {
		if (arch == 'i586') {
                    get_urls ('repo', 'i386');
		} else {
                    get_urls ('repo', arch);
		}
	    } else {
		/* This is for the AutoPXE page. */
		get_archs ('repo');
	    }
        }
    });

    $("#repo_producturl").change ( function () {
    get_patterns ('#repo_producturl', 'available_patterns', 'distro');
    guessProductCode($(this).val());
    });

    $("#addon_producturl").change ( function () {
    get_patterns ('#addon_producturl', 'addon_pattern_1', 'addon');
    });

    $("#typicmode").change(function () {
    change_patterns ();
    });

    $('#repo_archs').change(function () {
	get_urls ('repo', $(this).val());
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
    
    $("input:radio").on("change", function(){
        var item = $(this).val();
        switch (item){
            case "update-none": 
            case "update-opensuse": 
            case "update-smt": 
                $('#update-reg-email').attr('required', false);
                $('#rcode_product').attr('required', false);
                break;
            case "update-reg": 
                $('#update-reg-email').attr('required', true);
                $('#rcode_product').attr('required', true);

                break;
            default:
                break;
        }
    });

});
//-->
