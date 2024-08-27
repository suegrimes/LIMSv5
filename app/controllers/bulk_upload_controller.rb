class BulkUploadController < ApplicationController
  include XlsProcessing, XlsHdrValidation, BulkUploadCols, CategoryValues, FkFinders
  layout 'main/main'

  before_action :set_variables
  def set_variables
  # keys are the normalized expected sheet names
  # values have the model name(s) and dropdown method prefix
  # only 2 models may be listed for a sheet and it implies
  # the first model accepts_nested_attributes_for the second
    @sheet_info = {
      patients: { models: [Patient] },
      sample_acquisition: { models: [SampleCharacteristic]},
      #samples: { models: [SampleCharacteristic, Sample] },
      samples: { models: [Sample, SampleStorageContainer] },
      sample_locs: { models: [SampleStorageContainer] },
      dissections: { models: [Sample, SampleStorageContainer] },
      extractions: { models: [ProcessedSample, SampleStorageContainer] },
      seq_libs: { models: [SeqLib, LibSample] },
      imaging_slides: { models: [ImagingSlide, SlideSample] }
    }
  end

  def new
    @upload_ok = params[:upload_ok]
    @accept_suffixes = ".ods,.xlsx,.csv"
  end

  def create
    #deliberate_error_here

    @validation_passed = 'no'
    @file = params.permit(:file)[:file]

logger.debug "#{self.class}#create file.class: #{@file.class}"
    unless @file
      flash[:error] =  "No file specified"
      render action: :new
      return
    end

    # dry run option
    @action_type = params[:action_type]
logger.debug "@action_type: #{@action_type}"
    @dry_run = (@action_type[:dry_run] ? true : false)

=begin
# Use something like this section if saving the files is required
    # get an uploader
    @uploader = BulkUploader.new

    # remove an existing file with the same name
    @store_path = @uploader.store_path(@file.original_filename)
logger.debug "#{self.class}#create @store_path: #{@store_path}"
    if File.exist?(@store_path)
      File.delete(@store_path)
    end

    # store the file
    @uploader.store!(@file)
=end

    @ss = open_spreadsheet(@file)
    if @ss.nil?
      flash[:error] =  "Unknown file type for file: #{@file.original_filename}"
      render action: :new
      return
    end
logger.debug "#{self.class}#process_upload sheets: #{@ss.sheets}, expected: #{@sheet_info.keys}"

    # for testing only
    #@force_rollback = true
    # set if a Rollback was forced
    @rollback_forced = false

    # do validations on as many rows as possible, but do not save to the database
    # will still stop on header errors though

    # do all processing within a transaction so everything is rolled back on save error
    @errors = []
    ActiveRecord::Base.transaction do
      if !process_upload()
        # rollback all prior saves on any error
        raise ActiveRecord::Rollback
      end
      # helpful for testing
      if @force_rollback
        @rollback_forced = true
        raise ActiveRecord::Rollback
      end
    end

    if @rollback_forced
      flash[:notice] =  "Upload processing successful, but: ROLLBACK FORCED!"
      render :success
      return
    end

    if !@errors.empty?
      processing_text = (@dry_run ? 'Validation' : 'Upload')
      flash[:error] =  "#{processing_text} processing failed for file: #{@file.original_filename}"
      render :errors 
      return
    end

    if @dry_run
      @validation_passed = 'yes'
      flash[:notice] = "Validation successful for file: #{@file.original_filename}"
      render :new
    else
      flash[:notice] = "Upload successful for file: #{@file.original_filename}"
      render :success
    end
  end

  protected

  # process a spreadsheet opened by a Roo instance
  def process_upload()
    # Store sheet results data here:
    # header: array of normalized headers
    # saved_rows: array of saved rows
    # _refs: hash for an object to be referenced with model.name keys and header values
    # _ref_ids: hash with _ref header_name keys and maps of ref values to saved ids
    @sheet_results = {
      patients: { header: [], saved_rows: [], _refs: {}, _ref_ids: {} },
      sample_acquisition: { header: [], saved_rows: [], _refs: {}, _ref_ids: {} },
      samples: { header: [], saved_rows: [], _refs: {}, _ref_ids: {} },
      sample_locs: { header: [], saved_rows: [], _refs: {}, _ref_ids: {} },
      dissections: { header: [], saved_rows: [], _refs: {}, _ref_ids: {} },
      extractions: { header: [], saved_rows: [], _refs: {}, _ref_ids: {} },
      seq_libs: { header: [], saved_rows: [], _refs: {}, _ref_ids: {} },
      imaging_slides: { header: [], saved_rows: [], _refs: {}, _ref_ids: {} }
    }
    # get the sheets to process mapped to the sheet index (0 based)
    @sheet_map = sheets_to_process(@ss.sheets, @sheet_info.keys)
logger.debug "#{self.class}#process_upload sheet_map: #{@sheet_map}"

    # process the sheets in the order defined in the @sheet_info
    # valid sheets found
    valid_sheets = 0
    got_error = false
    @sheet_info.each do |sheet_name, sheet_models|
      next unless @sheet_map.has_key?(sheet_name)
      valid_sheets += 1
      set_sheet_index(@sheet_map[sheet_name])

      # authorize create on the model
      sheet_models[:models].each do |model|
         authorize! :create, model
      end

      # prepare the sheet attribute values for saving
      if !process_sheet(sheet_name, sheet_models[:models])
        got_error = true
        return false unless @dry_run
      end
    end
    unless valid_sheets > 0
      error("All", "", "No valid sheet names found")
      return false
    end

    # all done
    return false if got_error
    return true
  end

  # process a sheet given its sheet key AR model, Roo spreadsheet and sheet index
  def process_sheet(sheet_name, models)
logger.debug "process_sheet(#{sheet_name}, #{models.inspect})"
    @ss.default_sheet = cur_sheet_name
    header = get_header()
logger.debug "raw header: #{header}"
    # get all model(s) columns and category values defined for attributes
    models_columns = get_attributes(models)
logger.debug "model columns: #{models_columns}"
    resolve_ambiguous_headers(models_columns, header)

    return false if !verify_header_names(sheet_name, models_columns, header)
    
    # prepare each row for saving
    got_error = false
    (2..@ss.last_row).each do |rn|
      if !process_row(sheet_name, models_columns, get_row(rn), rn)
        got_error = true
        # keep processing to get as many errors as possible, if it is a dry run
        return false unless @dry_run
      end
    end

    return false if got_error
    return true
  end

  # process a row with column and header info
  def process_row(key, models_columns, row, rn)
#logger.debug "process_row rn: #{rn} row: #{row}"

    # for each model, get the row value for each header
    # if nil, we ignore
    # if NULL we change to nil
    # then check if there are required values specified for it
    attributes = []  # hashes indexed by model index
    saved_row = []   # array format of values for later display
    ref_def_keys = [] # _ref definition key value
    models_columns.each_with_index do |mc, mi|
      attributes[mi] = {}  # put attributes to save here
      mc[:headers].each do |h|
        name = h[0]	# attribute name
        ci = h[1]	# column index 0 based
        value = row[ci] # value in row
#logger.debug "value: #{value}"
        # Allow quoted "<values>" so numerals can be input as strings; remove quotes here
        value = unquote(value)

        # we ignore nil values in the spreadsheet
        if value.nil?
          save_row_value(mi, ci, name, "", saved_row)
          next
        end

        # check for "_ref" definition column
        if is_ref_def_header(name, mc[:model])
          # stash header name, ref key and model index so we can stored saved id below
          ref_def_keys << [name, value, mi]
          next
        end

        # check for ".ref" referencing column
        if is_ref_ref_header(name, mc)
          # get the saved definition header
          def_header = ref_to_def_header(name)
          if def_header.nil?
            error(cur_sheet_name, rn, "Matching reference header #{def_header} for referencing header #{name} not found")
            next
          end
          # get the stored id if there
          # if a dry run it will not be there, so no error in that case
          id = get_id_from_ref(def_header, value)
          if id.nil? && !@dry_run
            error(cur_sheet_name, rn, "Could not find saved id from reference column #{name} value #{value}")
          else
            attributes[mi][ref_ref_real_attr(name)] = id
            save_row_value(mi, ci, name, id, saved_row)
          end
          next
        end

        # check enumerated values
        if mc[:allowed_values][name]
          if mc[:allowed_values][name].include?(value)
            attributes[mi][name] = value
            save_row_value(mi, ci, name, value, saved_row)
          else
            error(cur_sheet_name, rn, "Value '#{value}' in column #{column_id(ci)} not allowed for #{mc[:model].name}.#{name}")
          end
          next
        end

        # check aliases for value
        ret_val = get_mapped_value(mc[:mapped_values], name, value)
        if !ret_val.nil?
          if ret_val == false
            error(cur_sheet_name, rn, "Value '#{value}' in column #{column_id(ci)} not allowed for #{mc[:model].name}.#{name}")
          else
            attributes[mi][name] = ret_val
            save_row_value(mi, ci, name, ret_val, saved_row)
          end
          next
        end

        # check for fk_finder and get id from finder
        if mc[:fk_finders]
          method = mc[:fk_finders][name]
          if method
            id = self.send(method, value)
            attributes[mi][fk_finder_real_attr(name)] = id
            save_row_value(mi, ci, name, id, saved_row)
            next
          end
        end

        # NULL means put a NULL in the DB, set to nil to do this
        if value == "NULL"
          attributes[mi][name] = nil
          save_row_value(mi, ci, name, "nil", saved_row)
          next
        end

        # there is no restriction or special handling defined on the value so use it
        # assign the value to the attribute
        attributes[mi][name] = value
        save_row_value(mi, ci, name, value, saved_row)
      end
    end

    if !@errors.empty?
      return false unless @dry_run
    end

logger.debug "process_row to instantiate: #{attributes.inspect}"

    instance = instantiate_models(rn, models_columns, attributes)
    # ignore if no attribute, empty row for example
    return true if instance.nil?
    # error return
    return false if !instance
    # don't save if dry_run
    return true if @dry_run

    # save the instance if not a dry run
    begin
      instance.save!
    rescue Exception => e
      error(cur_sheet_name, rn, "Save caused exception: #{$!}")
      raise ActiveRecord::Rollback
    else
      # save reference to the instance id if there is a reference key defined
      # this is the instance id if the model is the primary model
      # otherwise we have to get the last instance id from the database
      # when saved with one of the build constructs
      ref_ids = @sheet_results[key][:_ref_ids]
      ref_def_keys.each do |ref_def|
        header_name = ref_def[0]
        ref_key = ref_def[1]
        mi = ref_def[2]
        ref_id = nil
        if mi == 0
          ref_id = instance.id
        else
#logger.debug "Call get_last_created_id header_name: #{header_name} ref_key: #{ref_key} mi: #{mi}"
          ref_id = get_last_created_id(models_columns[mi][:model])
        end
        ref_ids[header_name][ref_key] = ref_id
#logger.debug "Saved _ref header: #{header_name} key: #{ref_key} id: #{ref_id}"
      end

      s_row = final_saved_row(instance.id, saved_row)
logger.debug "Saved Row: key: #{key} row: #{s_row}"
      @sheet_results[key][:saved_rows] << s_row
    end

    return true
  end

  # inputs should be either a 1 or 2 element array
  # return nil if there are no attributes to save; return false on failure
  def instantiate_models(rn, models_columns, attributes)
    raise "Maximum of 2 models is exceeded" if models_columns.size > 2

    # don't instantiate if there are no attributaes
    if attributes[0].empty?
      if attributes[1].nil? || attributes[1].empty?
        return nil
      else
        error(cur_sheet_name, rn, "Cannot instantiate subordinate model when main model is empty")
        return false
      end
    else
      # instantiate the first model
      model = models_columns[0][:model]
      instance = model.new(attributes[0])
      unless instance.valid?
        instance.errors.full_messages.each do |emsg|
          error(cur_sheet_name, rn, emsg)
        end
        return false
      end
      if models_columns.size == 1
        return instance
      end
    end

    if !attributes[1].nil? && !attributes[1].empty?
      # build the second model
      build_subordinate_model(instance, models_columns[1][:model], attributes[1])
      unless instance.valid?
        instance.errors.full_messages.each do |emsg|
          error(cur_sheet_name, rn, emsg)
        end
        return false
      end
    end

    return instance
  end

  def build_subordinate_model(instance, sub_model, attributes)
    table_sym = sub_model.name.tableize.to_sym
    if instance.respond_to?(table_sym)
      instance.send(table_sym).build(attributes)
    else
      build_method = ("build_" + sub_model.name.underscore).to_sym
      instance.send(build_method, attributes)
    end
  end

  def get_last_created_id(model)
    model.all.order("created_at DESC").first.id
  end

  # strip the quotes off of a quoted string
  def unquote(value)
    return value unless value.is_a?(String)
    if value[0] == '"' && value[-1] == '"'
      return value[1..(value.size-2)]
    end
    return value
  end

  # saves a row cell value for later display in the saved report page
  # model_index is the index of the model the value belongs to,
  # name is the normalized column name, value the value saved,
  # name_col an array of associations between names and header columns
  # and saved_row is an array in which to place the values
  def save_row_value(model_index, col_index, name, value, saved_row)
    saved_row[col_index] = [value, model_index]
  end

  def final_saved_row(id, saved_row)
    [[id, 0]] + saved_row.compact
  end

  # log an error
  def error(sheet_name, row_num, message)
    @errors << [sheet_name, row_num, message]
logger.debug "Error: #{@errors.last}"
  end

end
