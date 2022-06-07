# == Schema Information
#
# Table name: histologies
#
#  id                        :integer          not null, primary key
#  sample_id                 :integer
#  he_barcode_key            :string(20)       not null
#  he_date                   :date
#  histopathology            :string(25)
#  he_classification         :string(50)
#  pathologist               :string(50)
#  tumor_cell_content        :decimal(7, 3)
#  inflammation_type         :string(25)
#  inflammation_infiltration :string(25)
#  comments                  :string(255)
#  updated_by                :integer
#  created_at                :datetime
#  updated_at                :timestamp
#

class Histology < ApplicationRecord
  include Attachable
  include Storable

  belongs_to :sample, optional: true
  has_one :sample_storage_container, as: :stored_sample, dependent: :destroy
  has_many :attached_files, :as => :sampleproc

  accepts_nested_attributes_for :sample_storage_container, :allow_destroy => true, :reject_if => :all_blank

  before_validation :del_blank_storage
  validates_date :he_date
  validates_presence_of :pathologist

  def barcode_key
    he_barcode_key
  end

  def room_and_freezer
    (sample_storage_container ? sample_storage_container.room_and_freezer : '')
  end

  def container_and_position
    (sample_storage_container ? sample_storage_container.container_and_position : '')
  end

  def del_blank_storage
    if self.sample_storage_container and self.sample_storage_container.container_blank?
      self.sample_storage_container = nil
    end
  end

  def self.getwith_attach(id)
    self.includes(:attached_files).find(id)
  end
  
  def self.new_he_barcode(sample_barcode)
    return sample_barcode + '.H1'
  end

  def self.find_with_conditions(condition_array)
    self.includes(:sample => :sample_characteristic).where(sql_where(condition_array)).order('samples.patient_id, samples.barcode_key')
  end

#  def self.next_he_barcode(sample_id, sample_barcode)
#    barcode_max = self.maximum(:he_barcode_key, :conditions => ["sample_id = ? AND he_barcode_key LIKE ?", sample_id.to_i, sample_barcode + '%'])
#    if barcode_max
#      return barcode_max.succ   # Increment last 1-2 characters of string (eg H02 -> H03, or H09 -> H10)
#    else
#      return sample_barcode + '.H01' # No existing dissections, so use 'H01' suffix
#    end  
#  end
  
end
