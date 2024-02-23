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

  validates_numericality_of :sample_position, :only_integer => true, :less_than => 20,
                            :message => "is not a valid integer < 20"
end
