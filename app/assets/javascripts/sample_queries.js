// standard init functions
// Format: <controller>_init() => controller specific init
//   <controller>_<action>_init() => controller/action specific init

// samples controller init function
function sample_queries_init() {
  samples_tab_active();
}

// samples controller#index init function
function sample_queries_index_init() {

  var dt = $("table.data-table").DataTable( {
    // define column 0 as hidden but searchable
    // used for distinguishing source from dissection sample
    columnDefs: [ { targets: [0], visible: false, searchable: true } ]
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

  // search filter and redraw on change
  $(".source-select select").on('change', function() {
    dt.columns(0).search(this.value).draw();
  });

  // init for the selected actions feature
  selected_actions_init();
}

function selected_actions_init() {

  // enable row selections using 'selected' class
  // once selected, an action to be applied to all the selected items
  // can be triggerred
   $("table.data-table tbody").on('click', 'tr', function() {
    $(this).toggleClass('selected');
  });

  // handle update-sample actions
  $(".dropdown-menu #update-sample").on('click', function() {
    // set the selected rows
    if (save_selected() == 0) {
      //my_alert("No rows have been selected for update");
      dt_alert("info", "No rows have been selected for update");
      return
    }
    // init and open the lightbox
    lightbox_init("Update Selected Samples", "Edit Next", "Edit Again", edit_sample)
  });

  // handle enter-dissection actions
  $(".dropdown-menu #enter-dissection").on('click', function() {
    if (save_selected() == 0) {
      //my_alert("No rows have been selected for entering dissections");
      dt_alert("info", "No rows have been selected for update");
      return
    }
    // ensure that all selected rows are source samples
    if (!selected_all_source()) {
      dt_alert("info", "Some selected are not source samples, please de-select");
      return
    }

    // init dissection sticky fields, copied to next new dissection
    dissection_sticky_fields_init();

    // init and open the lightbox
    lightbox_init("Enter Dissection for Selected Samples", "Next Sample", "Another Dissection", new_dissection)
  });
}

// init the light box html with text,
// save the lightbox node and function to initiate this processing,
// get the first selection and initiate the processing on it
// and launch the lightbox with context
function lightbox_init(title, next_text, again_text, initiate_fcn) {
  var lb = $(".action-lightbox");

  // set the text fields for this set of actions
  lb.find(".lightbox-title").text(title);
  lb.find(".next-button").text(next_text);
  lb.find(".again-button").text(again_text);

  // set the initiating ajax caller function for the action
  window.initiate_fcn = initiate_fcn;

  // get the first row
  var first = next_selection();
  if (first == null) {
    dt_alert("No rows have been selected for update");
    return;
  }

  // launch the lightbox
  $.featherlight(lb, {
    afterOpen: function(evt) {
      // bind the handler for the next button
      $(".featherlight .next-button").on('click', handle_next);
      // bind the handler for the again button
      $(".featherlight .again-button").on('click', handle_again);
      // bind the handler for the cancel all button
      $(".featherlight .cancel-button").on('click', handle_cancel);

      // set selections left indicator
      set_selections_left();

      // invoke for the first selection
      initiate_fcn(first, $(featherlight_selector()).get(0));
    }
  });

}

function featherlight_selector() {
  return ".featherlight .lightbox-body";
}

function flash_selector() {
  return ".flash-box";
}

// make ajax call to edit the sample
// determine if it is a source sample or dissected sample
// to form proper URL
function edit_sample(row_index, context) {
logger("edit_sample("+row_index+", "+context+")");
  // get jquery row
  var row = $(node_at_index(row_index));
  // get the sample id from export field
  var  id = row.find("input[name='export_id[]']").val();

  var url;
  if (is_source_sample(row_index)) {
    url = "/samples/" + id + "/edit";
  } else {
    url = "/dissected_samples/" + id + "/edit";
  }
  ajax_action(url, id, context, "Edit", "Update");
}

// get the source sample id from the row and call new dissection with ajax
// we assume that all selections are source samples when called
function new_dissection(row_index, context) {
logger("new_dissection("+row_index+", "+context+")");
  // get jquery row
  var row = $(node_at_index(row_index));
  // get the sample id from export field
  var  id = row.find("input[name='export_id[]']").val();

  var url = "/dissected_samples/new/?" + $.param({source_sample_id: id});

  ajax_action(url, id, context, "Dissection", "Add dissection to");
}

// common ajax action routine to call the initial action
// and do the ajax_bind for the subsequent submit request
function ajax_action(url, id, context, request_label, submit_label) {
  // send the ajax request
  $.ajax(url, {context: context

    }).done(function(data, textStatus, jqXHR) {
//logger("ajax done called for " + request_label);

      // when done attach the respnse html to the lightbox body
      $(this).empty().append(data);

      // do anything needed aftr the initial function response is loaded
      after_action_loaded(url)

      // bind the form for the update ajax return handling
      ajax_bind(featherlight_selector()+" form", "", submit_label+" selected sample", submit_success, submit_error, {flash_selector: flash_selector});

    }).fail(function(jqXHR, textStatus, errorThrown) {
      set_header_flash_messages(jqXHR, flash_selector());
      my_alert(request_label+" request for "+ id +" failed: "+ textStatus +" responseText: "+ jqXHR.responseText);
    });
}

// on action submit success remove the initial form and append the result page
function submit_success(form, evt, data, status, xhr) {
  var html = xhr.responseText
  var body = $(featherlight_selector());
  body.empty();
  body.append(html);
}

// on action submit error log the error, the generic remote_error() method
// will do the rest
function submit_error(form, evt, xhr, status, error) {
logger("submit_error: " + status + " " + xhr.responseText);
}

// handle the next selection button
function handle_next() {
  // get the next row
  var next = next_selection();
  if (next == null) {
    //my_alert("Selection set is empty");
    lb_alert("info", "No more selections to process");
    return;
  }
  // set selections left indicator
  set_selections_left();

  // call the initiator function on the next selection
  window.initiate_fcn(next, $(featherlight_selector()).get(0));
}

// handle the again button to repeat action
function handle_again() {
  var current = current_selection();
  // call the initiator function on the current selection
  window.initiate_fcn(current, $(featherlight_selector()).get(0));
}

// cancel all of the selected actions
// remove the selections from the table and close the lightbox
function handle_cancel() {
  $("table.data-table tr.selected").removeClass("selected");
  $.featherlight.current().close();
}

// return true if all selected samples are source samples else false
function selected_all_source() {
  return !window.selected_rows.some(is_not_source_sample)
}

function is_not_source_sample(row_index) {
  return !is_source_sample(row_index)
}

function is_source_sample(row_index) {
  // first column is source tag
  return (window.datatable.row(row_index).data()[0] == "is-source")
}

// save the selected rows from the table
// and return the number of rows selected
function save_selected() {
  var dt = window.datatable;
  // array of selected row indexes
  window.selected_rows = dt.rows('.selected')["0"];
  return window.selected_rows.length
}

// get the current selection row index from the saved set
function current_selection() {
  return window.current_row_index;
}

// get the next selection row index from the saved set
// save it as the current in case we need to repeat the action
// and remove it from the selected set
// also remove the selected class from the <tr> node
function next_selection() {
  if (window.selected_rows.length == 0) {
    return null;
  }
  var next_row_index = window.selected_rows.shift();
  window.current_row_index = next_row_index;

  // remove the selected class so it is not highlighted
  var dt = window.datatable;
  var tr_node = dt.row(next_row_index).node();
  var next = $(tr_node);
  next.removeClass("selected");

  // return row index
  return next_row_index;
}

// return the <tr> node at the given row index
function node_at_index(row_index) {
  return window.datatable.row(row_index).node()
}

// alert attached to lightbox
function lb_alert(type, message) {
  bs_alert(".featherlight .alert-box", type, message)
}

// alert attached to top of Datatable
function dt_alert(type, message) {
  bs_alert(".top-alert-box", type, message)
}
// display a bootstrap style alert on the page
// type is type of alert, i.e. primary, secondary, success, danger
// warning, info, light and dark
function bs_alert(selector, type, message) {
  var copy = $(".alert-template").clone();
  copy.addClass("alert-" + type).append(message);
  copy.appendTo(selector).show();
}

function set_selections_left() {
  var msg = "  Selections Remaining: " + window.selected_rows.length;
  $(".featherlight .selections-left").empty().append(msg);
}

// things to do after the initial action is done and loaded
function after_action_loaded(url) {
  // if this is a new dissection request
  // copy the saved sticky fields to the form
  // and arrange to save before commit
  if (url.startsWith("/dissected_samples/new")) {
    dissection_sticky_fields_copy();

    // temporarily hijack the submit to save the submitted sticky fields
    $(featherlight_selector()+" form input[name='commit']").on("click", function() {
      dissection_sticky_fields_save();
    });
  }

  // initialize the storage location functions if the corresponding
  // templates are present
  ajax_storage_container_init();
}

// define the fields that are sticky from one instance to the next
// and init to null
function dissection_sticky_fields_init() {
  window.dissection_sticky_fields = {
    input: ["amount_initial"],
    select: ["vial_type", "sample_container", "amount_uom"]
  };
  window.dissection_sticky_vals = null;
}

// find and save the sticky fields in an object
function dissection_sticky_fields_save() {
logger("dissection_sticky_fields_save()");
  var sf = window.dissection_sticky_fields;
  var form = $(featherlight_selector()+" form");
  var vals = {}
  for (const tag in sf) {
    sf[tag].forEach(function(field) {
      var name = "sample["+field+"]";
      vals[field] = form.find(tag+"[name='"+name+"']").val();
    });
  }
  window.dissection_sticky_vals = vals;
}

// get the saved sticky fields and insert into the form input fields
function dissection_sticky_fields_copy() {
logger("dissection_sticky_fields_copy()");
  var vals = window.dissection_sticky_vals;
  if (vals == null) { return } // first dissection
  var sf = window.dissection_sticky_fields;
  var form = $(featherlight_selector()+" form");
  for (const tag in sf) {
    sf[tag].forEach(function(field) {
      var name = "sample["+field+"]";
      var elem = form.find(tag+"[name='"+name+"']").val(vals[field]);
      if (tag == "select") {
        elem.trigger("change");
      }
    });
  }
}
