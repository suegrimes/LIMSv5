class SampleLocsController < ApplicationController

  before_action :dropdowns, :only => [:edit]

  # GET /sample_locs/1/edit
  def edit
    @sample_loc = SampleLoc.includes(:sample_storage_containers).find(params[:id])
    authorize! :edit, SampleStorageContainer
    render :action => 'edit'
  end

  # PUT /sample_locs/1
  def update
    @sample_loc = SampleLoc.find(params[:id])
    authorize! :update, SampleStorageContainer

    if @sample_loc.update_attributes(update_params)
      flash[:notice] = 'Sample location was successfully updated.'
      redirect_to edit_sample_loc_path(@sample_loc)
    else
      dropdowns
      flash[:error] = 'ERROR - Unable to update sample location'
      render :action => 'edit' 
    end
  end

protected
  def dropdowns
    @freezer_locations  = FreezerLocation.list_all_by_room
  end

  def update_params
    params.require(:sample_loc).permit(
        :alt_identifier, :tumor_normal, :sample_tissue, :left_right, :sample_type, :tissue_preservation,
        :sample_container, :vial_type, :amount_uom, :amount_initial, :sample_remaining, :comments,
        sample_storage_container_attributes: [
            :sample_name_or_barcode, :container_type, :container_name,
            :position_in_container, :freezer_location_id, :storage_container_id, :notes
        ]
    )
  end

end