//Note: This should be changed to use classes instead of ids so can be more general
//      Currently specific to flow_cells/view ids

function sequencer_kit_init() {
    // handle machine type selection or de-selection
    logger('DEBUG::sequencer_kits_init')
    var machine_type = ''
    $("select#flow_cell_machine_type").on("change", function() {
        var machine_type = $(this).val();
        var options = mk_seq_kit_options(machine_type)
        add_kit_options(options);
    });

    // Initialize drop-down values if there is a selected value, but not on-change trigger
    // This could happen in create action after an error
    handle_existing_machine_type();
}

function mk_seq_kit_options(machine_type) {
    // check for kits for selected machine type
    var select_machine_kit_names = []
    $.each(window.machine_type_kits, function( index, value ) {
        if (value.includes(machine_type)) {
            select_machine_kit_names.push(value)
        }
    });

    var options = [];
    select_machine_kit_names.forEach(function(row) {
        var option = $("<option></option>");
        option.attr("value", row[0]);  // kit_name
        option.text(row[0]);
        options.push(option);
    });
    return options;
}

function add_kit_options(options) {
    logger("add_kit_options() "+options.length+" options");
    var first_option = $("select#flow_cell_sequencing_kit :first-child");
    if (options.length == 0) {
        first_option.nextAll().remove();
        first_option.text("No kits available for this machine type");
        return;
    }
    first_option.nextAll().remove();
    first_option.after(options);
    first_option.text("Select..");
}

// After error the machine type may already be selected
// If so initialize the sequencing kit dropdown accordingly
function handle_existing_machine_type() {
    var seq_kit = $("select#flow_cell_sequencing_kit");
    if (seq_kit.val() != "") { return }
    var machine_type = $("select#flow_cell_machine_type").val();
    if (machine_type === undefined) { machine_type = $("input#flow_cell_machine_type").val() }
    logger("Have machine type "+machine_type)
    if (machine_type == "") { return }
    var options = mk_seq_kit_options(machine_type);
    logger("Options for machine type are: "+options)
    add_kit_options(options);
}
