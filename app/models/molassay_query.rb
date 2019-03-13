# == Schema Information
#
# Table name: molassay_queries
#
#  patient_id :string
#  from_date  :date
#  to_date    :date
#  owner      :string
#

class MolassayQuery
  include ActiveModel::Model

  attr_accessor :patient_string, :owner, :from_date, :to_date

  validates_date :to_date, :from_date, :allow_blank => true

  #validates_format_of :patient_id, :with => /\A[\d,\s]+\z/, :allow_blank => true, :message => "id must be an integer"
  validates_format_of :patient_string, :with => /\A[\d,\s]+\z/, :allow_blank => true, :message => "ids must be integer"
  validates_date :to_date, :from_date, :allow_blank => true

  STD_FIELDS = {'molecular_assays' => %w(owner)}
  COMBO_FIELDS = {:patient_string => {:sql_attr => ['processed_samples.patient_id']}}

  QUERY_FLDS = {'standard' => STD_FIELDS, 'multi_range' => COMBO_FIELDS}
end
