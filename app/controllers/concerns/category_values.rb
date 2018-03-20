module CategoryValues
  extend ActiveSupport::Concern

  # The methods in this file have names constructed from a
  # modele.name.underscore + a suffix which is either: "_values" or "_mapped_values"  
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
        [['Female', 'female', 'F'], 'F']
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
    category_values_for([['container', 'container_type']])
  end

  def sample_storage_container_mapped_values
    mapped = {}
    fla = FreezerLocation.list_all_by_room.to_a
    mapped['freezer_location_id'] = []
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
      if m[0].include?(value)
#logger.debug "get_mapped_value: value: #{value} map to: #{m[1]}"
        return m[1]
      end
    end
    return false
  end

end
