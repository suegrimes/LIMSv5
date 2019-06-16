// standard init functions
// Format: <controller>_init() => controller specific init
//   <controller>_<action>_init() => controller/action specific init
//
// currently handling both samples and sample_characteristics in this file

// samples edit init
function mplex_libs_edit_init() {
    // new storage management init
    storage_container_init();

    // storage containers edit init
    edit_storage_container_init();
}

function checkUncheckAll(theElement) {
    var theForm = theElement.form, z = 0;
    for(z=0; z<theForm.length;z++){
        if(theForm[z].type == 'checkbox' && theForm[z].name != 'checkall'){
            theForm[z].checked = theElement.checked;
        }
    }
}
