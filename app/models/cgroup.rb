# == Schema Information
#
# Table name: cgroups
#
#  id         :integer          not null, primary key
#  group_name :string(25)       not null
#  sort_order :integer
#  created_at :datetime
#  updated_at :timestamp
#

# == Schema Information
#
# Table name: cgroups
#
#  id         :integer(4)      not null, primary key
#  group_name :string(25)      default(""), not null
#  sort_order :integer(2)
#  created_at :datetime
#  updated_at :timestamp
#
#TODO: Replace hardcoded CGROUPS with version derived from SQL table
class Cgroup < ApplicationRecord
  has_many :categories

  CGROUP_IDS = Cgroup.all.collect { |grp| [grp.group_name, grp.id] }.to_h
  
  CGROUPS = {'Clinical'    => '1',
             'Sample'      => '2',
             'Extraction'  => '3',
             'Seq Library' => '4',
             'Sequencing'  => '5',
             'Imaging'     => '10',
             'Pathology'   => '6',
             'Histology'   => '7'}
  
end
