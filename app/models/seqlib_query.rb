# == Schema Information
#
# Table name: seqlib_queries
#
#  owner         :string
#  project       :string
#  lib_name      :string
#  barcode_from  :string
#  barcode_to    :string
#  alignment_ref :string
#  from_date     :date
#  to_date       :date
#

class SeqlibQuery
  include ActiveModel::Model

  attr_accessor :patient_string, :owner, :project, :lib_name, :barcode_string, :alignment_ref, :from_date, :to_date

  validates_date :to_date, :from_date, :allow_blank => true

  SEARCH_FLDS = {'seq_libs' => %w(lib_name)}
  STD_FIELDS  = {'seq_libs' => %w(owner project alignment_ref), 'processed_samples' => %w(patient_id)}
  COMBO_FIELDS = {:patient_string => {:sql_attr => ['processed_samples.patient_id']},
                  :barcode_string => {:sql_attr => ['seq_libs.barcode_key'], :str_prefix => 'L', :pad_len => 6}}

  QUERY_FLDS = {'standard' => STD_FIELDS, 'multi_range' => COMBO_FIELDS, 'search' => SEARCH_FLDS}

end
