# == Schema Information
#
# Table name: protocols
#
#  id               :integer          not null, primary key
#  protocol_name    :string(50)
#  protocol_abbrev  :string(25)
#  protocol_version :string(10)
#  protocol_type    :string(1)
#  protocol_code    :string(3)
#  reference        :string(100)
#  comments         :string(255)
#  created_at       :datetime
#  updated_at       :timestamp        not null
#

class Protocol < ApplicationRecord
  PROTOCOL_TYPES      = {'Extraction' => 'E', 'Library Prep' => 'L', 'Molecular Assay' => 'M',
                         'Imaging' => 'I'}
  PROTOCOL_TYPE_NAMES = PROTOCOL_TYPES.invert
  
  validates_presence_of :protocol_code, :if => Proc.new{|p| %w[M I].include?(p.protocol_type)},
                        :message => 'must be supplied for molecular and imaging assays'
  validates :protocol_code, length: {is: 3}, :if => Proc.new{|p| p.protocol_type == "I"}

  def self.find_for_protocol_type(protocol_type)
    protocol_array = [*protocol_type]
    self.where('protocol_type IN (?)', protocol_array).order(:protocol_name).all
    #self.find(:all, :conditions => ['protocol_type IN (?)', protocol_array],
    #                :order      => 'protocol_name')
  end
  
  def name_ver
    [protocol_name, protocol_version].join('/')
  end

  def short_name
    (protocol_abbrev.blank? ? protocol_name[0..15] : protocol_abbrev)
  end
  
  def molecule_type
    if protocol_type != 'M'
      return nil
    else
      return (protocol_name.include?('Expression') ? 'R' : 'D')
    end
  end

end
