class CompoundStringValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    if options.key?(:datatype) and options[:datatype] == 'numeric'
      unless value =~ /\A(\d+\s?[-,]?\s?)*\d+\z/
        record.errors.add(attribute, "must be digits, comma-separated or valid ranges only")
      end
    elsif options.key?(:datatype) and options[:datatype] == 'alpha_dot_numeric'
      unless value =~ /\A(\w+\s?[-,]?\s?)*\w+\z/ or value =~ /\A\w+\.?\w+\z/
        record.errors.add(attribute, "must be alphanumeric, comma-separated or valid ranges only")
      end
    else #default to standard alphanumeric
      unless value =~ /\A(\w+\s?[-,]?\s?)*\w+\z/
        record.errors.add(attribute, "must be alphanumeric, comma-separated or valid ranges only")
      end
    end
  end
end
