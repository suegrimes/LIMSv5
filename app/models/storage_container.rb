# == Schema Information
#
# Table name: storage_containers
#
# id int(10) unsigned NOT NULL AUTO_INCREMENT,
# container_type varchar(15) DEFAULT NULL,
# container_name varchar(25) DEFAULT NULL,
# freezer_location_id int(11) DEFAULT NULL,
# freezer_type varchar(20) DEFAULT NULL,
# notes varchar(255) DEFAULT NULL,
#

class StorageContainer < ApplicationRecord
  belongs_to :freezer_location
  belongs_to :storage_type, :foreign_key => :container_type
  has_many :sample_storage_containers

  validates_uniqueness_of :container_name, scope: [:freezer_location_id, :container_type]

  STD_FIELDS = {'storage_containers' => %w(freezer_location_id container_type)}
  QUERY_FLDS = {'standard' => STD_FIELDS, 'multi_range' => {}, 'search' => {}}

  def container_sort
    (container_name =~ /\A\d\Z/ ? '0' + container_name : container_name)
  end

  def self.find_sc_key(freezer_id, container_type, container_name)
    self.where("freezer_location_id = ? and container_type = ? and container_name = ?",
               freezer_id, container_type, container_name).first
  end

  def self.find_for_summary_query(condition_array)
    self.joins(:freezer_location)
        .left_joins(:sample_storage_containers)
        .where(sql_where(condition_array))
        .group(:freezer_location_id, :container_type, :container_name, :id, :room_nr, :freezer_nr, :owner_name)
        .count('sample_storage_containers.id')
  end

  # construct dropdown data rows  with columns:
  # freezer_location_id, container_type, container_name, container_id, count of samples in container
  # nr_rows, nr_cols
  # where each row represents a storage container
  def self.container_data
    sql = <<HERE
select sc.freezer_location_id,sc.container_type,sc.container_name,sc.id,count(ssc.id),typ.nr_rows,typ.nr_cols
from sample_storage_containers ssc
  join storage_containers sc on ssc.storage_container_id = sc.id
  join storage_types typ on sc.container_type = typ.container_type
group by sc.freezer_location_id, sc.container_type, sc.container_name;
HERE
    result = ActiveRecord::Base.connection.exec_query(sql)
    result.rows
  end
    
  def self.container_type_freezer
    #self.select(:container_type, :freezer_location_id).distinct().to_a()
    sql = "select distinct container_type,freezer_location_id from storage_containers;"
    result = ActiveRecord::Base.connection.exec_query(sql)
    result.rows
  end

  def container_contents
    sample_storage_containers.to_a
  end

  def positions_used
    container_fmt = storage_type ? storage_type.display_format[0,2] : 'NA'
    if container_fmt == '2D'
      return container_contents.inject([]) {|array, r| array << r.position_in_container }
    else
      return []
    end
  end


end
