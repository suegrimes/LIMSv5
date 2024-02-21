# == Schema Information
#
# Table name: slide_samples
#
#  id   :integer          not null, primary key
#  imaging_slide_id :integer
#  imaging_run_id   :integer
#  imaging_position :integer
#

class SlideImaging < ApplicationRecord
  belongs_to :imaging_slide
  belongs_to :imaging_run
end
