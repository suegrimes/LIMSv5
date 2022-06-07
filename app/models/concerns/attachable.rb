module Attachable
  extend ActiveSupport::Concern
  def self.included(base)
    base.extend ClassMethods
  end

  #Define instance methods here
  #
  #Define class methods within ClassMethods module below
  module ClassMethods
    def self.getwith_attach(id)
      self.includes(:attached_files).find(id)
    end
  end

end
