# == Schema Information
#
# Table name: slide_samples
#
#  id   :integer          not null, primary key
#  sample_id :integer
#  imaging_slide_id :integer
#  sample_position :integer
#

class SlideImaging < ApplicationRecord
  belongs_to :imaging_slide
  belongs_to :imaging_run
end
