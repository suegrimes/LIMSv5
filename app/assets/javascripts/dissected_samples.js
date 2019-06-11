
// standard init functions
// Format: <controller>_init() => controller specific init
//   <controller>_<action>_init() => controller/action specific init

// dissected_samples edit init
function dissected_samples_edit_init() {
    // new storage management init
    storage_container_init();

    // storage containers edit init
    edit_storage_container_init();
}

// dissected_samples edit init
function dissected_samples_new_init() {
    // new storage management init
    storage_container_init();

    // storage containers edit init
    edit_storage_container_init();
}

//--------------------------------------------------------

// dissected_samples add_multi page init function
function dissected_samples_add_multi_init() {
logger("dissected_samples_add_multi_init()");

  // replicate button
  $("#replicate-button").on("click", function(evt) {

    input_elements = $("#default-values").find("input, select, textarea").toArray();
//logger(input_elements);

    // get the number of rows to replicate
    var nr_replicate = $("input#nr_dissections").val();
//logger("nr_replicate: " + nr_replicate);

    // attach the number of rows requested
    for (i = 0; i < nr_replicate; i++) {

      // create an instance of the row html to append
      var table_row = create_table_row(input_elements, "sample");
    
      // increment the barcode suffix and re-assign
      var barcode_input = table_row.find(".barcode");
      var source_barcode = barcode_input.attr("value");
      var next_barcode = $("#sample_next_barcode_key").val();
      barcode_input.attr("value", new_barcode(source_barcode, next_barcode));

      // attach to the grid
      var new_row = table_row.appendTo($("#edit-table"));

      // now that we are attached to the DOM we can change any
      // values required and trigger the change

      // remove the position_in_container value from the row
      new_row.find("#sample_sample_storage_container_attributes_position_in_container").val("").trigger("change");
      
      // copy the selected values from the form and trigger a change event
      copy_selected_values(new_row, "sample", get_row_index());
    }

    // make table visible
    $("#edit-table-container").show();

  });

//function ajax_bind(selector, data, fcn_label, fcn_success, fcn_error, options)
  ajax_bind("form", "save", "Save All Dissections", save_success, save_error, {no_success_alert: true})

  // hijack the submit and detach already saved rows until response
  $("form input[name='commit']").on("click",function() {
    delete_error_rows();
    form_detach_saved();
  });
}

// both complete success and save failures should come here
function save_success(form, evt, data, status, xhr) {
logger("save_success; " + status);
//logger(data);
  // set any flash messages sent in headers
  set_header_flash_messages(xhr)

  var fail_index = 0;
  var rows = $("#edit-table").find("tr.input-row");
  if (!(data.saved_ids === undefined || data.saved_ids.length == 0)) {
    fail_index = data.saved_ids.length;
    handle_saved(data.saved_ids, rows);
  }
  if (!(data.errors === undefined)) {
    handle_error(data.errors, data.last_status, rows, fail_index)
  }
  form_restore_saved(rows.get(0));
}

//fcn_error(this, evt, xhr, status, error)
// other unexpected errors should come here
function save_error(form, evt, xhr, status, error) {
logger("save_error: " + status);
//logger(error);
}

// handle successsfully saved rows in the edit table
// set data-saved on the row and barcode so css can set green
// and disable all other inputs
//
function handle_saved(ids, rows) {
logger("saved_ids: " + ids);
  // find the rows saved, will be the first n input rows in table
  rows.each(function() {
    var row = $(this);
    var id = ids.shift()
    row.addClass("data-saved") .attr("data-id", id)
    row.find("#sample_barcode_key").addClass("bg-success text-white");
    row.find("input, select, textarea").attr("disabled", "disabled");
    if (ids.length == 0) {
      return false;  // break out of each loop
    }
  });
}

// takes an array of error messages, the http status of the failing save
// and the table row index of the failing row
function handle_error(errors, last_status, rows, fail_index) {
logger("errors: " + errors);
logger("last_status: " + last_status);
logger("fail_index: " + fail_index);
  // get failed element
  var failed = rows.get(fail_index);
  var barcode = $(failed).find("#sample_barcode_key").val();
  errors.forEach(function(error) {
    var err_row = $("<tr><td>"+barcode+"</td><td colspan='7'>"+error+"</td></tr>");
    err_row.addClass("error-row");
    err_row.find("td").addClass("text-danger");
    err_row.insertBefore($(failed));
  });
}

function delete_error_rows() {
  $("#edit-table").find("tr.error-row").remove();
}

// detach those rows from the form that have already been saved
// so they don't get sent in this save call
// save them until the response is received
function form_detach_saved() {
  window.saved_rows = $("#edit-table").find("tr.data-saved").detach();
}

// restore saved rows that were detached during a save call
function form_restore_saved(first_row_elem) {
  window.saved_rows.each(function() {
    $(this).insertBefore($(first_row_elem));
  });
  window.saved_rows = null;
}

// given an array of input type dom elements
// return a table row jquery object
function create_table_row(input_elements, model) {
logger("create_table_row")
  var tr = $('<tr>');
  new_row_index();

  // get the ordered grid inputs
  var grid_inputs = get_grid_inputs(input_elements);
  $(grid_inputs).each(function() {
    var name = $(this).attr("name");

    if (name.startsWith(model)) {
      // convert form name to row name
      $(this).attr("name", form_to_row_name(name, model, get_row_index()));

      // create a <td> for each input and append to the row
      tr.append($(this).wrap("<td></td>").parents());
    }
  });

  // get the inputs not in the grid but needed to create the object
  var hidden_inputs = get_hidden_inputs(input_elements);
  $(hidden_inputs).each(function() {
    var input = $(this);
    var name = input.attr("name");

    // ensure a sample attribute that is not an id
    if (name.startsWith("sample") && !(name.endsWith("[id]"))) {
      // convert a select into a regular input
      if (input.prop("nodeName") == "SELECT") {
        var value = input.val();
        // create an html INPUT to hold its value
        input = $("<input>").attr("name", name).val(value);
      } 
      // convert form name to row name
      input.attr("name", form_to_row_name(name, model, get_row_index()));

      // add hidden attribute and append to the row
      input.attr("type", "hidden");
      tr.append(input);
    }
  });

  tr.addClass("input-row");
  return tr;
}

// remove "[i]" between model name and rest of name
function row_to_form_name(row_name, model, row_index) {
  var slice_at = (model + "[" +row_index+ "]").length;
  var name_end = row_name.slice(slice_at);
  var form_name = model + name_end;
//logger("row_to_form_name: " + form_name);
  return form_name
}

// add "[i]" between model name and rest of name
function form_to_row_name(form_name, model, row_index) {
  var slice_at = model.length;
  var name_end = form_name.slice(slice_at);
  var row_name = model + "[" +row_index+ "]" + name_end;
//logger("form_to_row_name: " + row_name);
  return row_name;
}

// given an array of input type elemnents,
// return an array in the desired row order
function get_grid_inputs(input_elements) {
  // get ordered grid input names
  var order = grid_attrs_order();

  // columns hidden in form to unhide in the grid
  var unhide = ["position_in_container"];

  var result = [];
  order.forEach(function(name, index) {
    input_elements.forEach(function(input) {
      if (input.getAttribute("name").endsWith(name + ']')) {

        // make new input objects separate from default values form
        var input_clone = input.cloneNode(true);

        // unhide columns needed in grid
        if (unhide.includes(name)) {
          $(input_clone).removeAttr("hidden");
        }
        result[index] = input_clone;
      }
    });
  });
  return result;
}

// get the inputs not included in the grid so they can
// be included as hidden inputs in each row's form
function get_hidden_inputs(input_elements) {
  var grid_names = grid_attrs_order();

  var result = [];
   input_elements.forEach(function(input) {
     found = false;
     grid_names.forEach(function(grid_name) {
        if (input.getAttribute("name").endsWith(grid_name + ']')) {
          found = true;
        }
     });
     if (!found) {
       result.push(input.cloneNode(true));
     }
   });
  return result;
}

function grid_attrs_order() {
  // define the order of columns in the edit table
  var order = [
    "barcode_key",
    "amount_initial",
    "sample_remaining",
    "position_in_container",
    "container_name",
    "freezer_location_id",
    "vial_type",
    "comments"
  ];
  return order;
}

// take a new row jquery object and copies the selected state
// from the default values to the grid selects
function copy_selected_values(new_row, model, row_index) {
  // set the row index into the new_row
  new_row.attr("data-row-index", row_index);

  var selects = new_row.find("select");
  selects.each(function() {
    // find the default value form select's value
    // remove the "[]" from the name so it can match the form names
    //var name = $(this).attr("name").slice(0, -2);
    var name = row_to_form_name($(this).attr("name"), model, row_index);
    var value = $("#default-values").find("select[name='"+name+"']").val();
    // set the new rows value
    $(this).val(value);
    $(this).trigger("change");
  });
}

// keep track of and return the next barcode and row index
function new_barcode(source_barcode, next_barcode) {
  if (window.barcode_base === undefined) {
    // init from source sample barcode and next barcode passed in hidden field
    window.barcode_base = source_barcode;
    window.barcode_suffix = next_barcode.slice(source_barcode.length);
  } else {
    window.barcode_suffix = next_barcode_suffix();
  }
  return (window.barcode_base + window.barcode_suffix);
}

function next_barcode_suffix() {
  return String.fromCharCode(window.barcode_suffix.charCodeAt(0) + 1);
}

function new_row_index() {
  if (window.row_index === undefined) {
    window.row_index = 0;
  } else { window.row_index++; }
}

function get_row_index() {
  return window.row_index;
}
