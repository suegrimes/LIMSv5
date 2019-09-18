function seq_kit_populate_dropdown() {
    var seq_kits;
    seq_kits = $('select.seq-kit').html();
    console.log(seq_kits);

    // For edit form, or after validation error on create, have existing machine type
    handle_existing_machine_type(seq_kits);

    $('select.machine-type').change(function() {
        var machine_type = $('select.machine-type :selected').val();
        set_kit_options_for_machine_type(seq_kits, machine_type)
    });
};

// After error, or pressing 'Back' button, machine type may already be selected
// If so initialize the sequencing kit dropdown accordingly
function handle_existing_machine_type(seq_kits) {
    var selected_kit = $("select.seq-kit");
    if (selected_kit.val() != "") { return }

    var selected_machine = $("select.machine-type").val();
    if (selected_machine === undefined) { selected_machine = $("input.machine-type").val() }

    logger("Have machine type "+selected_machine)
    set_kit_options_for_machine_type(seq_kits, selected_machine)
}

function set_kit_options_for_machine_type(seq_kits, machine_type) {
    var kit_options;
    if (machine_type == "") {
        kit_options = seq_kits
    } else {
        kit_options = $(seq_kits).filter("optgroup[label=" + machine_type + "]").html();
        nr_options = (kit_options.match(/<option/g) || []).length;
        if (nr_options > 1) {kit_options = "<option value=''>Select..</option>" + kit_options;}
    }

    console.log(kit_options);
    if (kit_options) {
        return $('select.seq-kit').html(kit_options);
    } else {
        return $('select.seq-kit').empty();
    }
}
