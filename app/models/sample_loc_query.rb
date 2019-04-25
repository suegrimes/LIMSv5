class SampleLocQuery
  include ActiveModel::Model

  attr_accessor :mrn, :patient_string, :barcode_string, :alt_identifier, :consent_protocol_id,
                :clinic_or_location, :sample_tissue, :sample_type, :tissue_preservation,
                :tumor_normal, :date_filter, :from_date, :to_date

  #validates_format_of :patient_id, :with => /\A\d+\z/, :allow_blank => true, :message => "id must be an integer"
  validates_date :to_date, :from_date, :allow_blank => true

  STD_FIELDS = {'sample_characteristics' => %w(patient_id consent_protocol_id clinic_or_location),
                'samples' => %w(alt_identifier tumor_normal sample_tissue sample_type tissue_preservation)}
  COMBO_FIELDS = {:patient_string => {:sql_attr => ['sample_characteristics.patient_id']},
                  :barcode_string => {:sql_attr => ['samples.barcode_key', 'samples.source_barcode_key']}}

  QUERY_FLDS = {'standard' => STD_FIELDS, 'multi_range' => COMBO_FIELDS, 'search' => {}}
end
