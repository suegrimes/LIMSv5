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
  has_one :sample
  has_one :image_slide

end
