# == Schema Information
#
# Table name: slide_samples
#
#  id   :integer          not null, primary key
#  sample_id :integer
#  imaging_slide_id :integer
#  sample_position :integer
#

class SlideSample < ApplicationRecord
  belongs_to :sample
  belongs_to :imaging_slide
end
