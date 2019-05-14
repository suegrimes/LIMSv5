# == Schema Information
#
# Table name: no_tables
#
#  company_name   :string
#  requester_name :string
#  item_status    :string
#  deliver_site   :string
#  from_date      :date
#  to_date        :date
#

class ItemQuery
  include ActiveModel::Model
  attr_accessor :company_name, :item_description, :requester_name, :ordered_status, :order_received_flag,
                :item_received_flag, :deliver_site, :from_date, :to_date

  validates_date :to_date, :from_date, :allow_blank => true

  STD_FIELDS = {'items' => %w(company_name requester_name deliver_site)}
  SEARCH_FLDS = {'items' => %w(item_description)}

  QUERY_FLDS = {'standard' => STD_FIELDS, 'multi_range' => {}, 'search' => SEARCH_FLDS}
end
