function checkUncheckAllSamples(theElement) {
    var theForm = theElement.form, z = 0;
    for(z=0; z<theForm.length;z++){
        if(theForm[z].type == 'checkbox' && theForm[z].id.startsWith('image_slide')) {
            theForm[z].checked = theElement.checked;
        }
    }
}
