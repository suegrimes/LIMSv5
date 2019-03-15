class OligoPoolsController < ApplicationController
  layout  'main/samples'

  # GET /oligo_pools
  def index
    @oligo_pools = Pool.order(:tube_label).all
  end

end
