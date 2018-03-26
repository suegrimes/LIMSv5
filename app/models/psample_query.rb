# == Schema Information
#
# Table name: psample_queries
#
#  mrn                 :string
#  patient_string      :string
#  barcode_string      :string
#  consent_protocol_id :integer
#  clinic_or_location  :string
#  sample_tissue       :string
#  sample_type         :string
#  tissue_preservation :string
#  pathology           :string
#  tumor_normal        :string
#  protocol_id         :string
#  extraction_type     :string
#  from_date           :date
#  to_date             :date
#  updated_by          :integer
#

class PsampleQuery
  include ActiveModel::Model

  attr_accessor :mrn, :patient_string, :barcode_string, :consent_protocol_id, :clinic_or_location,
    :sample_tissue, :sample_type, :tissue_preservation, :pathology, :tumor_normal, :protocol_id,
    :extraction_type, :from_date, :to_date, :updated_by

  #validates_format_of :patient_id, :with => /\A\d+\z/, :allow_blank => true, :message => "id must be an integer"
  validates_date :to_date, :from_date, :allow_blank => true
  
  SCHAR_FLDS   = %w{consent_protocol_id clinic_or_location pathology}
  SAMPLE_FLDS  = %w{sample_tissue sample_type tissue_preservation tumor_normal}
  PSAMPLE_FLDS = %w{barcode_key protocol_id extraction_type updated_by} 
  ALL_FLDS     = SCHAR_FLDS | SAMPLE_FLDS | PSAMPLE_FLDS
end
