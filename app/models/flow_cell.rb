# == Schema Information
#
# Table name: flow_cells
#
#  id              :integer          not null, primary key
#  flowcell_date   :date
#  nr_bases_read1  :string(4)
#  nr_bases_index  :string(2)
#  nr_bases_index1 :string(2)
#  nr_bases_index2 :string(2)
#  nr_bases_read2  :string(4)
#  cluster_kit     :string(10)
#  sequencing_kit  :string(10)
#  flowcell_status :string(2)
#  sequencing_key  :string(50)
#  run_description :string(80)
#  sequencing_date :date
#  seq_machine_id  :integer
#  seq_run_nr      :integer
#  machine_type    :string(10)
#  hiseq_xref      :string(50)
#  notes           :string(255)
#  created_at      :datetime
#  updated_at      :timestamp        not null
#

class FlowCell < ApplicationRecord
  include Attachable

  belongs_to :seq_machine, optional: true
  has_many :flow_lanes, :dependent => :destroy
  has_many :attached_files, :as => :sampleproc
  
  before_create :set_flowcell_status
  after_update :save_lanes
  
  validates_presence_of :machine_type, :nr_bases_read1
  validates_date :flowcell_date, :sequencing_date, :allow_blank => true
  validate :seq_kit_valid, on: :create
  
  #scope :sequenced,   :conditions => "flowcell_status <> 'F'"
  #scope :unsequenced, :conditions => "flowcell_status = 'F'"
  # mhayden: scope body needs to be a callable proc or lambda in Rails 5
  scope :sequenced, -> { where("flowcell_status <> 'F'") }
  scope :unsequenced, -> { where("flowcell_status = 'F'") }
  scope :desc_by_run, -> { order("flow_cells.seq_run_nr DESC")}
  scope :desc_by_date, -> { order("flow_cells.flowcell_date DESC")}
  
  DEFAULT_MACHINE_TYPE = 'iSeq'
  NR_LANES = {:iSeq => 1, :Genius => 1, :MinION => 1, :MiSeq => 1, :NextSeq => 1, :NovaSeq => 4, :GAIIx => 8, :HiSeq => 8,
              :PromethION => 24, :Xenium => 1, :PacBio => 1}
  STATUS = %w{F R S Q N X}
  #Status code values: F-Flow Cell created; R-Ready for sequencing; Q-QC uploaded; N-N/A; X-Failed.
  #  S-Sequenced: no entries in database table.
  #Only codes currently being used: F (flowcell created), R (run# assigned), X (failed run)
  RUN_NR_TYPES = %w{LIMS Illumina}
  
  def seq_kit_valid
    sequencer_kits = SequencerKit.where('machine_type = ?', machine_type).pluck(:kit_name)
    unless sequencer_kits.include?(sequencing_kit)
      errors.add(:sequencing_kit, "is not valid for selected machine type")
    end
  end

  def for_publication?
    publication_flags = self.flow_lanes.collect{|flow_lane| flow_lane.for_publication?}
    return publication_flags.max
  end
  
  def publication_ids
    self.flow_lanes.collect{|flow_lane| flow_lane.publication_ids}.flatten.uniq
  end
  
  def sequenced?
    flowcell_status != 'F'
  end

  def failed_run?
    flowcell_status == 'X'
  end
  
  def flowcell_qc
    case flowcell_status
      when 'N' then 'N/A'
      when 'X' then 'Fail'
      else ' '
    end
  end
  
  def hiseq_qc?
    # This method is used to determine whether to display 'Synder' center QC fields, or 'SGTC'
    # If sequencing machine starts with 'S' or run# > 118, assume QC done at SGTC
    (machine_type == 'HiSeq' && (sequencing_key.split('_')[1][0].chr != 'S' && seq_run_nr < 110))
  end
  
  def hiseq_run?
    # This method is used to determine whether to display hiseq flowcell along with sequencing key
    (machine_type == 'HiSeq' && !hiseq_xref.blank? && hiseq_xref.split('_').size > 3)
  end
  
  def seq_run_key
    hiseq_flowcell = (hiseq_run? ? hiseq_xref.split('_')[3][0..5] : ' ')
    return (hiseq_run? ? [sequencing_key, ' (', hiseq_flowcell, ')'].join : sequencing_key)
  end
  
  def id_name
  (sequenced? ? "Run #: #{sequencing_key}" : "Flow Cell: #{id.to_s}")
  end

  def alt_run_or_descr
    alt_run = (hiseq_xref.blank? ? '' : ['Alt Run#: ', hiseq_xref].join)
    return (run_description.blank? ? alt_run : run_description)
  end
  
  def self.find_sequencing_runs(rptorder='runnr',condition_array=[])
    rpt_order = (rptorder == 'seqdt' ? 'flow_cells.sequencing_date DESC' : 'flow_cells.seq_run_nr DESC')
    self.sequenced.includes(:flow_lanes => :publications).where(sql_where(condition_array)).order(rpt_order).all
  end

  def self.find_for_export(flowcell_ids)
    self.includes(:flow_lanes => :publications).where("flow_cells.id IN (?)", flowcell_ids).desc_by_run.all
  end
  
  def self.find_flowcells_for_sequencing
    self.unsequenced.includes(:flow_lanes => :publications).desc_by_date.all
    #self.unsequenced.find(:all, :include => {:flow_lanes => :publications}, :order => 'flow_cells.flowcell_date DESC')
  end
  
  def self.find_flowcell_incl_rundirs(condition_array=[])
    self.includes(:run_dirs, {:flow_lanes => :publications}).where(sql_where(condition_array)).order('flow_cells.seq_run_nr, run_dirs.device_name').first
  end
  
  def set_flowcell_status(flowcell_status='F')
    self.flowcell_status = flowcell_status
  end
  
  def build_flow_lanes(lib_rows)
    lib_rows.each do |lrow|
      # Ignore blank lines (ie sequencing libraries which were not assigned to a lane)
      next if lrow[:lane_nr].blank?
      
      # Check for sequencing libraries assigned to multiple lanes, and replicate if needed
      # NextSeq is 4 identical lanes and only enter 1, so replicate 4 times
      lane_nrs = machine_type == 'NextSeq' ? [1,2,3,4] : lrow[:lane_nr].split(',')
      lane_nrs[0..(lane_nrs.size - 1)].each_with_index do |lnr, i|
        lrow[:lane_nr] = lnr
        lrow[:oligo_pool] = Pool.find(lrow[:pool_id]).tube_label if !lrow[:pool_id].blank?
        flow_lanes.build(flow_lane_params(lrow))
      end  
    end
  end
  
#  def new_lane_attributes=(lane_attributes)
#    # Remove blank lines (ie sequencing libraries which were not assigned to a lane)
#    lane_attributes.reject!{|attr| attr[:lane_nr].blank?}
#    
#    lane_attributes.each do |attributes|
#      # Check for sequencing libraries assigned to multiple lanes, and replicate if needed
#      lane_nrs = attributes[:lane_nr].split(',')
#      lane_nrs[0..(lane_nrs.size - 1)].each do |lnr|
#        attributes[:lane_nr] = lnr
#        flow_lanes.build(attributes)
#      end
#    end
#  end
  
  def existing_lane_attributes=(lane_attributes)
    flow_lanes.reject(&:new_record?).each do |flow_lane|
      upd_attributes = lane_attributes[flow_lane.id.to_s]
      if upd_attributes
        upd_attributes[:oligo_pool] = (upd_attributes[:pool_id].blank? ? '' : Pool.find(upd_attributes[:pool_id]).tube_label)
        flow_lane.attributes = upd_attributes
      else
        flow_lanes.delete(flow_lane)
      end
    end
  end
  
  def save_lanes
    flow_lanes.each do |flow_lane|
      flow_lane.save(:validate=>false) unless flow_lane.lane_nr.nil? || flow_lane.lane_nr.blank?
    end
  end

protected
  def flow_lane_params(lrow)
    lrow.permit(:lane_nr, :lib_conc, :pool_id, :oligo_pool, :notes, :sequencing_key, :seq_lib_id, :lib_barcode,
                                      :lib_name, :lib_conc_uom, :adapter_id, :alignment_ref_id, :alignment_ref)
  end
  
end
