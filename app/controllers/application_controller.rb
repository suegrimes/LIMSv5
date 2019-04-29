class ApplicationController < ActionController::Base
  protect_from_forgery
  include AuthenticatedSystem
  include RoleRequirementSystem
  include LimsCommon
  require 'rubyXL'

  before_action :login_required
 
  #Make current_user accessible from model (via User.current_user)
  before_action :set_current_user
  before_action :log_user_action

  # for ajax, set flash message into the headers
  after_action :flash_to_headers

  rescue_from CanCan::AccessDenied do |exception|
    user_login = (current_user.nil? ? nil : current_user.login)
    Rails.logger.debug "Access denied for user #{user_login} on #{exception.action} #{exception.subject.inspect}"
    flash[:error] = "Sorry #{user_login}, you are not authorized to access that page"
    redirect_to root_url
  end
  # 
  require 'csv'
  #require 'calendar_date_select'

  helper :all # include all helpers, all the time
  #
  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  protect_from_forgery # :secret => 'a7fa20ae329c39ca9cb722a7173c224f'
  
  # See ActionController::Base for details 
  # Uncomment this to filter the contents of submitted sensitive data parameters
  # from your application log (in this case, all fields with names like "password"). 
  #filter_parameter_logging :password, :mrn
  DateRange = Struct.new(:from_date, :to_date)

  def category_filter(categories, cat_name, output='collection')
    category_selected = categories.select{|cm| cm.category == cat_name}
    if output == 'string'
      return category_selected[0].category_values.map {|cv| cv.c_value}
    else
      return category_selected[0].category_values
    end  
  end
  
#  def base_barcode(barcode_key)
#    barcode_split = barcode_key.split('.')
#    return barcode_split[0]
#  end
  
  def barcode_type(barcode_key)
    barcode_split = barcode_key.split('.')
    if barcode_split.length == 1
      return 'S'
    else
      return barcode_split[-1][0,1] # first character of last substring after splitting by '.'
    end
  end
  
  def param_blank?(val)
    if val.nil?
      val_blank = true
    elsif val.is_a? Array
      #val_blank = (val.size == 1 && val[0].blank? ? true : false )
      # Hack due to change in Rails 3 which passes hidden value for collection_select/multiple and causes duplicate blank entry in array
      val_blank = (val.size == 1 && val[0].blank? ) || (val.size == 2 && val[0].blank? && val[1].blank?)
    else
       val_blank = val.blank?
    end
    return val_blank 
  end
  
  def array_to_string(arry, delim=',')
    if arry.nil? || arry.empty? 
      string_val = nil
    else
      string_val = arry.join(delim)
    end
    return string_val
  end
  
  def find_patient_nr(model, id)
    patient_id = model.constantize.find(id).patient_id
    return format_patient_nr(patient_id, 'array')
  end
  
  # If current_user can read MRN, format patient nr as id/mrn, otherwise just id
  def format_patient_nr(id, format='string')
    if can? :read, Patient
      patient = Patient.find(id)
    end  
    
    if patient
      patient_numbers = [id.to_s, patient.mrn]
      return (format == 'string' ? patient_numbers.join(' / ') : patient_numbers)
    else
      return (format == 'string' ? id.to_s : [id.to_s])
    end 
  end
  
  def find_barcode(model, id)
    model.constantize.find(id).barcode_key
  end

  def barcode_format(str_prefix, pad_len, sstring)
    return(str_prefix + "%0#{pad_len}d" % sstring.to_i)
  end

  def compound_string_params(str_prefix, pad_len, compound_string)
    convert_with_prefix = (str_prefix.blank? && pad_len.nil? ? false : true)
    compound_string.chomp!
    str_split_all = compound_string.split(",")
    str_vals = []; str_ranges = []; error = [];

    for str_val in str_split_all
      str_val = str_val.to_s.delete(' ')

      if convert_with_prefix  # reformat/add prefix and push to array
        case str_val
          when /^(\d+)$/ # digits only
            str_vals.push(barcode_format(str_prefix, pad_len, str_val))
          when /^(\d+)\-(\d+)$/ # has range of digits
            str_ranges.push([barcode_format(str_prefix, pad_len, $1), barcode_format(str_prefix, pad_len, $2)])
          else error << str_val + ' is unexpected value'
        end # case

      else
        case str_val
          when /^(\w+)(\.*)(\w+)$/ #alphanumeric only (not a range)
            str_vals.push(str_val)
          when /^(\d+)-(\d+)$/ #numeric range, convert to integer so that SQL search will work correctly
            str_ranges.push([$1.to_i, $2.to_i])
          when /^(\w+)-(\w+)$/ #alphanumeric range, leave as is
            str_ranges.push([$1, $2])
          else  error << str_val + ' is unexpected value'
        end #case
      end #if convert_with_prefix
    end # for

    return str_vals, str_ranges, error
  end

  def email_value(email_hash, email_type, deliver_site)
    site_and_type = [deliver_site.downcase, email_type].join('_')
    return (email_hash[site_and_type.to_sym].nil? ? email_hash[email_type.to_sym] : email_hash[site_and_type.to_sym])
  end

  def extract_sheet(temp_fn)
    # Ruby file upload puts file into a temp dir with temp name which does not include file extension
    # RubyXL gem requires Excel file to have .xls or .xlsx file extension, so need to add it
    temp_fn_xlsx = temp_fn + '.xlsx'
    FileUtils.copy(temp_fn, temp_fn_xlsx)
    lib_workbook = RubyXL::Parser.parse(temp_fn_xlsx)
    return lib_workbook[0].extract_data
  end

  protected
  def set_current_user
    @user = User.find_by_id(session[:user])
    if @user
      User.current_user = @user
    end
  end
  
  def log_user_action
    user_login = (User.current_user.nil? ? 'nil' : User.current_user.login)
    logger.info("<**User:  #{user_login} **> Controller/Action: #{self.controller_name}/#{self.action_name}" +
                  " IP: " + request.remote_ip + " Date/Time: " + Time.now.strftime("%Y-%m-%d %H:%M:%S"))
    UserLog.add_entry(self, User.current_user, request.remote_ip)
  end

  # Ajax related functions
  # put flash messages into the headers for use in Ajax transport
  def flash_to_headers
    return unless request.xhr?
    flash_json = Hash[flash.map {|k,v| [k,ERB::Util.h(v)] }].to_json
    response.headers['X-Flash-Messages'] = flash_json
    flash.discard
  end

  # can be called generically on a record create error
  def create_error(instance)
    server_error(action_error_msg(:create, instance))
  end

  # can be called generically on a record update error
  def update_error(instance)
    server_error(action_error_msg(:update, instance))
  end

  def action_error_msg(action, instance)
    inst_errors = instance.errors.full_messages.join("; ")
    emsg = "ERROR: #{self.class}: #{action}: #{instance.class}: #{inst_errors}"
#logger.debug "action_error: #{instance.inspect}"
    return emsg
  end

  def instance_errors(instance)
    instance.errors.full_messages.join("; ")
  end

  def server_error(message)
    generic_error(:internal_server_error, message)
  end

  def bad_request_error(message)
    generic_error(:bad_request, message)
  end

  def forbidden_error(message)
    generic_error(:forbidden, message)
  end

  def generic_error(status, message)
    logger.debug "#{self.class}: #{status}: " + message
    render :inline => message, :status => status
  end
  
end
