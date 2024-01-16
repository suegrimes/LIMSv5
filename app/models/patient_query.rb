# == Schema Information
#
# Table name: patient_queries
#
#  mrn                 :string
#  patient_string      :string
#  consent_protocol_id :integer
#  clinic_or_location  :string
#  organism            :string
#  gender              :string
#  sample_tissue       :string
#  sample_type         :string
#  tissue_preservation :string
#  disease_primary     :string
#  tumor_normal        :string
#  date_filter         :string
#  from_date           :date
#  to_date             :date
#  updated_by          :integer
#

class PatientQuery
  include ActiveModel::Model

  attr_accessor :mrn, :patient_string, :organism, :gender, :consent_protocol_id, :clinic_or_location,
                :sample_tissue, :sample_type, :tissue_preservation, :disease_primary, :tumor_normal,
                :date_filter, :from_date, :to_date, :updated_by

  #validates_format_of :patient_id, :with => /\A\d+\z/, :allow_blank => true, :message => "id must be an integer"
  validates_date :to_date, :from_date, :allow_blank => true
  validates :patient_string, compound_string: {:datatype => 'numeric'}, :allow_blank => true

  STD_FIELDS = {'patients' => %w(organism gender),
                'sample_characteristics' => %w(patient_id consent_protocol_id clinic_or_location disease_primary),
                'samples' => %w(tumor_normal sample_tissue sample_type tissue_preservation updated_by)}
  COMBO_FIELDS = {:patient_string => {:sql_attr => ['sample_characteristics.patient_id']}}

  QUERY_FLDS = {'standard' => STD_FIELDS, 'multi_range' => COMBO_FIELDS, 'search' => {}}
end
