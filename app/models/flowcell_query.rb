# == Schema Information
#
# Table name: flowcell_queries
#
#  run_nr_type  :string
#  run_nr       :string
#  machine_type :string
#  from_date    :date
#  to_date      :date
#
class FlowcellQuery
  include ActiveModel::Model

  attr_accessor :seq_run_nr, :hiseq_xref, :machine_type, :from_date, :to_date

  validates_format_of :seq_run_nr, :with => /\A\d+\z/, :allow_blank => true, :message => "must be an integer"
  validates_date :to_date, :from_date, :allow_blank => true

  STD_FIELDS  = {'flow_cells' => %w(machine_type seq_run_nr)}
  SEARCH_FLDS = {'flow_cells' => %w(hiseq_xref)}
  QUERY_FLDS = {'standard' => STD_FIELDS, 'multi_range' => {}, 'search' => SEARCH_FLDS}

  EXPORT_FLDS = {:hdgs => %w(DownloadDt RunNr AltRun ClusterKit SequencingKit Read1 Index1 Index2 Read2 Publication? Description Notes),
                 :flds => [['fc', 'seq_run_key'],
                           ['fc', 'hiseq_xref'],
                           ['fc', 'cluster_kit'],
                           ['fc', 'sequencing_kit'],
                           ['fc', 'nr_bases_read1'],
                           ['fc', 'nr_bases_index1'],
                           ['fc', 'nr_bases_index2'],
                           ['fc', 'nr_bases_read2'],
                           ['fc', 'for_publication?'],
                           ['fc', 'run_description'],
                           ['fc', 'notes']]}
end

