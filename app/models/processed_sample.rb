# == Schema Information
#
# Table name: processed_samples
#
#  id                  :integer          not null, primary key
#  sample_id           :integer
#  patient_id          :integer
#  protocol_id         :integer
#  extraction_type     :string(25)
#  processing_date     :date
#  input_uom           :string(25)
#  input_amount        :decimal(11, 3)
#  barcode_key         :string(25)
#  old_barcode         :string(25)
#  support             :string(25)
#  elution_buffer      :string(25)
#  vial                :string(10)
#  final_vol           :decimal(11, 3)
#  final_conc          :decimal(11, 3)
#  final_a260_a280     :decimal(11, 3)
#  final_a260_a230     :decimal(11, 3)
#  final_rin_nr        :decimal(4, 1)
#  psample_remaining   :string(2)
#  storage_location_id :integer
#  storage_shelf       :string(10)
#  storage_boxbin      :string(25)
#  comments            :string(255)
#  updated_by          :integer
#  created_at          :datetime
#  updated_at          :timestamp        not null
#

class ProcessedSample < ApplicationRecord
  belongs_to :sample, optional: false
  belongs_to :patient, optional: true
  belongs_to :user, optional: true, foreign_key: 'updated_by'
  belongs_to :protocol, optional: true
  has_many :molecular_assays
  has_many :lib_samples
  has_many :seq_libs, :through => :lib_samples
  has_one :sample_storage_container, :as => :stored_sample, :dependent => :destroy
  has_many :attached_files, :as => :sampleproc
  
  accepts_nested_attributes_for :sample_storage_container
  
  validates_date :processing_date
  before_validation :derive_barcode, on: :create
  before_create :get_sample_flds
  before_save :del_blank_storage

  validates_presence_of :barcode_key
  validates_uniqueness_of :barcode_key, message: 'is not unique'

  def del_blank_storage
    if self.sample_storage_container
      if self.psample_remaining == 'N' or self.sample_storage_container.storage_container_id.nil?
        self.sample_storage_container = nil
      end
    end
  end

  def derive_barcode
    if self.barcode_key.blank?
      self.barcode_key = ProcessedSample.next_extraction_barcode(self.sample_id, self.sample.barcode_key, self.extr_type_char)
    end
  end

  def get_sample_flds
    self.patient_id = (self.sample ? self.sample.patient_id : nil)
    self.input_uom = (self.sample ? self.sample.amount_uom : nil)
  end
  
  def initial_amt_ug
    (initial_vol * initial_conc / 1000) if (!initial_vol.nil? && !initial_conc.nil?)
  end
  
  def final_amt_ug
    (final_vol * final_conc / 1000) if (!final_vol.nil? && !final_conc.nil?)
  end
  
  def extr_type_char
    echar = case extraction_type
      when /(.*)DNA(.*)/     then 'D'
      when /(.*)RNA(.*)/     then 'R'
      when /(.*)Nucleic(.*)/ then 'N'
      when /(.*)Protein(.*)/ then 'P'
      else '?'
    end
    return echar
  end

  def protocol_abbrev
    (protocol ? protocol.short_name : 'N/A')
  end
  
  def room_and_freezer
    (sample_storage_container ? sample_storage_container.room_and_freezer : '')
  end
  
  def container_and_position
    (sample_storage_container ? sample_storage_container.container_and_position : '')
  end
  
  def self.barcode_search(search_string)
    #self.find(:all, :conditions => ["barcode_key LIKE ?", search_string + '%'])
    self.where("barcode_key LIKE ?", search_string + '%').all
  end
  
  def self.getwith_attach(id)
    self.includes(:attached_files).find(id)
  end

  def self.find_psample_id(source_DNA)
    processed_sample = self.where('barcode_key = ?', source_DNA).first if !source_DNA.blank?
    return (processed_sample ? processed_sample.id : nil)
  end

  def self.find_all_incl_sample(condition_array=[])
    self.includes(:sample, :sample_storage_container).where(sql_where(condition_array)).order('samples.patient_id, samples.barcode_key')
  end
  
  def self.find_one_incl_patient(condition_array=[])
    self.includes({:sample => [:sample_characteristic, :patient]}, :sample_storage_container).where(sql_where(condition_array)).first
  end
  
  def self.find_for_query(condition_array=[])
    self.includes({:sample => :sample_characteristic}, :protocol, :user, {:sample_storage_container => {:storage_container => :freezer_location}})
        .references(:protocol, :user, {:sample_storage_container => {:storage_container => :freezer_location}})
        .where(sql_where(condition_array))
        .order('samples.patient_id, samples.barcode_key, processed_samples.barcode_key').all
  end
  
  def self.find_for_export(psample_ids)
    self.includes({:sample => {:sample_characteristic => :consent_protocol}}, :protocol, {:sample_storage_container => {:storage_container => :freezer_location}})
        .references(:protocol, {:sample_storage_container => :storage_container})
        .where('processed_samples.id IN (?)', psample_ids)
        .order('samples.patient_id, samples.barcode_key, processed_samples.barcode_key').all
  end
  
  def self.next_extraction_barcode(source_id, source_barcode, extraction_char)
    barcode_mask = [source_barcode, '.', extraction_char, '%'].join
    #barcode_max  = self.maximum(:barcode_key, :conditions => ["sample_id = ? AND barcode_key LIKE ?", source_id.to_i, barcode_mask])
    barcode_max  = self.where('sample_id = ? AND barcode_key LIKE ?', source_id.to_i, barcode_mask).maximum(:barcode_key)
    if barcode_max
      return barcode_max.succ  # Existing extraction, so increment last 1-2 characters of max barcode string (eg. 3->4, or 09->10)
    else
      return [source_barcode, '.', extraction_char, '01'].join # No existing extractions of this type, so add '01' suffix.  (eg. D01 if DNA extraction)
    end
  end
  
end
