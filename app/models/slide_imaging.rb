# == Schema Information
#
# Table name: slide_samples
#
#  id   :integer          not null, primary key
#  sample_id :integer
#  image_slide_id :integer
#  sample_position :integer
#

class SlideSample < ApplicationRecord
  belongs_to :sample
  belongs_to :image_slide
end
