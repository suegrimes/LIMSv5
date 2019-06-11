// standard init functions
// Format: <controller>_init() => controller specific init
//   <controller>_<action>_init() => controller/action specific init

// processed_samples edit init
function processed_samples_edit_init() {
    // new storage management init
    storage_container_init();

    // storage containers edit init
    edit_storage_container_init();
}

//--------------------------------------------------------