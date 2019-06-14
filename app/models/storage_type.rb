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

  def max_row
    if display_format == '2D'
      return (first_row == '1' ? nr_rows : ('A'.ord + nr_rows - 1).chr )
    else
      return nil
    end
  end

  def max_col
    if display_format == '2D'
      return (first_col == '1' ? nr_rows : ('A'.ord + nr_rows - 1).chr )
    else
      return nil
    end
  end

  def valid_positions
    return nil if display_format == '2D'
    grid_positions = []
    (first_col..max_col).each do |col|
      (first_row..max_row).each do |row|
        grid_positions.push([first_col.to_s, first_row.to_s].join())
      end
    end
    return grid_positions
  end

end
