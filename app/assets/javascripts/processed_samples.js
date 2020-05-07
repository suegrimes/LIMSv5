// standard init functions
// Format: <controller>_init() => controller specific init
//   <controller>_<action>_init() => controller/action specific init

// processed_samples new init
function processed_samples_new_init() {
    storage_container_init();
}

function processed_samples_edit_init() {
    storage_container_init();
    edit_storage_container_init();
}
