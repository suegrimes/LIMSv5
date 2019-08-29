// Routines to help manage flow cell form responses

jQuery(function() {
    var seq_kits;
    seq_kits = $('#flow_cell_sequencing_kit').html();
    console.log(seq_kits);
    return $('#flow_cell_machine_type').change(function() {
        var machine_type, options;
        machine_type = $('#flow_cell_machine_type :selected').text();
        if (machine_type == "") {
            options = $(seq_kits).html()
        } else {
            options = $(seq_kits).filter("optgroup[label=" + machine_type + "]").html();
        }
        console.log(options);
        if (options) {
            return $('#flow_cell_sequencing_kit').html(options);
        } else {
            return $('#flow_cell_sequencing_kit').empty();
        }
    });
});


function flow_cells_init() {
//    sequencer_kit_init()
}

