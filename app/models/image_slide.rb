# == Schema Information
#
# Table name: image_slides
#
#  id               :integer          not null, primary key
#  imaging_run_id   :integer
#  slide_number     :string
#  slide_name       :string
#  updated_by       :integer
#  created_at       :datetime
#  updated_at       :timestamp
#

class ImageSlide < ApplicationRecord
  
  belongs_to :imaging_run, optional: true
  has_many :samples, through: :slide_samples
  accepts_nested_attributes_for :slide_samples, :reject_if => proc {|attrs| attrs[:sample_id].blank?},
                                :allow_destroy => true

end
