
// standard init functions
// Format: <controller>_init() => controller specific init
//   <controller>_<action>_init() => controller/action specific init

// samples controller init function
function samples_init() {
  samples_tab_active();
}

// sample_characteristics controller init function
function sample_characteristics_init() {
  samples_tab_active();
}

//--------------------------------------------------------

// sample index page init function
function samples_index_init() {
logger("samples_index_init()");

  // bind to dropdown links to handle html returned
  var options = {no_success_alert: true, reset_styling: true};
  ajax_bind('a.dropdown-item', "none", "Load menu", append_form, fetch_error, options);
}

// append the html returned
function append_form(evt_elem, evt, data, status, xhr) {
logger("append_form()");
//logger("status: "+ status);
//logger("evt.data: "+ evt.data.toString());
//logger("response data type: "+ typeof(data));
//logger("response data: "+ JSON.stringify(data));
//logger("xhr.responseText: "+ xhr.responseText);

  $('#sample-container').empty().append(xhr.responseText);
}

// handle error
function fetch_error(evt_elem, evt, xhr, status, error) {
  logger("Error loading form");
}

function samples_tab_active() {
  // remove any currently active
  $('#top-nav .nav-link').removeClass('active');
  // add active to samples tab
  $('#top-nav #samples-tab').addClass('active');
}
