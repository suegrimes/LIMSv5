# == Schema Information
#
# Table name: histology_queries
#
#  mrn :string
#  patient_string :string
#  barcode_string :string
#  alt_identifier :string
#  consent_protocol_id  :integer
#  clinic_or_location   :string
#  tissue_preservation  :string
#  from_date    :date
#  to_date      :date
#

class HistologyQuery
  include ActiveModel::Model

  attr_accessor :mrn, :patient_string, :barcode_string, :alt_identifier, :consent_protocol_id, :clinic_or_location,
                :tissue_preservation, :from_date, :to_date

  validates_date :to_date, :from_date, :allow_blank => true

  #SAMPLE_FLDS = %w{alt_identifier tissue_preservation}
  #SCHAR_FLDS = %w{consent_protocol_id clinic_or_location}
  #ALL_FLDS    = SCHAR_FLDS | SAMPLE_FLDS

  STD_FIELDS = {'sample_characteristics' => %w(consent_protocol_id clinic_or_location),
                'samples' => %w(alt_identifier tissue_preservation)}

  COMBO_FIELDS = {:patient_string => {:sql_attr => ['samples.patient_id']},
                   :barcode_string => {:sql_attr => ['samples.barcode_key', 'histologies.he_barcode_key']}}

  QUERY_FLDS = {'standard' => STD_FIELDS, 'multi_range' => COMBO_FIELDS}
end
