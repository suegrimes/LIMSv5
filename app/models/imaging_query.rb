# == Schema Information
#
# Table name: imaging_queries
#  barcode_string      :string
#  protocol_id         :string
#  owner               :string
#  from_date           :date
#  to_date             :date
#  updated_by          :integer
#

class ImagingQuery
  include ActiveModel::Model

  attr_accessor :slide_nr_string, :owner, :protocol_id, :from_date, :to_date, :updated_by

  validates_date :to_date, :from_date, :allow_blank => true
  validates :slide_nr_string, compound_string: {:datatype => 'alpha_dot_numeric'}, :allow_blank => true

  STD_FIELDS = {'imaging_slides' => %w(protocol_id updated_by)}

  COMBO_FIELDS = {:slide_nr_string => {:sql_attr => ['imaging_slides.slide_number']}}

  QUERY_FLDS = {'standard' => STD_FIELDS, 'multi_range' => COMBO_FIELDS, 'search' => {}}
end
