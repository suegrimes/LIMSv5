# == Schema Information
#
# Table name: researchers
#
#  id                  :integer          not null, primary key
#  user_id             :integer
#  researcher_name     :string(50)       not null
#  researcher_initials :string(3)        not null
#  company             :string(50)
#  phone_number        :string(20)
#  active_inactive     :string(1)
#

class Researcher < ApplicationRecord
  belongs_to :user, optional: true
  
  #scope :active, :conditions => {:active_inactive => 'A'}
  scope :active, -> { where(active_inactive: 'A') }

  def self.populate_dropdown(active_flag='active_only', add_existing = [])
    if active_flag == 'active_only'
      researchers = self.active.order(:researcher_name).pluck(:researcher_name)
    else
      #researchers = self.find(:all, :order => "active_inactive, researcher_name").collect(&:researcher_name)
      researchers = self.order("active_inactive, researcher_name").pluck(:researcher_name)
    end
    if add_existing.nil?
      return researchers
    else
      return researchers | add_existing.to_a
    end
  end

  def self.find_user_id(user_name)
    researcher = self.where('researcher_name = ?', user_name).first if !user_name.blank?
    return (researcher ? researcher.user_id : 1)
  end

  def self.find_and_group_by_active_inactive
    researchers = self.joins(:user).includes(:user).order("researchers.active_inactive, researchers.researcher_name").all
    #researchers = self.find(:all, :order => "researchers.active_inactive, researchers.researcher_name")
    return researchers.group_by {|researcher| researcher.active_inactive}
  end

end
