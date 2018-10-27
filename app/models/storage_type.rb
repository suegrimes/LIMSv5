# == Schema Information
#
# Table name: storage_types
#
# id int(10) unsigned NOT NULL AUTO_INCREMENT,
# container_type varchar(15) NOT NULL,
# nr_rows smallint(6) DEFAULT NULL,
# nr_cols smallint(6) DEFAULT NULL,
# first_row char(1) DEFAULT NULL,
# first_col char(1) DEFAULT NULL,
# freezer_type varchar(20) DEFAULT NULL,
# notes varchar(255) DEFAULT NULL,
#

class StorageType < ApplicationRecord

 def self.container_dimensions
    #self.select(:container_type, :freezer_location_id).distinct().to_a()
    sql = "select container_type,display_format,nr_rows,nr_cols,first_row,first_col from storage_types;"
    result = ActiveRecord::Base.connection.exec_query(sql)
    result.rows
 end

 def self.populate_dropdown
   self.all
 end

end
