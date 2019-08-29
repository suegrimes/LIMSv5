function seq_kit_populate_dropdown() {
    var seq_kits;
    seq_kits = $('select.seq-kit').html();
    console.log(seq_kits);

    // For edit form, or after validation error on create, have existing machine type
    handle_existing_machine_type(seq_kits)

    $('select.machine-type').change(function() {
        var machine_type, options;
        machine_type = $('select.machine-type :selected').val();

        options = kit_options_for_machine_type(seq_kits, machine_type)
        console.log(options);
        if (options) {
            return $('select.seq-kit').html(options);
        } else {
            return $('select.seq-kit').empty();
        }
    });
};

// After error the machine type may already be selected
// If so initialize the sequencing kit dropdown accordingly
function handle_existing_machine_type(seq_kits) {
    var selected_kit = $("select.seq-kit");
    if (selected_kit.val() != "") { return }

    var selected_machine = $("select.machine-type").val();
    if (selected_machine === undefined) { selected_machine = $("input.machine-type").val() }
    logger("Have machine type "+selected_machine)

    var options =  kit_options_for_machine_type(seq_kits, selected_machine);
    console.log(options);
    if (options) {
        return $('select.seq-kit').html(options);
    } else {
        return $('select.seq-kit').empty();
    }
}

function kit_options_for_machine_type(seq_kits, machine_type) {
    if (machine_type == "") {
        return seq_kits
    } else {
        return $(seq_kits).filter("optgroup[label=" + machine_type + "]").html();
    }
}
