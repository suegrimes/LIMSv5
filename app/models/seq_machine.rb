# == Schema Information
#
# Table name: seq_machines
#
#  id            :integer          not null, primary key
#  machine_name  :string(20)       not null
#  bldg_location :string(12)
#  machine_type  :string(20)
#  machine_desc  :string(50)
#  last_seq_num  :integer
#  notes         :string(255)
#  created_at    :datetime
#  updated_at    :timestamp
#

class SeqMachine < ApplicationRecord
  scope :sequencers, -> { where("machine_name <> 'Run_Number'") }
  
  #MACHINE_TYPES = %w{GAIIx HiSeq MiSeq NextSeq}
  #MACHINE_TYPES = self.sequencers.select('DISTINCT(machine_type)').group(:machine_type).all.map(&:machine_type)
  MACHINE_TYPES = Category.populate_dropdown_for_category('machine type')
  
  def machine_name_and_type
    return [machine_name, '(', machine_type, ')'].join
  end
  
  def self.populate_dropdown
    return self.sequencers.order('bldg_location, machine_name').all
  end
  
  def self.populate_dropdown_grouped
    sequencers_by_bldg = self.sequencers.select('id, bldg_location, machine_name').order('bldg_location, machine_name').all.group_by(&:bldg_location)
    return sequencers_by_bldg.collect {|bldg, attrs| [bldg, attrs.collect{|attr| [attr.machine_name, attr.id]}]}
  end
  
  def self.find_and_incr_run_nr
    seq_run_nr = self.find_by_machine_name('Run_Number')
    seq_run_nr.update_attributes(:last_seq_num => seq_run_nr.last_seq_num + 1) 
    return seq_run_nr.last_seq_num
  end
  
  def self.all_sorted
    self.sequencers.order('seq_machines.bldg_location, seq_machines.machine_name').all
  end
  
end
