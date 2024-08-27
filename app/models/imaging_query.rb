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

  attr_accessor :slide_nr_string, :run_nr_string, :owner, :protocol_id, :from_date, :to_date,
                :updated_by

  validates_date :to_date, :from_date, :allow_blank => true
  validates :slide_nr_string, compound_string: {:datatype => 'alpha_dot_numeric'}, :allow_blank => true
  validates :run_nr_string, compound_string: {:datatype => 'numeric'}, :allow_blank => true

  STD_FIELDS = {'imaging_runs' => %w(protocol_id),
                'imaging_slides' => %w(owner)}

  COMBO_FIELDS = {:slide_nr_string => {:sql_attr => ['imaging_slides.slide_number']},
                  :run_nr_string => {:sql_attr => ['CAST(SUBSTR(imaging_runs.imaging_key,14,19) AS UNSIGNED)']}}

  QUERY_FLDS = {'standard' => STD_FIELDS, 'multi_range' => COMBO_FIELDS, 'search' => {}}
end
