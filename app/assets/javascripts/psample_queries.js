// standard init functions
// Format: <controller>_init() => controller specific init
//   <controller>_<action>_init() => controller/action specific init

// psample_queries controller init function
function psample_queries_init() {
  samples_tab_active();
}

// psample_queries controller#index init function
function psample_queries_index_init() {

  var dt = $("table.data-table").DataTable({
      // Columns with links should not be sortable or searchable
      columnDefs: [ { targets: [ 'action', 'link-col'], sortable: false, searchable: false } ]
  });

  // fix for back button, destroy DataTables before caching the page
  document.addEventListener("turbolinks:before-cache", function() {
    if (dt !== null) {
     dt.destroy();
     dt = null;
    }
  });

}
