module XlsHdrValidation
  extend ActiveSupport::Concern

  # map foreign key fields to model names they reference
  ForeignKeyFieldToModels = {
      'patient_id' => 'Patient',
      'sample_id' => 'Sample',
      'source_sample_id' => 'Sample',
      'stored_sample_id' => 'Sample',
      'consent_protocol_id' => 'ConsentProtocol',
      'protocol_id' => 'Protocol'
  }

  # verify the header names and add normalized names with row index
def verify_header_names(key, models_columns, header)
  normalized_header = []

  got_error = false
  header.each_with_index do |h, i|
    logger.debug "verify header: #{h}"
    if h == "id"
      error(cur_sheet_name, 1, "Header column #{h} not allowed, update not supported yet")
      next
    end

    if h.nil?	# ignore empty header
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

# make everything lower case and replace spaces with underbar, remove last char '?' if exists
def normalize_header(header)
  return nil if header.nil?
  header.downcase.split.join("_").chomp('?')
end

# If there is the same attribute name in both models
# resolve which model it/they should belong to.
# If there are two instances, the first in the header should belong to
# the first model and the 2nd to the 2nd model.
# If there is only one instance in the header,
# if it's position in the header is after any non-dup header
# belonging to the 2nd model it is assigned to the 2nd model
# else to the first model
  def resolve_ambiguous_headers(models_columns, raw_header)
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
#logger.debug "resolve_ambiguous_headers found dup_names: #{dup_names}"
    return if dup_names.empty?
# normalize all headers
    header = raw_header.map {|h| normalize_header(h) }
    dup_names.each do |dn|
#logger.debug "resolve_ambiguous_headers handle dup_name: #{dn}"
      fi = li = nil
      # find first instance of the dup name in header
      header.each_with_index do |h, i|
        if dn == h
          fi = i
          break
        end
      end
      #logger.debug "resolve_ambiguous_headers  dup_name: #{dn} first index: #{fi}"
      # next if the dup name is not used in the sheet
      next if fi.nil?
      # find last instance of the dup name in header
      header.reverse_each.with_index do |h, ri|
        if dn == h
          li = (header.size - 1) - ri
          break
        end
      end
      #logger.debug "resolve_ambiguous_headers  dup_name: #{dn} last index: #{li}"
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
          #logger.debug "resolve_ambiguous_headers  dup_name: #{dn} assign to first"
          models_columns[0][:dups][dn] = fi
          models_columns[1][:dups][dn] = nil
        else
          # assign to the 2nd model
          #logger.debug "resolve_ambiguous_headers  dup_name: #{dn} assign to second"
          models_columns[0][:dups][dn] = nil
          models_columns[1][:dups][dn] = fi
        end
      else
#logger.debug "resolve_ambiguous_headers assign dup_name: #{dn} first index: #{fi} last index: #{li}"
# two instances of dup name
        models_columns[0][:dups][dn] = fi
        models_columns[1][:dups][dn] = li
      end
    end
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

# true if the name is a pseudo attribute of the model
  def is_pseudo_attr(model, name)
    # see if there is a method to assign to it
    model.instance_methods.include? (name + "=").to_sym
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

  def ref_ref_real_attr(name)
    name.split('.').first
  end


end
