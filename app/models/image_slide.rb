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
  has_and_belongs_to_many :samples, :join_table => :slide_samples

end
