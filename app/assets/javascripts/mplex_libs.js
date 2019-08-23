// standard init functions
// Format: <controller>_init() => controller specific init
//   <controller>_<action>_init() => controller/action specific init
//

// mplex_libs new init
function mplex_libs_new_init() {
    storage_container_init();
}

// mplex_libs edit init
function mplex_libs_edit_init() {
    storage_container_init();
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
