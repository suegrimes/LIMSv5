# == Schema Information
#
# Table name: sample_characteristics
#
#  id                  :integer          not null, primary key
#  patient_id          :integer
#  collection_date     :date
#  clinic_or_location  :string(100)
#  consent_protocol_id :integer
#  consent_nr          :string(15)
#  gender              :string(1)
#  ethnicity           :string(35)
#  race                :string(70)
#  disease_primary     :string(25)
#  nccc_tumor_id       :string(20)
#  nccc_pathno         :string(20)
#  pathology_id        :integer
#  pathology           :string(50)
#  comments            :string(255)
#  updated_by          :integer
#  created_at          :datetime
#  updated_at          :datetime
#

class SampleCharacteristic < ApplicationRecord
  require 'ezcrypto'
  
  has_many :samples, :dependent => :destroy
#  belongs_to :patient, optional: true
  belongs_to :patient, optional: false
  belongs_to :consent_protocol, optional: true
  belongs_to :pathology, optional: true
  belongs_to :user, optional: true, foreign_key: 'updated_by'
  
  accepts_nested_attributes_for :samples
  validates_associated :samples
  
  validates_presence_of :collection_date, :if => Proc.new { |a| a.new_record? }
  validates_date :collection_date, :allow_blank => true
  validates_presence_of :consent_protocol_id, :clinic_or_location
  validates_numericality_of :patient_age, :only_integer => true, :allow_blank => true

  before_create :upd_from_patient
  before_save :upd_consent
  after_update :upd_sample_date
  
  def upd_from_patient
    self.gender    = self.patient.gender
    self.ethnicity = self.patient.ethnicity
    self.race      = self.patient.race
  end
  
  def upd_consent
    self.consent_nr = self.consent_protocol.consent_nr if self.consent_protocol
  end
  
  def consent_descr
    (consent_protocol.nil? ? consent_nr : [consent_nr, consent_protocol.consent_abbrev].join('/'))
  end
  
  def from_nccc?
    (clinic_or_location == 'NCCC' ? true : false)
  end

  def self.find_by_patient(patient_id)
    sample_characteristics = self.where('patient_id = ?', patient_id).order('collection_date DESC').to_a
    return (sample_characteristics.empty? ? nil : sample_characteristics[0])
  end
  
  def self.find_with_samples(patient_id=nil)
    condition_array = (patient_id.nil? ? nil : ['sample_characteristics.patient_id = ?', patient_id])
    self.includes(:samples).where(*condition_array).order('sample_characteristics.patient_id, samples.barcode_key').references(:patient_id)
    #self.find(:all, :include => :samples,
    #                :order   => 'sample_characteristics.patient_id, samples.barcode_key',
    #                :conditions => condition_array)
  end

  def self.find_and_group_with_conditions(condition_array=[])
    #sample_characteristics = self.find(:all, :include => [:patient, :samples],
    #                :order   => 'sample_characteristics.patient_id, sample_characteristics.collection_date DESC',
    #               :conditions => condition_array)
    sample_characteristics = self.includes(:patient, :samples).where(sql_where(condition_array))
                                 .order('sample_characteristics.patient_id, sample_characteristics.collection_date DESC').references(:patient_id)
    return sample_characteristics.size, 
           sample_characteristics.group_by {|samp_char| [samp_char.patient_id, samp_char.patient.mrn]}
  end

  def self.find_for_export(id_array)
    self.includes(:patient, :consent_protocol, :samples)
        .references(:patient, :consent_protocol, :samples)
        .where("sample_characteristics.id IN (?) and samples.source_sample_id IS NULL", id_array)
        .order("patients.id, collection_date").all
  end

  private
  def upd_sample_date
    self.samples.each do |sample|
      sample.update_attributes(:sample_date => self.collection_date)
    end
  end
end
