# == Schema Information
#
# Table name: category_values
#
#  id          :integer          not null, primary key
#  category_id :integer          not null
#  c_position  :integer
#  c_value     :string(50)       not null
#  created_at  :datetime
#  updated_at  :datetime
#

class CategoryValue < ApplicationRecord
  belongs_to :category, optional: true
  
  def self.populate_dropdown_for_id(category_id)
    self.where(:category_id => category_id).order(:c_position).all
  end
  
end
