// standard init functions
// Format: <controller>_init() => controller specific init
//   <controller>_<action>_init() => controller/action specific init

// samples controller init function
function psample_queries_init() {
  samples_tab_active();
}

// samples controller#index init function
function psample_queries_index_init() {

  var dt = $("table.data-table").DataTable( {
    // define column 0 as hidden but searchable
    columnDefs: [ { targets: [0], visible: false, searchable: true } ]
  });

  // fix for back button, destroy DataTables before caching the page
  document.addEventListener("turbolinks:before-cache", function() {
    if (dt !== null) {
     dt.destroy();
     dt = null;
    }
  });

}
