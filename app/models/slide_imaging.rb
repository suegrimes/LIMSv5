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

  validates_numericality_of :imaging_position, :only_integer => true, :less_than => 10,
                            :message => "is not a valid integer < 10"
end
