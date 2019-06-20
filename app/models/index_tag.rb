# == Schema Information
#
# Table name: index_tags
#
#  id              :integer          not null, primary key
#  adapter_id      :integer
#  runtype_adapter :string(25)
#  index_read      :integer
#  tag_nr          :integer
#  tag_sequence    :string(12)
#  created_at      :datetime
#  updated_at      :timestamp
#

class IndexTag < ActiveRecord::Base
  belongs_to :adapter

  def adapter_name
    return self.adapter.runtype_adapter
  end

  def rev_compl_seq
    return tag_sequence.tr('ACGT', 'TGCA').reverse
  end

  def tag_ctr
    (runtype_adapter == 'M_HLA192' ? tag_nr - 100 : tag_nr)
  end

  def self.find_tag_id(adapter_id, readnr, tag_nr)
    index_tag = self.where('adapter_id = ? AND index_read = ? AND tag_nr = ?', adapter_id, readnr, tag_nr).first
    return (index_tag.nil? ? nil : index_tag.id)
  end

  def self.i2id_for_i1tag(i1id)
    i1tag = self.find(i1id)
    i2tag_id =  (i1tag.nil? ? nil : self.where('adapter_id = ? and index_read = 2 and tag_nr = ?', i1tag.adapter_id, i1tag.tag_nr).pluck(:id))
    return (i2tag_id.nil? ? nil : i2tag_id[0])
  end

end

