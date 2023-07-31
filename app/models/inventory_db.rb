class InventoryDB < ActiveRecord::Base
  self.abstract_class = true
  #establish_connection(:oligo_inventory) if Rails.env != 'local_dev'
  establish_connection(:oligo_inventory) if Rails.env != 'development'
end
