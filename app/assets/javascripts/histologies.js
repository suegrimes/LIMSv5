// standard init functions
// Format: <controller>_init() => controller specific init
//   <controller>_<action>_init() => controller/action specific init

function histologies_new_init() {
    storage_container_init();
    //edit_storage_container_init();
}

function histologies_edit_init() {
    storage_container_init();
    edit_storage_container_init();
}

function histologies_edit_storage_init() {
    storage_container_init();
    edit_storage_container_init();
}
//--------------------------------------------------------
