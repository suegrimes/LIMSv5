# == Schema Information
#
# Table name: N/A
#
class StorageQuery
include ActiveModel::Model

attr_accessor :mrn, :patient_id, :barcode_string, :alt_identifier, :consent_protocol_id, :clinic_or_location,
              :sample_tissue, :sample_type, :tissue_preservation, :tumor_normal, :date_filter, :from_date, :to_date

validates_date :to_date, :from_date, :allow_blank => true

validates_format_of :patient_id, :with => /\A\d+\z/, :allow_blank => true, :message => "id must be an integer"
validates_date :to_date, :from_date, :allow_blank => true

#SCHAR_FLDS = %w{consent_protocol_id clinic_or_location}
#SAMPLE_FLDS = %w{patient_id alt_identifier tumor_normal sample_tissue sample_type tissue_preservation}
#ALL_FLDS    = SCHAR_FLDS | SAMPLE_FLDS

STD_FIELDS = {'sample_characteristics' => %w(consent_protocol_id clinic_or_location),
              'samples' => %w(patient_id alt_identifier tumor_normal sample_tissue sample_type tissue_preservation)}
COMBO_FIELDS = {:barcode_string => {:sql_attr => ['samples.barcode_key']}}

QUERY_FLDS = {'standard' => STD_FIELDS, 'multi_range' => COMBO_FIELDS}

end
