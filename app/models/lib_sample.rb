# == Schema Information
#
# Table name: lib_samples
#
#  id                  :integer          not null, primary key
#  seq_lib_id          :integer
#  splex_lib_id        :integer
#  splex_lib_barcode   :string(20)
#  processed_sample_id :integer
#  sample_name         :string(50)
#  source_DNA          :string(50)
#  runtype_adapter     :string(50)
#  index_tag           :integer
#  adapter_id          :integer
#  index1_tag_id       :integer
#  index2_tag_id       :integer
#  enzyme_code         :string(50)
#  notes               :string(255)
#  updated_by          :integer
#  created_at          :datetime
#  updated_at          :timestamp
#

class LibSample < ApplicationRecord
  
  belongs_to :seq_lib, optional: true
  belongs_to :splex_lib, optional: true, class_name: 'SeqLib', foreign_key: :splex_lib_id
  belongs_to :processed_sample, optional: true
  belongs_to :adapter, optional: true
  belongs_to :index1_tag, optional: true, class_name: "IndexTag", foreign_key: :index1_tag_id
  belongs_to :index2_tag, optional: true, class_name: "IndexTag", foreign_key: :index2_tag_id
  
  #validates_presence_of :sample_name
  validates_presence_of :adapter_id, :if => Proc.new {|s| !s.seq_lib_id.nil? }
  validates_presence_of :index1_tag_id, :if => Proc.new{|s| !s.adapter_id.nil? && s.adapter.runtype_adapter[0,1] == 'M'}, :message => 'not supplied or not valid for given multiplex adapter'
   
  #def validate
  #  max_tags = (runtype_adapter == 'M_PE_Illumina' ? SeqLib::MILLUMINA_SAMPLES : SeqLib::MULTIPLEX_SAMPLES)
  #  if runtype_adapter == 'M_PE' && !index_tag.nil?
  #    errors.add(:index_tag, "must be in range 1 - #{max_tags} for #{runtype_adapter} adapter") if (index_tag < 1 || index_tag > max_tags)
  #  end
  #end

  before_create :upd_flds_from_lib
  before_save :set_index2

  # Validation, callbacks
  def set_index2
    if self.adapter && self.adapter.force_i2 == 'Y'
      i2tag_id = IndexTag.i2id_for_i1tag(self.index1_tag_id)
      self.index2_tag = IndexTag.find(i2tag_id)
    end
  end

  def upd_flds_from_lib
    self.sample_name = self.seq_lib.lib_name if self.sample_name.blank?
    self.adapter_id = self.seq_lib.adapter_id
    self.notes = self.seq_lib.notes if self.notes.blank? and self.splex_lib_id.nil?
  end

  # Pseudo attributes predominantly for bulk upload
  # At the point that adapter_i1/i2 is read, associated seq_lib has not been created, so cannot use adapter_id from seq_lib
  def adapter_i1=(index_code)
    unless index_code.blank?
      #self.adapter_id  = self.seq_lib.adapter_id
      adapter_itag = index_code.split(":")
      self.adapter = Adapter.where('runtype_adapter = ?', adapter_itag[0]).first
      self.index1_tag = IndexTag.where('adapter_id = ? and index_read = 1 and index_code = ?', self.adapter_id, adapter_itag[1]).first
    end
  end

  def adapter_i2=(index_code)
    unless index_code.blank?
      #self.adapter_id  = self.seq_lib.adapter_id
      adapter_itag = index_code.split(":")
      self.adapter = Adapter.where('runtype_adapter = ?', adapter_itag[0]).first
      self.index2_tag = IndexTag.where('adapter_id = ? and index_read = 2 and index_code = ?', self.adapter_id, adapter_itag[1]).first
    end
  end

  def source_sample_name=(barcode)
    self.source_DNA = barcode
    self.processed_sample = ProcessedSample.where("barcode_key = ?", barcode).first if !barcode.blank?
  end

  def singleplex_lib=(lib_barcode)
    #self.splex_lib_barcode = lib_barcode
    self.splex_lib = nil if lib_barcode.blank?

    if !lib_barcode.blank?
      #slib = SeqLib.find(:first, :include => :lib_samples, :conditions => ["library_type = 'S' AND barcode_key = ?", lib_barcode])
      slib = SeqLib.includes(:lib_samples).where("library_type = 'S' AND barcode_key = ?", lib_barcode).first
      if slib && slib.lib_samples
        ssample = slib.lib_samples[0]
        self.splex_lib = slib
        self.splex_lib_barcode = slib.barcode_key
        self.processed_sample_id = ssample.processed_sample_id
        self.sample_name = ssample.sample_name
        self.source_DNA  = ssample.source_DNA
        self.adapter_id = ssample.adapter_id
        self.index1_tag_id = ssample.index1_tag_id
        self.index2_tag_id = ssample.index2_tag_id
        self.enzyme_code = ssample.enzyme_code
      end
    end
  end

  # Virtual attributes
  def patient_id
    (!processed_sample.nil? ? processed_sample.patient_id : nil)
  end

  def adapter_name
    return (self.adapter.nil? ? '' : self.adapter.runtype_adapter)
  end

  def index1_tag_nr
    return (index1_tag.nil? ? '' : index1_tag.index_code)
  end

  def index2_tag_nr
    return (index2_tag.nil? ? '' : index2_tag.index_code)
  end

  def index1_tag_seq
    return (index1_tag.nil? ? '' : index1_tag.tag_sequence)
  end

  def index2_tag_seq
    return (index2_tag.nil? ? '' : index2_tag.tag_sequence)
  end

  def tag1_nr_seq
    return (index1_tag.nil? ? '' : [index1_tag.index_code, '(', index1_tag.tag_sequence, ')'].join)
  end

  def tag2_nr_seq
    return (index2_tag.nil? ? '' : [index2_tag.index_code, '(', index2_tag.tag_sequence, ')'].join)
  end

  def tag_sequence
    return [index1_tag_seq, index2_tag_seq].join(',')
  end
  
  def source_sample_name
    return source_DNA
  end

  def singleplex_lib
    return splex_lib_barcode
  end

  # Class methods
  def self.upd_mplex_sample_fields(seq_lib)
    lsample_attrs = {}
    
    # find_all_by is deprecated, use where
    #lib_samples = self.find_all_by_splex_lib_id(seq_lib.id)  # Find any multiplex libraries which include this single lib
    lib_samples = self.where(splex_lib_id: seq_lib.id)  # Find any multiplex libraries which include this single lib
    if lib_samples
      # Set up those attributes that come from lib_samples table of singleplex lib
      # Should always be one and only one lib_sample for a singleplex lib; but test for existence of lib_samples just in case
      lsample_attrs = {:index1_tag_id       => seq_lib.lib_samples[0].index1_tag_id,
                       :index2_tag_id       => seq_lib.lib_samples[0].index2_tag_id,
                       :sample_name         => seq_lib.lib_samples[0].sample_name,
                       :source_DNA          => seq_lib.lib_samples[0].source_DNA,
                       :processed_sample_id => seq_lib.lib_samples[0].processed_sample_id} if seq_lib.lib_samples
      # Set up those attributes that come from seq_libs table for singleplex lib
      lsample_attrs.merge!(:splex_lib_barcode => seq_lib.barcode_key,
                           :adapter_id   => seq_lib.adapter_id)
      # Update attributes for all multiplex samples which reference this singleplex lib
      self.upd_multi_lib_samples(lib_samples, lsample_attrs)
    end
  end
  
  def self.upd_multi_lib_samples(lib_samples, attrs)
    # Set up arrays of ids, and of attribute values, for SQL update of multiple lib_samples
    lib_sample_ids   = lib_samples.collect(&:id) if lib_samples
    if lib_sample_ids
      lib_sample_attrs = []
      lib_sample_ids.each_with_index {|lib_sample_id, i| lib_sample_attrs[i] = attrs} 
      self.update(lib_sample_ids, lib_sample_attrs)
    end
  end
end
