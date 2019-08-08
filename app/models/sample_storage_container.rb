# == Schema Information
#
# Table name: sample_storage_containers
#
#  id                     :integer          not null, primary key
#  stored_sample_id       :integer
#  stored_sample_type     :string(50)
#  sample_name_or_barcode :string(25)       default(""), not null
#  container_type         :string(10)
#  container_name         :string(25)       default(""), not null
#  position_in_container  :string(15)
#  freezer_location_id    :integer
#  storage_container_id   :integer
#  row_nr                 :string(2)
#  position_nr            :string(3)        default("")
#  notes                  :string(100)
#  updated_by             :integer
#  updated_at             :timestamp
#

class SampleStorageContainer < ApplicationRecord
  # Rails 5 defaults to required: true, so make it explicitly optional
  #belongs_to :freezer_location, optional: true
  belongs_to :stored_sample, optional: true, polymorphic: true
  belongs_to :storage_container, optional: true
  belongs_to :user, :foreign_key => :updated_by, optional: true

  validates_presence_of :storage_container, on: :create, message: "is invalid.  Please enter a valid container, or leave all location fields blank"
  validate :position_must_be_valid_for_container_type

  before_create :upd_sample_name, :upd_storage_container_fields
  before_update :upd_storage_container_fields

  def container_blank?
    self.container_type.blank? and self.container_name.blank? and self.position_in_container.blank? and self.freezer_location_id.nil?
  end

  def position_must_be_valid_for_container_type
    unless self.container_type.nil?
      storage_type = StorageType.where('container_type = ?', self.container_type).first
      valid_positions = (storage_type.nil? ? nil : storage_type.valid_positions)
      if valid_positions and !valid_positions.include?(self.position_in_container)
        errors.add(:position_in_container, "is not valid for this container type")
      end
    end
  end

  def upd_sample_name
    self.sample_name_or_barcode = self.stored_sample.barcode_key
  end

  def type_of_sample
    stype = 'NotInLIMS'
    if stored_sample
      if stored_sample_type == 'Sample'
        stype = stored_sample.sample_type
      elsif stored_sample_type == 'ProcessedSample'
        stype = stored_sample.extraction_type
      else
        stype = stored_sample_type
      end
    end
    return stype
  end
  
  def container_desc
    (storage_container ? [storage_container.container_type, storage_container.container_name].join(': ') : 'NA: Unknown')
  end

  def container_sort
    (container_name =~ /\A\d\Z/ ? '0' + container_name : container_name)
  end
  
  def container_and_position
    [container_desc, position_in_container].join('/')
  end
  
  def position_sort
    if position_in_container =~ /\A[A-Z]\d+\Z/ 
      sort1 = position_in_container[0,1]
      sort2 = position_in_container[1..-1].to_i
    else
      sort1 = (position_in_container.nil? ? '' : position_in_container)
      sort2 = 0
    end
    return [sort1, sort2] 
  end
  
  def room_and_freezer
    (storage_container ? storage_container.freezer_location.room_and_freezer : '')
  end

  def self.find_for_query(condition_array)
    self.includes(:storage_container => :freezer_location).where(sql_where(condition_array))
        .order('freezer_locations.freezer_nr, freezer_locations.room_nr, storage_containers.container_type, storage_containers.container_name').all
  end

  # This dropdown should now be populated from StorageType
  #def self.populate_dropdown
  #  self.where('container_type > ""').order(:container_type).uniq.pluck(:container_type)
  #end

  # Delete these redundant fields unless need to keep here for query efficiency (or may need for bulk upload?)
  # keep redundant fields in sync with the storage container it belongs to
  def upd_storage_container_fields
    if self.storage_container
      self.container_type = self.storage_container.container_type
      self.container_name = self.storage_container.container_name
      self.freezer_location_id = self.storage_container.freezer_location_id
    else
      # This is needed for bulk upload where StorageContainer model is not accessed directly
      new_container = StorageContainer.where("container_type = ? and container_name = ? and freezer_location_id = ?",
                                                 self.container_type, self.container_name, self.freezer_location_id).first
      self.storage_container_id = (new_container ? new_container.id : self.storage_container_id)
    end
  end
end
