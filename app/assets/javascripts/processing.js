
// standard init functions
// Format: <controller>_init() => controller specific init
//   <controller>_<action>_init() => controller/action specific init

// samples controller init function
function dissected_samples_init() {
  processing_tab_active();
}

// sample_characteristics controller init function
function processed_samples_init() {
  processing_tab_active();
}

// sample_queries controller init function
function sample_queries_init() {
  processing_tab_active();
}

// sample_queries controller init function
function psample_queries_init() {
  processing_tab_active();
}

//--------------------------------------------------------

function processing_tab_active() {
  // remove any currently active
  $('#top-nav .nav-link').removeClass('active');
  // add active to samples tab
  $('#top-nav #processing-tab').addClass('active');
}
