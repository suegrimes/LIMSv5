module Storable
  extend ActiveSupport::Concern
  def self.included(base)
    base.extend ClassMethods
  end

  #Define instance methods here
  #
  #Define class methods within ClassMethods module below
  module ClassMethods
    def getwith_storage(id)
      self.includes(:sample_storage_container).find(id)
    end
  end

end
