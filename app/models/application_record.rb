class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
  validates_lengths_from_database
end
