// generic ajax binding function
//
// selector is a jquery selector string
// fcn_label is a string to pass into error messages
// fcn_success and fcn_error are functions to call on success and error
// which are called with this as the first parameter followed by the normal params
// options is an object which have the following properties:
//    no_success_alert - if true no alert user on success, default is false
//    success_alert - if true alert user on success, default is true
//    reset_styling - if true reset the styling after executing the success function, default is false
//    flash_selector - jQuery selector for flash box, default is '#flash_box'

// Note: handler function signatures have changed in Rails 5.1 when using rails-ujs:
// 0 or one event parametr is passed and old params are in event.detail[] array

function ajax_bind(selector, data, fcn_label, fcn_success, fcn_error, options) {

  $(document).on("ajax:beforeSend", selector, data, function() {
    $(this).addClass("waiting");

  }).on("ajax:success", selector, data, function(evt) {
    var detail = evt.detail;
    var response_data = detail[0], status = detail[1], xhr = detail[2];
//logger("ajax_bind("+selector+"): success: "+response_data);
    $(this).removeClass("waiting");
    if (fcn_success) {
      fcn_success(this, evt, response_data, status, xhr);
    }
    if (options) {
      // in case html was added to DOM which needs to be styled
      if (options.reset_styling) {
        reset_styling();
      }
      if (options.no_success_alert) {
      } else if (options.success_alert) {
        my_alert(options.success_alert);
      }
    } else {
      my_alert("Successful");
    }

  }).on("ajax:error", selector, data, function(evt) {
    var detail = evt.detail;
    var error = detail[0], status = detail[1], xhr = detail[2];
    $(this).removeClass("waiting");
    if (fcn_error) {
      fcn_error(this, evt, xhr, status, error);
    }
    if (options && options.flash_selector) {
      remote_error(xhr, error, fcn_label, options.flash_selector);
    } else {
      remote_error(xhr, error, fcn_label);
    }
  });
}

// generic error handling for remote ajax call

function remote_error(xhr, error, fcn_label, flash_selector) {
  var label = "Error: ";
  if (fcn_label) {
    label =  fcn_label+": ";
  }
  if (xhr.status == 401) {
    set_flash("error", xhr.responseText, flash_selector);
//    shrink_flash_timer(5000, function() {
//      redirect_relative('users/sign_in');
//    });
  } else if (xhr.status >= 400 && xhr.status <= 499) {
    // handle client erros
    set_header_flash_messages(xhr, flash_selector);
    my_alert(label+error+" - "+xhr.responseText);
  } else {
    // handle server errors
    my_alert(label+error+" - "+xhr.responseText);
  }
}

// set the flash message in the flash box
// selector is an optional parameter for the flashbox
function set_flash(key, message, selector) {
  if (typeof selector === 'undefined') { selector = '#flash_box'; }
  var html = '<div class="'+key+' flash_msg" id="flash_'+key+'">'+message+'</div>';
  $(selector).empty().append(html);
}

// set flash messages from response headers
// selector is an optional parameter for the flashbox
function set_header_flash_messages(xhr, selector) {
  if (typeof selector === 'undefined') { selector = '#flash_box'; }
  var box = $(selector);
  box.empty();
  var fm_str = xhr.getResponseHeader("X-Flash-Messages");
  var fm = $.parseJSON(fm_str);
  //alert("fm.inspect: "+Object.inspect(fm));
  for(var key in fm) {
    if (fm.hasOwnProperty(key)) {
      var html = $('<div class="'+key+' flash_msg" id="flash_'+key+'">'+fm[key]+'</div>');
      // bootstrap customization
      bs_class = "";
      if (key == "notice") {
        bs_class = "text-success"
      } else if (key == "error") {
        bs_class = "text-danger"
      }
      html.addClass(bs_class);
      box.append(html);
    }
  }
}

// set default datatype
function set_ajax_datatype(type) {
  $.ajaxSetup({
    dataType: type
  });
}
