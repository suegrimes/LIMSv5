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
    columnDefs: [ { targets: [0], visible: false, searchable: true } ]
  });

  // attach the select to the DOM and filter on change
  $(".source-select").append(select_source_html()).find('select').on('change', function() {
logger("Got select change");
    dt.columns(0).search(this.value).draw();
  });
}

function select_source_html() {
  var html =
  '<label class="col-auto col-form-label">Sample Type:</label>' +
  '<div class="col-auto">' +
    '<select class="form-control">' +
      '<option value="">All</option>' +
      '<option value="is-source">Source</option>' +
      '<option value="is-dissection">Dissection</option>' +
    '</select>' +
  '</div>';
  return $(html);
}
