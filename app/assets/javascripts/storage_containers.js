// Routines to help manage sample storage locations
// using new storage_types and storage_containers tables

function storage_container_init() {
  logger("storage_container_init()");

  storage_container_populate_dropdowns()
  handle_new_container_checked()

  // handle button to show container grid locations
  // SG 6/15/2019: modify for current container now in text box not select
  $(".select-position-btn button").on("click", function() {
    var container_type = $("select.container-type").val();
    if (container_type == null) {
      var container_type = $("input.container-type").val();
    }

    // check for and handle a new container
    if ($("input#new-container-check").prop("checked")) {
      location_lightbox_init(container_type);
      return;
    }

    // handle existing container
    var container_id = get_storage_container_id();
    if (container_id == null) {
       my_alert("No storage container selected");
       return;
    }
    var url = "/storage_containers/"+container_id+"/positions_used.json";
    location_lightbox_init(container_type, url);
  });

  // see if container select options need init
  // this could happen in create action after an error
  handle_freezer_cont_type();
}

//****************************************************************************************************//
// General controller/method initialization functions
//****************************************************************************************************//
function edit_storage_container_init() {
    logger("edit_storage_container_init()");

    // save and remove the existing or new container fields from the edit form
    var exist_new_fields = $("div.existing-new-container-fields");
    // clear any inherited values from edited sample storage
    exist_new_fields.find(".container-name").val("");
    exist_new_fields.find(".container-notes").val("");
    exist_new_fields.find(".position-in-container input").val("");

    //SG 6/15/2019: Only detach existing-new fields if there is a current container div
    if ($("div.current-container-fields").length > 0 ) {
        var container_type = $("input.container-type").val()
        logger("got container type"+container_type)
        display_position_ui(container_type)
        logger("detaching exist_new_fields");
        window.existing_new_container_fields = exist_new_fields.detach();
    }

    // save state for current position in container
    // used for grid display with a currently existing position
    //var cur_pic = $("div.current-container-fields.position-in-container input").val()
    //SG 8/28/19: input/div identifier above not working => add class to text field, and use format below.
    var cur_pic = $("input.position-in-container").val()
    logger("saving current position in container "+cur_pic)
    window.current_position_in_container = cur_pic;
    window.edit_current_container = true;

    // handle which container radio button in edit form
    $("input[name='which_container']").on("change", function() {
        var which = $("input[name='which_container']:checked").val();
        if (which == "other") {
            // deal with buttons- JP 6/17
            $(".current-button").show()
            $(".change-button").hide()
            $(".new-container-button").show()
            // save the current container form
            window.current_container_fields = $("div.current-container-fields").detach();
            // attach and show the fields for existing or new container
            $("div.existing-new-container").append(window.existing_new_container_fields).show();
            // see if container select options need init
            //handle_freezer_cont_type();  //SG 8/29/19: don't think this is needed here
            window.edit_current_container = false;

        } else if (which == "current") {
            // deal with buttons - JP 6/17
            $(".change-button").show()
            $(".current-button").hide()
            $(".new-container-button").hide()
            window.existing_new_container_fields = $("div.existing-new-container-fields").detach();
            $("div.current-container").append(window.current_container_fields);
            window.edit_current_container = true;

        } else if (which == "new") {
            $(".new-container-button").hide()
            window.edit_current_container = false;

        } else {
            my_alert("Unknown which_container value: "+which);
        }
    });
}

//FUNCTION: storage_containers_new_query_init
//  handle loading only container types for freezer - JP 8/9/2019
function storage_containers_new_query_init() {
  logger('storage_containers_new_query_init')
  var freezer_id = '' 
  $("select#freezer_location_freezer_location_id").on("change", function() {
    freezer_id = $(this).val();
    if (freezer_id == "") { return }
    add_container_type_options_for_freezer(freezer_id);
  });

  // reset valid options if needed (eg using back button after query)
  freezer_id = $("select#freezer_location_freezer_location_id").val();
  if (freezer_id == "") { return }
  add_container_type_options_for_freezer(freezer_id);
}

//****************************************************************************************************//
// New container UI
//****************************************************************************************************//
function handle_new_container_checked() {
    $("input#new-container-check").on("change", function() {
        var container_type = $("select.container-type").val();
        var container = $("select.storage-container");
        var container_name = $(".container-name");
        var container_notes = $(".container-notes");
        var container_button=$("span#new-container-text")

        if ($(this).prop("checked")) {
            // disable existing container select
            container.prop("disabled", true);
            // enable and display new storage container fields
            container_name.prop("disabled", false);
            container_notes.prop("disabled", false);
            container_button.text("Existing Container")
            display_new_fields();
            // clear any prior position in container value
            $(".position-in-container input").val("");
            // display the position ui
            display_position_ui(container_type);
        } else {
            // not a new container, so enable selection of an existing one
            container.prop("disabled", false);
            container_name.prop("disabled", true);
            container_notes.prop("disabled", true);
            // if not a new container and no existing one is selected
            // hide the UI for inputing the position
            if (container.val() == "") {
                hide_position_ui();
            }
            container_button.text("New Container")
            hide_new_fields();
        }
    });
}

//****************************************************************************************************//
// Drop-down lists (storage_container new/edit)
//****************************************************************************************************//
function storage_container_populate_dropdowns() {
// ON_CHANGE: handle freezer selection or de-selection
    $("select.freezer").on("change", function () {
        var freezer = $(this).val();
        logger("got freezer change: " + freezer);
        if (freezer == "") {
            // remove all container options
            remove_container_options();
            return
        }
        // if a container type is also selected fill in the container select options
        var container_type = $("select.container-type").val();
        if (container_type != "") {
            add_container_select_options(freezer, container_type);
            // if a new container, go ahead and show the position UI
            if ($("input#new-container-check").prop("checked")) {
                display_position_ui(container_type);
            }
        }
        // move container types in this freezer to the top of list of options
        // SG 6/15/2019: commenting this out since can end up with duplicate container-types when re-arranging
        arrange_container_types($("select.container-type"), freezer);
    });

// ON CHANGE: handle container type selection or de-selection
    $("select.container-type").on("change", function() {
        var container_type = $(this).val();
        logger("got container type change: "+container_type);
        if (container_type == "") {
            // remove all container options
            remove_container_options();
            return
        }
        // if a freezer is also selected fill in the container select options
        var freezer = $("select.freezer").val();
        if (freezer != "") {
            add_container_select_options(freezer, container_type);
            // if a new container, go ahead and show the position UI
            if ($("input#new-container-check").prop("checked")) {
                display_position_ui(container_type);
            }
        }
    });

// ON CHANGE: handle container selection or de-selection
    $("select.storage-container").on("change", function() {
        var container = $(this).val();
        var container_type = $("select.container-type").val();
        logger("got container change: "+container);
        if (container == "") {  // handle de-select
            if (!$("input#new-container-check").prop("checked")) {
                hide_position_ui();
            }
            return;
        }
        // handle selected
        display_position_ui(container_type);
    });
}

// FUNCTION: handle_freezer_cont_type
//   for edit, the freezer and container type will typically be set
//   if so initialize the Existing Container select dropdown if not already set to a value
function handle_freezer_cont_type() {
    var container = $("select.storage-container");
    if (container.val() != "") { return }
    var container_type = $("select.container-type").val();
    var freezer = $("select.freezer").val();
    if (freezer == "" || container_type == "") { return }
    add_container_select_options(freezer, container_type);
}

// FUNCTION: add_container_select_options
//   construct an array of option elements and append to a select element
//   window.container_data is array of rows comprising containers existing in each freezer and container type:
//     [freezer_location_id, container_type, container_name, container_id, count_of_samples_in_container, nr_rows, nr_cols]
function add_container_select_options(freezer_id, container_type) {
    logger("add_container_select_options freezer: "+freezer_id+" container_type: "+container_type);
    var options = [];
    window.container_data.forEach(function(row) {
        if (freezer_id != row[0] || container_type != row[1]) { return };
        var option = $("<option></option>");
        option.attr("value", row[3]);  // container_id
        var capacity = row[5] * row[6];
        var available = capacity - row[4];
        // handle null dimensions
        if (row[5] == null || row[6] == null) {
            capacity = available = "unknown";
        }
        var text = '"'+row[2]+'"'+' [Capacity: '+capacity+' Available: '+available+']';
        option.text(text);
        options.push(option);
    });

    logger ("add_container_select_options "+options.length+" options")
    var first_option = $("select.storage-container :first-child");
    first_option.nextAll().remove();

    if (options.length == 0) {
        first_option.text("No existing containers for Freezer/Type");
        hide_position_ui();
        return;
    }  //else
    first_option.text("Select("+options.length+")..");
    first_option.after(options);
}

// FUNCTION: remove_container_options
//   remove all storage containers from drop-down list
function remove_container_options() {
    var select_text = "Select Freezer/Type first";
    $("select.storage-container :first-child").text(select_text).nextAll().remove();
}

// FUNCTION: arrange_container_types
//   re-arrange the container type options so ones in the selected freezer are displayed first
//   the select param is a jquery object of the select element to adjust
function arrange_container_types(select, freezer_id) {
    var priority_types = freezer_container_types(window.container_type_freezer, freezer_id);
    var options = select.find("option");
    var priority_options = [];

    options.each(function() {
        var option = $(this);
        if (priority_types.includes(option.attr("value"))) {
            // save priority option and remove from existing place in dom
            priority_options.push(option);
            option.remove();
        }
    });
    // insert priority type options after the first option (which is blank)
    var first_option = select.find(":first-child");
    first_option.after(priority_options);
}

//****************************************************************************************************//
// Drop-down lists (storage_container query)
//****************************************************************************************************//
function add_container_type_options_for_freezer(freezer_id) {
    logger("add_container_type_options_for_freezer "+freezer_id);

    var options = []
    $.each(window.container_type_freezer, function( index, value ) {
        if (value.includes(Number(freezer_id))) {
            var option=$('<option value="'+value[0]+'">'+value[0]+'</option>')
            options.push(option)
        }
    });
    logger("Have "+options.length+" container_type options")

    var first_option = $("select#storage_type_container_type :first-child");
    first_option.nextAll().remove();

    if (options.length == 0) {
        first_option.text("No existing containers for Room/Freezer");
        return;
    }   // else
    first_option.text("Select..");
    first_option.after(options);
}

//****************************************************************************************************//
// Lightbox storage container grid handling
//****************************************************************************************************//
function lightbox_selector() {
    // featherligth-inner class needed for nested lightboxes
    return ".location-lightbox.featherlight-inner .lightbox-body";
}

// launch the light box and call ajax to get position data
// if a url is supplied
function location_lightbox_init(container_type, url) {
    logger("location_lightbox_init("+url+","+container_type+")");
    var lb = $(".location-lightbox");

    // launch the lightbox
    $.featherlight(lb, {
        afterOpen: function(evt) {
            var context = $(lightbox_selector()).get(0)
            if (url == undefined) {
                var grid = build_grid(container_type, []);
                $(context).empty().append(grid);
                grid_init();
            } else {
                get_positions_build_grid(url, container_type, context);
            }
        }
    });
}

function get_positions_build_grid(url, container_type, context) {
    $.ajax(url, {context: context

    }).done(function(data, textStatus, jqXHR) {
        logger("got ajax data: "+ data);
        var json = JSON.parse(data);
        if (json.positions_used == undefined) {
            my_alert("Location data returned does not have a positions_used property");
            return
        }
        var grid = build_grid(container_type, json.positions_used);
        $(this).empty().append(grid);
        grid_init();

    }).fail(function(jqXHR, textStatus, errorThrown) {
        set_header_flash_messages(jqXHR, flash_selector());
        my_alert("Request for "+ url +" failed: "+ textStatus +" responseText: "+ jqXHR.responseText);
    });
}

// build a table with positions used data filled in and with available cells clickable
function build_grid(container_type, positions_used) {
    logger("build_grid("+container_type+","+positions_used+")");
    var row, display_format, nr_rows, nr_cols, first_row, first_col;

    row = get_container_dimensions(container_type);
    display_format = row[1];
    nr_rows = row[2]; nr_cols = row[3];
    first_row = row[4]; first_col = row[5];
    logger("display_format: "+display_format+" nr_rows: "+nr_rows+" nr_cols: "+nr_cols+" first_row: "+first_row+" first_col: "+first_col);

    var table = $("<table/>");
    table.addClass("grid-locations table table-bordered table-sm");
    if (nr_rows > 16 || nr_cols > 16) {
        table.addClass("table-font-sm");
    }
    var tr, td;
    // add an extra row and column to show the index labels on top and left
    for (i = 0; i < nr_rows + 1; i++) {
        tr = $("<tr/>");
        if (i == 0) {  // build the top row of column labels
            for (j = 0; j < nr_cols + 1; j++) {
                if (j == 0) {
                    td = $("<td/>");
                } else {
                    td = $("<td/>").text(char_at(first_col, j-1));
                }
                td.appendTo(tr);
            }
        } else {  // build the content rows
            var row_label = char_at(first_row, i-1);
            for (j = 0; j < nr_cols + 1; j++) {
                if (j == 0) {  // build left row label
                    td = $("<td/>").text(row_label);
                } else {  // build content td
                    var col_label = char_at(first_col, j-1)
                    var row_col = row_label + col_label;

                    if (display_format == "2D") {
                        var col_row = col_label + row_label;
                    } else {
                        var col_row = char_at((i-1)*nr_rows, j);
                    }

                    if (positions_used.includes(col_row)) {
                        // check if we are editing a current position,
                        // and if the value matches this cell, set it and don't show as filled
                        if (window.edit_current_container == true &&
                            window.current_position_in_container == col_row) {
                            td = build_clickable_td(col_row);
                            td.text(col_row);
                            table.data("selected_position", col_row);
                            table.data("selected_td", td);
                        } else {
                            // uncomment the following line if you want greyed out coordinates
                            //td = $("<td/>").text(col_row);
                            td = $("<td/>").addClass("filled");
                        }
                    } else {
                        td = build_clickable_td(col_row);
                    }
                }
                td.appendTo(tr);
            }
        }
        tr.appendTo(table);
    }
    logger("build_grid returns: "+table.html());
    return table;
}

function build_clickable_td(row_col) {
    var td = $("<td/>").attr("data-row-col", row_col);
    td.attr("data-toggle", "tooltip");
    td.attr("title", row_col);
    return td;
}

// given a character as a string, return the character n characters away sequentially as a string
function char_at(char_string, n) {
    var num = +char_string;  // converts to number if a number
    if (isNaN(num)) {
        // this only works for n < 26
        return String.fromCharCode(char_string.charCodeAt(0) + n)
    } else {
        return (num + n).toString();
    }
}

// bind click handlers for grid
function grid_init() {
    logger("grid_init()");
    var table = $("table.grid-locations");

    // click on grid cell
    table.on("click", "td[data-row-col]", function() {
        if ($(this).hasClass("filled")) {
            return;
        }
        var row_col = $(this).attr("data-row-col");
        // remove text from any last selection
        var last_td = table.data("selected_td");
        if (last_td) {
            last_td.text("");
        }
        // save the selection and set the text for this cell
        table.data("selected_position", row_col);
        table.data("selected_td", $(this));
        $(this).text(row_col);
    });

    // on done set the position selected in the grid into the input field
    // hide the show grid button, show the input and close the loghtbox
    $(".location-lightbox.featherlight-inner .done-button").on("click", function() {
        var position = table.data("selected_position");
        $(".position-in-container input").val(position);
//    $(".select-position-btn").hide();
        $(".position-in-container").show();
        $.featherlight.current().close();
    });

    // click on cancel
    $(".location-lightbox.featherlight-inner .cancel-button").on("click", function() {
        $.featherlight.current().close();
    });
}

//****************************************************************************************************//
// Data Tables
//****************************************************************************************************//
function storage_containers_index_init() {
    var dt = $("table.data-table").DataTable( {
        iDisplayLength: 50,
        aLengthMenu: [[25, 50, 100, -1], [25, 50, 100, "All"]],
        // Columns with links should not be sortable or searchable
        columnDefs: [ { targets: [ 'action', 'link-col'], sortable: false, searchable: false } ]
    });

    // save the Datatable for later use
    window.datatable = dt;

    // fix for back button, destroy DataTables before caching the page
    document.addEventListener("turbolinks:before-cache", function() {
        if (dt !== null) {
            dt.destroy();
            dt = null;
        }
    });
}

function storage_containers_list_contents_init() {
    var dt = $("table.data-table").DataTable( {
        iDisplayLength: 50,
        aLengthMenu: [[25, 50, 100, -1], [25, 50, 100, "All"]],
        // Columns with links should not be sortable or searchable
        columnDefs: [ { targets: [ 'action', 'link-col'], sortable: false, searchable: false } ]
    });

    // save the Datatable for later use
    window.datatable = dt;

    // fix for back button, destroy DataTables before caching the page
    document.addEventListener("turbolinks:before-cache", function() {
        if (dt !== null) {
            dt.destroy();
            dt = null;
        }
    });
}

//****************************************************************************************************//
// General helper functions
//****************************************************************************************************//
// call the appropriate init function(s) after checking the presence of template sections
// useful after loading template with ajax calls
function ajax_storage_container_init() {
  if ($("div.existing-new-container-fields").length > 0 ) {
    storage_container_init();
  }
  if ($("div.current-container-fields").length > 0 ) {
    edit_storage_container_init();
  }
}

// given type_data which is a map (2-D array) from container_type to freezer_id
// return all types with the given freezer_id
function freezer_container_types(type_data, freezer_id) {
    var types = [];
    // collect the container types in this freezer
    type_data.forEach(function(row) {
        if (row[1] != freezer_id) { return };
        types.push(row[0]);  //container type
    });
    return types;
}

function get_storage_container_id() {
  // for edit this is in a hidden input
  var container_id = $("input.storage-container-id").val();
  if (container_id != undefined) {
    if (container_id == "") {
      my_alert("No storage container id provided");
      return null;
    }
    return container_id;
  }
  // for new samples
  container_id = $("select.storage-container").val();
  if (container_id != "") {
     return container_id;
  }
  my_alert("No storage container selected or id provided");
  return null;
}

// display the appropriate UI for the container display format
// a position in container text input and if appropriate a button to fetch the grid locations already filled
function display_position_ui(container_type) {
    // get the dimensions for this container type
    var dimensions = get_container_dimensions(container_type);
    if (dimensions == undefined) {
        logger("display_position_ui: container dimensions undefined!");
        return;
    }
    var display_format = dimensions[1];

    if (display_format == "2D" || display_format == "2Dseq") {
        // we have a 2-d grid
//    $(".position-in-container").hide();
        $(".position-in-container").show();
        $(".select-position-btn").show();
    } else {
        $(".select-position-btn").hide();
        $(".position-in-container").show();
    }
}

// given a container type, return the container dimension information in an array
function get_container_dimensions(container_type) {
logger("get_container_dimensions("+container_type+")");
  var dimensions;
  window.container_dimensions.forEach(function(row) {
    if (row[0] == container_type) {
      dimensions = row;
      return;
    }
  });
  return dimensions;
}

function hide_position_ui() {
  $(".position-in-container").hide();
  $(".select-position-btn").hide();
}

function display_new_fields() {
  $(".existing-container").hide();
  $(".new-fields").show();
  which = 'new';
}

function hide_new_fields() {
  $(".new-fields").hide();
  $(".existing-container").show();
  which = 'other';
}

function flash_selector() {
  return ".flash-box";
}
