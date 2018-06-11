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
  has_many :sample_storage_containers

  # construct dropdown data rows  with columns:
  # freezer_location_id, container_type, container_name, container_id, count of samples in container
  # nr_rows, nr_cols
  # where each row represents a storage container
  def self.container_data
    sql = <<HERE
select ssc.freezer_location_id,ssc.container_type,ssc.container_name,ssc.storage_container_id,count(ssc.id),typ.nr_rows,typ.nr_cols
from storage_containers sc
  join storage_types typ on sc.container_type = typ.container_type
  join sample_storage_containers ssc on sc.container_type = ssc.container_type and sc.container_name = ssc.container_name
group by ssc.freezer_location_id, ssc.container_type, ssc.container_name;
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

end
