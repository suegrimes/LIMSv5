
// standard init functions
// Format: <controller>_init() => controller specific init
//   <controller>_<action>_init() => controller/action specific init
//
// currently handling both samples and sample_characteristics in this file

// samples controller init function
function samples_init() {
  //samples_tab_active();
}

// samples edit init
function samples_edit_init() {
  // new storage management init
  storage_container_init();

  // storage containers edit init
  edit_storage_container_init();
}

// sample_characteristics controller init function
function sample_characteristics_init() {
  //samples_tab_active();
}

// sample_characteristics new_sample init
function sample_characteristics_new_sample_init() {
  // new storage management init
  storage_container_init();
}

// sample_characteristics create init
function sample_characteristics_create_init() {
  // new storage management init
  storage_container_init();
}

// sample_characteristics new_sample init
function sample_characteristics_edit_init() {
  edit_add_another_sample();
  // new storage management init
  storage_container_init();

  // storage containers edit init
  edit_storage_container_init();
}

// sample_characteristics show init
function sample_characteristics_show_init() {
   show_sample();
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

function edit_add_another_sample() {
  $('#add_more').bind("ajax:success", function(event){
     var detail = event.detail;
     var response_data = detail[0], status = detail[1], xhr = detail[2];
    $('#sample_link').toggle();
    $('#load_more').html(xhr.responseText); // insert content
    reset_styling();
  });
}

function show_sample() { 
  $('#add_more').bind("ajax:success", function(event, data){
    var detail = event.detail;
    var response_data = detail[0], status = detail[1], xhr = detail[2];
    $('#sample_link').toggle();
    $('#load_more').html(xhr.responseText); // insert content
    reset_styling();
  });   
}

// handle error
function fetch_error(evt_elem, evt, xhr, status, error) {
  logger("Error loading form");
}

//function samples_tab_active() {
  // remove any currently active
//  $('#top-nav .nav-link').removeClass('active');
  // add active to samples tab
//  $('#top-nav #samples-tab').addClass('active');
//}
