
// standard init functions
// Format: <controller>_init() => controller specific init
//   <controller>_<action>_init() => controller/action specific init
//
// currently handling both samples and sample_characteristics in this file

// samples edit init
function sample_storage_containers_edit_init() {
  // new storage management init
  storage_container_init();

  // storage containers edit init
  edit_storage_container_init();
}
