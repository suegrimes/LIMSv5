
# == Schema Information
#
# Table name: sample_queries
#
#  mrn                 :string
#  patient_string      :string
#  barcode_string      :string
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

  attr_accessor :mrn, :patient_string, :barcode_string, :alt_identifier, :gender, :consent_protocol_id,
    :clinic_or_location, :organism, :race, :ethnicity, :sample_tissue, :sample_type, :tissue_preservation,
                :disease_primary, :tumor_normal, :date_filter, :from_date, :to_date, :updated_by

  #validates_format_of :patient_id, :with => /\A\d+\z/, :allow_blank => true, :message => "id must be an integer"
  validates_date :to_date, :from_date, :allow_blank => true
  validates :patient_string, compound_string: {:datatype => 'numeric'}, :allow_blank => true
  validates :barcode_string, compound_string: {:datatype => 'alphanumeric'}, :allow_blank => true

  STD_FIELDS = {'patients' => %w(organism),
                'sample_characteristics' => %w(patient_id gender race ethnicity consent_protocol_id clinic_or_location disease_primary),
                'samples' => %w(alt_identifier tumor_normal sample_tissue sample_type tissue_preservation updated_by)}
  COMBO_FIELDS = {:patient_string => {:sql_attr => ['samples.patient_id']},
                  :barcode_string => {:sql_attr => ['samples.barcode_key', 'samples.source_barcode_key']}}

  QUERY_FLDS = {'standard' => STD_FIELDS, 'multi_range' => COMBO_FIELDS, 'search' => {}}
end
