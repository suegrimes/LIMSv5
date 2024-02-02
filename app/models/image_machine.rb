# == Schema Information
#
# Table name: image_machines
#
#  id            :integer          not null, primary key
#  imager_name  :string(20)       not null
#  bldg_location :string(12)
#  imager_type  :string(20)
#  imager_desc  :string(50)
#  last_seq_num  :integer
#  notes         :string(255)
#  created_at    :datetime
#  updated_at    :timestamp
#

class ImageMachine < ApplicationRecord
  scope :imagers, -> { where("imager_name <> 'Run_Number'") }

  MACHINE_TYPES = Category.populate_dropdown_for_category('imager_type')
  
  def imager_name_and_type
    return [imager_name, '(', imager_type, ')'].join
  end
  
  def self.populate_dropdown
    return self.imagers.order('bldg_location, imager_name').all
  end

  def self.find_and_incr_run_nr
    img_run_nr = self.find_by_imager_name('Run_Number')
    img_run_nr.update_attributes(:last_seq_num => img_run_nr.last_seq_num + 1)
    return img_run_nr.last_seq_num
  end
  
  def self.all_sorted
    self.imagers.order('img_machines.bldg_location, img_machines.imager_name').all
  end
  
end
