# == Schema Information
#
# Table name: sample_queries
#
#  mrn                 :string
#  patient_id          :string
#  barcode_from        :string
#  barcode_to          :string
#  gender              :string
#  consent_protocol_id :integer
#  clinic_or_location  :string
#  organism            :string
#  race                :string
#  ethnicity           :string
#  sample_tissue       :string
#  sample_type         :string
#  tissue_preservation :string
#  tumor_normal        :string
#  date_filter         :string
#  from_date           :date
#  to_date             :date
#  updated_by          :integer
#

class SampleQuery
  include ActiveModel::Model

  attr_accessor :mrn, :patient_id, :barcode_string, :alt_identifier, :gender, :consent_protocol_id,
    :clinic_or_location, :organism, :race, :ethnicity, :sample_tissue, :sample_type, :tissue_preservation,
    :tumor_normal, :date_filter, :from_date, :to_date, :updated_by

  validates_format_of :patient_id, :with => /\A\d+\z/, :allow_blank => true, :message => "id must be an integer"
  validates_date :to_date, :from_date, :allow_blank => true
  
  PATIENT_FLDS = %w(organism)
  SCHAR_FLDS = %w{patient_id gender race ethnicity consent_protocol_id clinic_or_location}
  SAMPLE_FLDS = %w{alt_identifier tumor_normal sample_tissue sample_type tissue_preservation updated_by}
  ALL_FLDS    = PATIENT_FLDS | SCHAR_FLDS | SAMPLE_FLDS

end
