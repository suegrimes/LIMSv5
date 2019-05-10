
function set_bootstrap_style() {

  // set all forms to have small inputs and labels
  // this is done here so that standard Rails form builders can be used
  // without alot of customization of the markup

  // use small form controls
  $('.form-group .form-control').addClass('form-control-sm');
  $('.form-group .col-form-label').addClass('col-form-label-sm');

  // set width to over-ride 100% if an explicit input size if set
  // uses em-width classes defined for every 10em up to 100em
/*
  $('.form-group input[size]').each(function() {
    if (typeof(this.size) == "number") {
      var sz = Math.floor(this.size / 10) * 10;
      if (sz >= 100) { sz = 100 }  // set the largest category 
      $(this).addClass("em-width-" + sz);
    }

    // set display: inline-block for labels before
    var name = $(this).name;
    $(this).parent().find("label[for="+"'"+name+"'"+"]").addClass("d-inline");
  });
*/
}
