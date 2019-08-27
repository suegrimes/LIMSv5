# == Schema Information
#
# Table name: sequencer_kits
#
#  id              :integer          not null, primary key
#  machine_type    :string(20)
#  kit_type        :string(1)
#  kit_name        :string(25)
#

class SequencerKit < ApplicationRecord
  scope :seq_kits, -> { where("kit_type = 'S'") }

  validates_presence_of :kit_name, :kit_type

  def self.populate_dropdown
    return self.seq_kits.order('machine_type, kit_name').all
  end

  def self.populate_dropdown_grouped
    kits_by_machine_type = self.seq_kits.select(:machine_type, :kit_name).order(:machine_type, :kit_name).all.group_by(&:machine_type)
    return kits_by_machine_type.collect {|mtype, attrs| [mtype, attrs.collect{|attr| [attr.kit_name]}]}
  end

  def self.machine_type_kits
    #self.select(:container_type, :freezer_location_id).distinct().to_a()
    sql = "select distinct kit_name, machine_type from sequencer_kits;"
    result = ActiveRecord::Base.connection.exec_query(sql)
    result.rows
  end

end
