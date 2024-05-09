module CategoryValues
  extend ActiveSupport::Concern

  # The methods in this file have names constructed from a
  # model.name.underscore + a suffix which is either: "_values" or "_mapped_values"
  #
  # values methods return a hash where the keys are attribute names and
  # values are an array of allowable values for that attribute
  #
  # mapped_values methods return a hash where the keys are attribute names and
  # values are 2 element arrays where the first element is the set of strings
  # that are acceptable aliases in the input for the value in the second element

  def patient_values
    category_values_for(['race', 'ethnicity', 'organism'])
  end

  def patient_mapped_values
    {
    'gender' => [
        [['Male', 'male', 'M'], 'M'],
        [['Female', 'female', 'F'], 'F'],
        [['Unknown', 'unknown', 'U'], 'U']
      ]
    }
  end

  def sample_characteristic_mapped_values
    mapped = {}
    cpa = ConsentProtocol.populate_dropdown.to_a
    mapped['consent_protocol_id'] = []
    cpa.each do |cp|
      mapped['consent_protocol_id'] << [[cp.consent_nr, cp.consent_abbrev, cp.consent_name], cp.id]
    end
    return mapped
  end

  def sample_characteristic_values
    category_values_for(['race', 'ethnicity', 'organism', ['clinic', 'clinic_or_location']])
  end

  def sample_values
    category_values_for(['tumor_normal', ['source tissue', 'sample_tissue'],
      ['sample type', 'sample_type'], ['tissue preservation', 'tissue_preservation'],
      ['sample unit', 'sample_container'], ['vial type', 'vial_type'], ['unit of measure', 'amount_uom']
    ])
  end

  def sample_storage_container_values
    #category_values_for([['container', 'container_type']])
    return {:container_type => StorageType.pluck(:container_type),
            :container_name => StorageContainer.pluck(:container_name).uniq}
  end

  def sample_storage_container_mapped_values
    mapped = {'freezer_location_id' => []}
    fla = FreezerLocation.list_all_by_room.to_a
    fla.each do |fl|
      mapped['freezer_location_id'] << [[fl.room_nr + (fl.freezer_nr.blank? ? "" : ('/'+fl.freezer_nr))], fl.id]
    end
    return mapped
  end

  def processed_sample_values
    category_values_for([['extraction type', 'extraction_type'],
      'support', ['elution buffer', 'elution_buffer'], ['vial volume', 'vial']
    ])
  end

  def processed_sample_mapped_values
    mapped = {}
    pa = Protocol.find_for_protocol_type('E').to_a
    mapped['protocol_id'] = []
    pa.each do |p|
      mapped['protocol_id'] << [[p.protocol_name, p.protocol_abbrev ], p.id]
    end
    return mapped
  end

  def seq_lib_values
    values = {'oligo_pool' => Pool.pluck(:tube_label)}
  end

  def seq_lib_mapped_values
    mapped = {'protocol_id' => [], 'adapter_id' => []}
    pa = Protocol.find_for_protocol_type('L').to_a
    pa.each do |p|
      mapped['protocol_id'] << [[p.protocol_name, p.protocol_abbrev], p.id]
    end
    adapters = Adapter.all.to_a
    mapped['adapter_id'] = adapters.map{|a| [[a.runtype_adapter], a.id]}
    return mapped
  end

  def lib_sample_values
    category_values_for([['quantitation', 'quantitation_method']])
  end

  # return a hash where keys are the attributes passed in as an Array
  # and values are arrays of acceptable values
  # the attributes Array may contain either:
  #   - an attribute name that is also used for the category query
  #   - an Array where the first element is a category and the second is the related attribute
  #     (this is necessary when category names don't match the attribute name)
  def category_values_for(attributes)
    values = {}
    attributes.each do |attr|
      if attr.is_a?(Array)
        category = attr[0]
        attribute = attr[1]
      else
        category = attribute = attr
      end
      values[attribute] = []
      Category.populate_dropdown_for_category(category).to_a.each {|cv| values[attribute] << cv.c_value }
    end
    return values
  end

  # given a mapped_value hash return:
  #   - the mapped value if present
  #   - nil if the name is not found
  #   - false if name is found, but there is no mapping for the value
  def get_mapped_value(mapped_values, name, value)
    maps = mapped_values[name]
#logger.debug "get_mapped_value: name: #{name} maps: #{maps}" 
    return nil if maps.nil?
    maps.each do |m|
      # allow match on aliases and the mapped to value
      if m[0].include?(value) || m[1] == value
#logger.debug "get_mapped_value: value: #{value} map to: #{m[1]}"
        return m[1]
      end
    end
    return false
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

end
