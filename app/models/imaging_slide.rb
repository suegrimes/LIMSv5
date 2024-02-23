# == Schema Information
#
# Table name: imaging_slides
#
#  id               :integer          not null, primary key
#  imaging_run_id   :integer
#  imaging_date     :date
#  slide_number     :string
#  slide_name       :string
#  updated_by       :integer
#  created_at       :datetime
#  updated_at       :timestamp
#

class ImagingSlide < ApplicationRecord

  belongs_to :user, optional: true, foreign_key: :updated_by
  belongs_to :protocol, optional: true
  has_many :slide_samples, dependent: :destroy
  has_many :samples, through: :slide_samples
  accepts_nested_attributes_for :slide_samples, :reject_if => proc {|attrs| attrs[:sample_id].blank?},
                                :allow_destroy => true
  has_many :slide_imagings, dependent: :destroy
  has_many :imaging_runs, through: :slide_imagings
  accepts_nested_attributes_for :slide_imagings, :reject_if => proc {|attrs| attrs[:imaging_run_id].blank?},
                                :allow_destroy => true

  validates_presence_of :slide_number
  validates_presence_of :protocol_id
  validates_date :imaging_date

  def self.find_for_query(condition_array=[])
    self.includes(:imaging_runs).where(sql_where(condition_array))
        .order('imaging_date DESC').all
  end
end

