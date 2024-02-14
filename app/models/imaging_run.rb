# == Schema Information
#
# Table name: imaging_runs
#
#  id              :integer          not null, primary key
#  imaging_date   :date
#  imaging_key    :string(20)
#  imaging_alt_id :string(50)
#  run_description :string(80)
#  seq_run_nr      :integer
#  machine_type    :string(10)
#  notebook_ref    :string(50)
#  notes           :string(255)
#  updated_by      :integer
#  created_at      :datetime
#  updated_at      :timestamp        not null
#

class ImagingRun < ApplicationRecord
  include Attachable

  has_many :image_slides, :dependent => :destroy
  has_many :attached_files, :as => :sampleproc
  
  validates_presence_of :machine_type
  validates_date :run_date, :allow_blank => true

  DEFAULT_MACHINE_TYPE = 'Xenium'
  NR_SLIDES = {:Xenium => 2}

  def self.find_imaging_runs(rptorder='runnr',condition_array=[])
    rpt_order = (rptorder == 'rundt' ? 'imaging_runs.run_date DESC' : 'imaging_runs.seq_run_nr DESC')
    self.includes(:image_slides).where(sql_where(condition_array)).order(rpt_order).all
  end

  def self.find_for_export(imaging_ids)
    self.includes(:image_slides).where("imaging_runs.id IN (?)", imaging_ids).desc_by_run.all
  end
end