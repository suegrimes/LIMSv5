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

  belongs_to :user, optional: true, foreign_key: :updated_by
  belongs_to :protocol, optional: true
  has_many :slide_imagings, :dependent => :destroy
  has_many :imaging_slides, :through => :slide_imagings
  accepts_nested_attributes_for :slide_imagings, :reject_if => proc {|attrs| attrs[:imaging_position].blank?},
                                :allow_destroy => true
  has_many :attached_files, :as => :sampleproc
  
  validates_presence_of :protocol_id
  validates_date :run_date, :allow_blank => true

  DEFAULT_MACHINE_TYPE = 'Xenium'
  NR_SLIDES = {:Xenium => 2}

  def self.last_run_nr
    run_nr = 0
    if self.count > 0
      last_run_key = self.order("id DESC").limit(1).pluck(:imaging_key)[0]
      run_nr = last_run_key.split("_")[2].to_i
    end
    return run_nr
  end

  def self.find_imaging_runs(rptorder='runnr',condition_array=[])
    rpt_order = (rptorder == 'rundt' ? 'imaging_runs.run_date DESC' : 'imaging_runs.seq_run_nr DESC')
    self.includes(:imaging_slides).where(sql_where(condition_array)).order(rpt_order).all
  end

  def self.find_for_export(imaging_ids)
    self.includes(:imaging_slides).where("imaging_runs.id IN (?)", imaging_ids).desc_by_run.all
  end

  def self.find_for_query(condition_array=[])
    self.includes(:imaging_slides)
        .references(:slide_imaging, :imaging_slides)
        .where(sql_where(condition_array))
        .order('imaging_runs.id DESC, slide_imagings.imaging_position').all
  end
end
