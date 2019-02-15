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

  attr_accessor :patient_id, :owner, :from_date, :to_date

  validates_date :to_date, :from_date, :allow_blank => true

  validates_format_of :patient_id, :with => /\A\d+\z/, :allow_blank => true, :message => "id must be an integer"
  validates_date :to_date, :from_date, :allow_blank => true

  ASSAY_FLDS   = %w{owner}
  PSAMPLE_FLDS = %w{patient_id}
  ALL_FLDS     = ASSAY_FLDS
end
