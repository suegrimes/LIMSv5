/* with turbolinks this no longer works */
//$(document).ready(function() {

$( document ).on('turbolinks:load', function() {
logger("turbolinks:load");
  common_init();

  /* look for controller and action specific init routines to call */
  invoke_specific_inits();
});

function common_init() {

  // make html the default data type
  // force page nav ajax calls to default to HTML
  set_ajax_datatype("html");

  // set common styling
  reset_styling()
}

// Get the controller and action names from the body tag
// and invoke controller or action specific functions if defined
function invoke_specific_inits() {
logger("invoke_specific_inits()");
  var body = document.body;
  var controller = body.getAttribute("data-controller");
  var action = body.getAttribute("data-action");
  var c_func_name = controller+'_init';
  var a_func_name = controller+'_'+action+'_init';
  c_function = window[c_func_name];
  a_function = window[a_func_name];
  if (typeof c_function == "function") {
    // invoke it
logger("Calling "+c_func_name+'()');
    c_function();
  }
  if (typeof a_function == "function") {
    // invoke it
logger("Calling "+a_func_name+'()');
    a_function();
  }
}

/* common functions here */

// logger function
function logger(msg) {
  if (console) {
    console.log(msg);
  }
}

// common alert function if different from browser
function my_alert(msg) {
  if (alertify) {
    alertify.alert(msg);
  } else {
    alert(msg);
  }
}
