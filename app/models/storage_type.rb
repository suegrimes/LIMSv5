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
  self.primary_key = :container_type

  def self.container_dimensions
    #self.select(:container_type, :freezer_location_id).distinct().to_a()
    sql = "select container_type,display_format,nr_rows,nr_cols,first_row,first_col from storage_types;"
    result = ActiveRecord::Base.connection.exec_query(sql)
    result.rows
  end

  def self.populate_dropdown
    self.all
    #self.pluck(:container_type)
  end

  def display_in_grid?
    display_format[0..1] == '2D'
  end

  def max_row
    if display_in_grid?
      return (first_row == '1' ? nr_rows.to_s : ('A'.ord + nr_rows - 1).chr )
    else
      return nil
    end
  end

  def max_col
    if display_in_grid?
      return (first_col == '1' ? nr_cols.to_s : ('A'.ord + nr_cols - 1).chr )
    else
      return nil
    end
  end

  def grid_rows
    if !display_in_grid?
      return nil
    elsif display_format == '2Dseq'
      return [*1..nr_rows].map(&:to_s)
    else
      return [*first_row..max_row]
    end
  end

  def grid_cols
    if !display_in_grid?
      return nil
    elsif display_format == '2Dseq'
      return [*1..nr_cols].map(&:to_s)
    else
      return [*first_col..max_col]
    end
  end

  def valid_positions
    if !display_in_grid?
      return nil
    elsif display_format == '2Dseq'
      return [*1..nr_rows*nr_cols].map(&:to_s)
    else
      grid_positions = []
      (first_col..max_col).each do |col|
        (first_row..max_row).each do |row|
          grid_positions.push([col, row].join())
        end
      end
      return grid_positions
    end
  end

end
