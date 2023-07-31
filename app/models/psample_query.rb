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
                :disease_primary, :sample_tissue, :sample_type, :tissue_preservation, :pathology, :tumor_normal,
                :protocol_id, :extraction_type, :from_date, :to_date, :updated_by

  #validates_format_of :patient_id, :with => /\A\d+\z/, :allow_blank => true, :message => "id must be an integer"
  validates_date :to_date, :from_date, :allow_blank => true
  validates :patient_string, compound_string: {:datatype => 'numeric'}, :allow_blank => true
  validates :barcode_string, compound_string: {:datatype => 'alpha_dot_numeric'}, :allow_blank => true

  STD_FIELDS = {'sample_characteristics' => %w(consent_protocol_id clinic_or_location disease_primary, pathology),
                'samples' => %w(sample_tissue sample_type tissue_preservation tumor_normal),
                'processed_samples' => %w(barcode_key protocol_id extraction_type updated_by)}

  COMBO_FIELDS = {:patient_string => {:sql_attr => ['samples.patient_id']},
                  :barcode_string => {:sql_attr => ['samples.source_barcode_key', 'samples.barcode_key', 'processed_samples.barcode_key']}}

  QUERY_FLDS = {'standard' => STD_FIELDS, 'multi_range' => COMBO_FIELDS, 'search' => {}}
end
