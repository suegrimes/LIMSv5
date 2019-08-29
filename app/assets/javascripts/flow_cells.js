// Routines to help manage flow cell form responses
function flow_cells_init() {
    var seq_kits;
    seq_kits = $('#flow_cell_sequencing_kit').html();
    console.log(seq_kits);

    // For edit form, or after validation error on create, have existing machine type
    handle_existing_machine_type(seq_kits)

    $('#flow_cell_machine_type').change(function() {
        var machine_type, options;
        machine_type = $('#flow_cell_machine_type :selected').val();

        options = kit_options_for_machine_type(seq_kits, machine_type)
        console.log(options);
        if (options) {
            return $('#flow_cell_sequencing_kit').html(options);
        } else {
            return $('#flow_cell_sequencing_kit').empty();
        }
    });
};

// After error the machine type may already be selected
// If so initialize the sequencing kit dropdown accordingly
function handle_existing_machine_type(seq_kits) {
    var selected_kit = $("select#flow_cell_sequencing_kit");
    if (selected_kit.val() != "") { return }

    var selected_machine = $("select#flow_cell_machine_type").val();
    if (selected_machine === undefined) { selected_machine = $("input#flow_cell_machine_type").val() }
    logger("Have machine type "+selected_machine)

    var options =  kit_options_for_machine_type(seq_kits, selected_machine);
    console.log(options);
    if (options) {
        return $('#flow_cell_sequencing_kit').html(options);
    } else {
        return $('#flow_cell_sequencing_kit').empty();
    }
}

function kit_options_for_machine_type(seq_kits, machine_type) {
    if (machine_type == "") {
        return seq_kits
    } else {
        return $(seq_kits).filter("optgroup[label=" + machine_type + "]").html();
    }
}


