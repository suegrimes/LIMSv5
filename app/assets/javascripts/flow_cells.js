// Routines to help manage flow cell form responses

function flow_cells_new_init() {
    // handle machine type selection or de-selection
    logger('DEBUG::flow_cells_new_init')
    var machine_type = ''
    $("select#flow_cell_machine_type").on("change", function() {
        var machine_type = $(this).val();

        // check for kits for selected machine type
        var select_machine_kit_names = []
        $.each(window.machine_type_kits, function( index, value ) {
            if (value.includes(machine_type)) {
                select_machine_kit_names.push(value)
            }
        });
        var options = mk_seq_kit_options(select_machine_kit_names)
        add_kit_options(options);
    });
}

function mk_seq_kit_options(kit_names) {
    var options = [];
    kit_names.forEach(function(row) {
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