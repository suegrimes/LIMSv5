class BulkUploadController < ApplicationController
  include CategoryValues
  include FkFinders

  layout 'main/main'

  def new
    @accept_suffixes = ".ods,.xlsx,.csv"
  end

  def create
    # permit file
    @file = params.permit(:file)[:file]
logger.debug "#{self.class}#create file.class: #{@file.class}"
    unless @file
      flash[:error] =  "No file specified"
      render action: :new
      return
    end

    # dry run option
    @options = params.permit(:options)[:options]
logger.debug "@options: #{@options}"
    @dry_run = false
    if @options == "dry_run" 
      @dry_run = true
    end
logger.debug "@dry_run: #{@dry_run}"

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
logger.debug "#{self.class}#process_upload ss.class: #{@ss.class}"
    if @ss.nil?
      flash[:error] =  "Unknown file type for file: #{@file.original_filename}"
      render action: :new
      return
    end
logger.debug "#{self.class}#process_upload sheets: #{@ss.sheets}"

    # for testing only
    #@force_rollback = true
    # set if a Rollback was forced
    @rollback_forced = false

    # do validations on as many rows as possible, but do not save to the database
    # will still stop on header errors though

    # do all processing within a transaction so everything
    # gets rolled back on a save error
    @errors = []
    ActiveRecord::Base.transaction do
      if !process_upload()
        # rollback all prior saves on any error
        raise ActiveRecord::Rollback
      end
      # helpfull for testing
      if @force_rollback
        @rollback_forced = true
        raise ActiveRecord::Rollback
      end
    end

    if @rollback_forced
      flash[:notice] =  "Upload processing successfull, but: ROLLBACK FORCED!"
      render :success
      return
    end

    if !@errors.empty?
      flash[:error] =  "Upload processing failed"
      render :errors 
      return
    end

    if @dry_run
      flash[:notice] = "Dry run validations for file: #{@file.original_filename} were successfully"
      render :new
    else
      flash[:notice] = "Upload has been processed successfully"
      render :success
    end
  end

  protected

  # process a spreadsheet opened by a Roo instance
  def process_upload()
    
    # keys are the normalized expected sheet names
    # values have the model name(s) and dropdown method prefix
    # only 2 models may be listed for a sheet and it implies
    # the first mocel accepts_nested_attributes_for the second
    @sheet_info = {
      patients: { models: [Patient] },
      samples: { models: [SampleCharacteristic, Sample] },
      samplelocs: { models: [SampleStorageContainer] },
      dissections: { models: [Sample, SampleStorageContainer] },
      extractions: { models: [ProcessedSample, SampleStorageContainer] }
    }
    # Store sheet results data here:
    # header: array of normalized headers
    # saved_rows: array of saved rows
    # _refs: hash for an object to be referenced with model.name keys and header values
    # _ref_ids: hash with _ref header_name keys and maps of ref values to saved ids
    @sheet_results = {
      patients: { header: [], saved_rows: [], _refs: {}, _ref_ids: {} },
      samples: { header: [], saved_rows: [], _refs: {}, _ref_ids: {} },
      samplelocs: { header: [], saved_rows: [], _refs: {}, _ref_ids: {} },
      dissections: { header: [], saved_rows: [], _refs: {}, _ref_ids: {} },
      extractions: { header: [], saved_rows: [], _refs: {}, _ref_ids: {} }
    }
    # get the sheets to process mapped to the sheet index (0 based)
    @sheet_map = sheets_to_process(@ss.sheets, @sheet_info.keys)
logger.debug "#{self.class}#process_upload sheet_map: #{@sheet_map}"

    # process the sheets in the order defined in the @sheet_info
    # valid sheets found
    valid_sheets = 0
    got_error = false
    @sheet_info.each do |key, info|
      next unless @sheet_map.has_key?(key)
      valid_sheets += 1
      set_sheet_index(@sheet_map[key])
#logger.debug "#{self.class}#process_upload sheet index: #{get_sheet_index}"

      # authorize create on the model
      info[:models].each do |model|
         authorize! :create, model
      end

      # prepare the sheet attribute values for saving
      if !process_sheet(key, info[:models])
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

  # return hash with sheet name symbols as keys and sheet indexes as values
  def sheets_to_process(given, expected)
    map = {}
    given.each_with_index do |sh, i|
      cl = sh.downcase.to_sym
      if expected.include?(cl)
        map[cl] = i
      end
    end
    return map
  end

  # process a sheet given its sheet key AR model, Roo spreadsheet and sheet index
  def process_sheet(key, models)
logger.debug "process_sheet(#{key}, #{models.inspect})"
    # set the default sheet
    @ss.default_sheet = cur_sheet_name
    # get the header as an array
    header = get_header()
logger.debug "raw header: #{header}"
    # get all model(s) columns and category values defined for attributes
    models_columns = []
    models.each do |model|
      h = {}
      h[:model] = model
      h[:allowed_cols] = model.column_names - ["updated_by", "created_at", "updated_at"]
      content_cols = model.content_columns.map {|cc| cc.name}
      special_cols = model.column_names - content_cols
      # regular content columns for this model
      #content_cols = content_cols - ["updated_by", "created_at", "updated_at"]
      # foreign key columns
      h[:fk_cols] = special_cols - ["id"]
      h[:allowed_values] = allowed_values(model)
      h[:mapped_values] = mapped_values(model)
      h[:fk_finders] = {} # place to put fk finders mao
      h[:headers] = []  # place to put verified header names
      h[:dups] = {}     # place to put dup indexes
#logger.debug "models_columns for model: #{model.name}: #{h}"
      models_columns << h
    end

    resolve_amgiguous_headers(models_columns, header)
#logger.debug "models_columns[0][:dups]: #{models_columns[0][:dups]}"
#logger.debug "models_columns[1][:dups]: #{models_columns[1][:dups]}"

    return false if !verify_header_names(key, models_columns, header)
    
    # prepare each row for saving
    got_error = false
    (2..@ss.last_row).each do |rn|
      if !process_row(key, models_columns, get_row(rn), rn)
        got_error = true
        # keep processing to get as many errors as possible, if it is a dry run
        return false unless @dry_run
      end
    end

    return false if got_error
    return true
  end

  # verify the header names and add normalized names with row index
  # into the models_columns structure
  def verify_header_names(key, models_columns, header)
    normalized_header = []
    
    got_error = false
    header.each_with_index do |h, i|
logger.debug "verify header: #{h}"
      if h == "id"
        error(cur_sheet_name, 1, "Header column #{h} not allowed, update not supported yet")
        next
      end

      if h.nil?	# ignore mepty header
        normalized_header[i] = nil
        next
      else
        normalized_header[i] = normalize_header(h)
      end

      # see if heading is an attribute name, pseudo attribute,
      # fk_finder, refrerence id or reference to one
      # if so, put it in the models_columns :headers hash with header index
      header_is_known = false
      show_header_in_results = true
      models_columns.each_with_index do |mc, ci|

        # check for ambiguous header name
        if mc[:dups].has_key?(normalized_header[i])
#logger.debug "verify_header:  ci: #{ci} found ambiguous header: #{normalized_header[i]}"
          dup_index = mc[:dups][normalized_header[i]]
#logger.debug "verify_header: ci: #{ci} dup_index: #{dup_index}"
          next if dup_index.nil?
          if dup_index == i
            header_is_known = true
            mc[:headers] << [normalized_header[i], i]  # 0 based index
#logger.debug "header #{h} i: #{i} ci: #{ci} is_ambiguous_model_column mc[:headers]: #{mc[:headers]}"
            break
          end
          next
        end

        if mc[:allowed_cols].include?(normalized_header[i])
          header_is_known = true
          mc[:headers] << [normalized_header[i], i]  # 0 based index
#logger.debug "header #{h} is_model_column mc[:headers]: #{mc[:headers]}"
          break
        end

        if is_pseudo_attr(mc[:model], normalized_header[i])
          header_is_known = true
          mc[:headers] << [normalized_header[i], i]
#logger.debug "header #{h} is_model_pseudo_attr mc[:headers]: #{mc[:headers]}"
          break
        end

        if is_fk_finder_header(normalized_header[i], mc)
          header_is_known = true
          mc[:headers] << [normalized_header[i], i]
#logger.debug "header #{h} is_fk_finder mc[:headers]: #{mc[:headers]}"
          break
        end

        if is_ref_def_header(normalized_header[i], mc[:model])
          header_is_known = true
          show_header_in_results = false
          @sheet_results[key][:_refs][(mc[:model]).name] = normalized_header[i]
          @sheet_results[key][:_ref_ids][normalized_header[i]] = {}
          mc[:headers] << [normalized_header[i], i]
#logger.debug "header #{h} is_ref_def mc[:headers]: #{mc[:headers]}"
          break
        end

        if is_ref_ref_header(normalized_header[i], mc)
          header_is_known = true
          mc[:headers] << [normalized_header[i], i]
#logger.debug "header #{h} is_ref_ref mc[:headers]: #{mc[:headers]}"
          break
        end
      end
      if !show_header_in_results
        normalized_header.delete_at(i)
      end
      next if header_is_known

      # error if not recognized, but continue to gather all errors
      got_error = true
      error(cur_sheet_name, 1, "Header name '#{h}' is not recognized for model(s) #{model_column_names(models_columns)}")
    end
    return false if got_error

#logger.debug "mc[0][:headers]: #{models_columns[0][:headers]}"
#logger.debug "mc[1][:headers]: #{models_columns[1][:headers]}"

    @sheet_results[key][:header] = ["id"] + normalized_header.compact
logger.debug "Normalized header: key: #{key} #{@sheet_results[key][:header]}"
    return true
  end

  # return a hash of allowed category values keyed by attribute names
  def allowed_values(model)
    cv_method = (model.name.underscore + "_values").to_sym
    return {} if !self.respond_to?(cv_method)
    self.send(cv_method)
  end

  # return a map of aliases related to a value keyed by attribute names
  def mapped_values(model)
    cv_method = (model.name.underscore + "_mapped_values").to_sym
    return {} if !self.respond_to?(cv_method)
    self.send(cv_method)
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
        # Allow quoted "<values>" so numerals can be input as strings
        # remove quotes here
        value = unquote(value)

        # we ignore nil values in the spreadsheet
        if value.nil?
          save_row_value(mi, ci, name, "", saved_row)
          next
        end

        # check for "_ref" definition column
        if is_ref_def_header(name, mc[:model])
          # stash header name, ref key and model index
          # so we can store the saved id below
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

  # inputs should both be either a 1 or 2 element array
  # return nil if there are no attributes to save
  # return false on failure
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

  # true if the name is a pseudo attribute of the model
  def is_pseudo_attr(model, name)
    # see if there is a method to assign to it
    model.instance_methods.include? (name + "=").to_sym
  end

  # set the default sheet index
  def set_sheet_index(index)
    @sh_index = index
  end

  # get the default sheet index
  def get_sheet_index()
    @sh_index
  end

  # return an array of column header names
  # we assume headers are in the first row (count starting from 1)
  # this should work wether the default sheet is set or not
  def get_header
    @ss.sheet(@sh_index).row(1)
  end

  def cur_sheet_name
    @ss.sheets[@sh_index]
  end

  def get_row(row_index)
    @ss.sheet(@sh_index).row(row_index)
  end

  # if spreadsheet return a capitalized column label
  def column_id(col_index)
    return col_index if @input_type == "csv"
    if col_index < 26
      return (('A'.ord) + col_index).chr
    else
      x = (col_index - 1) / 26
      y = col_index % 26
      a = (('A'.ord) + x).chr
      b = (('A'.ord) + y).chr
      return a + b
    end
  end

  # use Roo gem to open a csv, xls or xlsx file
  def open_spreadsheet(file)
logger.debug "open_spreadsheet: file.tempfile: #{file.tempfile}"
    ss = nil
    case File.extname(file.original_filename)
    when '.csv'
      ss = Roo::Csv.new(file.tempfile)
      @input_type = "csv"
    # for some reason Roo fails to open an IO opbect but can use the file path
    when '.ods'
      ss = Roo::OpenOffice.new(file.tempfile.path)
      @input_type = "ods"
    when '.xlsx'
      ss = Roo::Excelx.new(file.tempfile)
      @input_type = "xlsx"
    else nil
    end
    return ss
  end

  # make everything lower case and replace spaces with underbar
  def normalize_header(header)
    return nil if header.nil?
    header.downcase.split.join("_")
  end

  # return strign with model names from models_columns structure for error report 
  def model_column_names(models_columns)
    model_names = ""
    models_columns.each do |mc|
      if model_names.empty?
        model_names = mc[:model].name 
      else
        model_names = model_names + ', ' + mc[:model].name 
      end
    end
    return model_names
  end

  # strip the quotes off of a quoted string
  def unquote(value)
    return value unless value.is_a?(String)
    if value[0] == '"' && value[-1] == '"'
      return value[1..(value.size-2)]
    end
    return value
  end

  # is this column a valid foreign key finder
  def is_fk_finder_header(name, model_column)
    ns = name.split('.')
    return false unless (ns.size == 2)
    ref_field = ns.first
    key = ns.last
    return false unless model_column[:fk_cols].include?(ref_field)
    # get the referred to model name
    model_name =  ForeignKeyFieldToModels[ref_field]
    return false if model_name.nil?
    stn = model_name.tableize.singularize
    method = ('fk_find_' + stn + '_' + key).to_sym
#logger.debug "is_fk_finder_header: name: #{name} method: #{method}"
    if self.respond_to?(method)
      # store in the :fk_finders map for use during row processing
      # if not already there and return true
      if !model_column[:fk_finders].has_key?(name)
        model_column[:fk_finders][name] = method
      end
      return true
    end
    return false
  end

  # is this a column where reference ids are defined
  def is_ref_def_header(name, model)
    name == model.name.tableize.singularize + '_ref'
  end

  # is this a column where reference ids are referred to
  # name is normalized header and model_column is where the
  # header may appear
  def is_ref_ref_header(name, model_column)
    ns = name.split('.')
    return false unless (ns.size == 2 && ns.last == "ref")
    return true if model_column[:fk_cols].include?(ns.first)
    return false
  end

  # given a referencing header name, return the related
  # reference definition header name or nil if none found
  def ref_to_def_header(name)
    model_name = ForeignKeyFieldToModels[ref_ref_real_attr(name)]
    return nil if model_name.nil?
    @sheet_results.each do |sh, res|
      refs = res[:_refs]
      next if refs.nil?  # this shouldn't really happen
      def_header = refs[model_name]
      return def_header unless def_header.nil?
    end
    return nil
  end

  # given a reference definition header and a reference value
  # return the store id for it, or nil if not found or referenceable
  def get_id_from_ref(def_header, ref_key)
    @sheet_results.each do |sh, res|
      ref_ids = res[:_ref_ids]
      next if ref_ids.nil?  # this shouldn't really happen
      hdr_ids = ref_ids[def_header]
      next if hdr_ids.nil?
      id = hdr_ids[ref_key]
      return id unless id.nil?
    end
    return nil
  end

  # If there is the same attribute name in both models
  # resolve which model it/they should belong to.
  # If there are two instances, the first in the header should belong to
  # the first model and the 2nd to the 2nd model.
  # If there is only one instance in the header,
  # if it's position in the header is after any non-dup header
  # belonging to the 2nd model it is assigned to the 2nd model
  # else to the first model
  def resolve_amgiguous_headers(models_columns, raw_header)
    return if models_columns.size < 2
    m0_cols = models_columns[0][:allowed_cols] - ["id", "updated_by", "created_at", "updated_at"]
    m1_cols = models_columns[1][:allowed_cols] - ["id", "updated_by", "created_at", "updated_at"]
    dup_names = []
    m0_cols.each do |n1|
      m1_cols.each do |n2|
        if n1 == n2
          dup_names << n1
        end
      end
    end
#logger.debug "resolve_amgiguous_headers found dup_names: #{dup_names}"
    return if dup_names.empty?
    # normalize all headers
    header = raw_header.map {|h| normalize_header(h) }
    dup_names.each do |dn|
#logger.debug "resolve_amgiguous_headers handle dup_name: #{dn}"
      fi = li = nil
      # find first instance of the dup name in header
      header.each_with_index do |h, i|
        if dn == h
          fi = i
          break
        end
      end
#logger.debug "resolve_amgiguous_headers  dup_name: #{dn} first index: #{fi}"
      # next if the dup name is not used in the sheet
      next if fi.nil?
      # find last instance of the dup name in header
      header.reverse_each.with_index do |h, ri|
        if dn == h
          li = (header.size - 1) - ri
          break
        end
      end
#logger.debug "resolve_amgiguous_headers  dup_name: #{dn} last index: #{li}"
      if fi == li
        # one instance of dup name
        m1_no_dups = models_columns[1][:allowed_cols] - dup_names
        first_m1_index = nil
        header.each_with_index do |h, i|
          if m1_no_dups.include?(h)
            # we foud the first non-ambiguous header of 2nd model
            first_m1_index = i
            break
          end
        end
        if first_m1_index.nil? || fi < first_m1_index
          # assign to the 1st model
#logger.debug "resolve_amgiguous_headers  dup_name: #{dn} assign to first"
          models_columns[0][:dups][dn] = fi
          models_columns[1][:dups][dn] = nil
        else
          # assign to the 2nd model
#logger.debug "resolve_amgiguous_headers  dup_name: #{dn} assign to second"
          models_columns[0][:dups][dn] = nil
          models_columns[1][:dups][dn] = fi
        end
      else
#logger.debug "resolve_amgiguous_headers assign dup_name: #{dn} first index: #{fi} last index: #{li}"
        # two instances of dup name
        models_columns[0][:dups][dn] = fi
        models_columns[1][:dups][dn] = li
      end
    end
  end

  def ref_ref_real_attr(name)
    name.split('.').first
  end

  def get_last_created_id(model)
    model.all.order("created_at DESC").first.id
  end

  # log an error
  def error(sheet_name, row_num, message)
    @errors << [sheet_name, row_num, message]
logger.debug "Error: #{@errors.last}"
  end

end
