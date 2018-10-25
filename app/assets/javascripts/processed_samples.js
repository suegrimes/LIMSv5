// standard init functions
// Format: <controller>_init() => controller specific init
//   <controller>_<action>_init() => controller/action specific init

// dissected_samples controller init function
function processed_samples_init() {
    processing_tab_active();
}

// dissected_samples edit init
function processed_samples_edit_init() {
    // new storage management init
    storage_container_init();

    // storage containers edit init
    edit_storage_container_init();
}

//--------------------------------------------------------