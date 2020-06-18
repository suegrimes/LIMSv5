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

class PsampleLoc < ProcessedSample
  has_many   :sample_storage_containers, :as => :stored_sample
  accepts_nested_attributes_for :sample_storage_containers, :allow_destroy => true, :reject_if => :all_blank

  def room_and_freezer
    (sample_storage_containers ? sample_storage_containers.map{|sc| sc.room_and_freezer}.uniq.join(',') : '')
  end
  
  def container_and_position
    (sample_storage_containers ? sample_storage_containers.map{|sc| sc.container_and_position}.join(',') : '')
  end

end
