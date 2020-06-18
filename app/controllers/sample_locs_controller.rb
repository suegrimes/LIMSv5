class SampleLocsController < ApplicationController
  layout 'main/main'
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

    sscontainers = []
    params[:sample_loc][:sample_storage_containers_attributes].each do |idx, container_params|
      sscontainers[idx.to_i] = SampleStorageContainer.find_ssc_key(container_params[:freezer_location_id], container_params[:container_type],
                                            container_params[:container_name])
      params[:sample_loc][:sample_storage_containers_attributes][idx][:storage_container_id] = sscontainers[idx.to_i]
    end

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
    @container_types = StorageType.populate_dropdown
  end

  def update_params
    params.require(:sample_loc).permit(
        :alt_identifier, :tumor_normal, :sample_tissue, :left_right, :sample_type, :tissue_preservation,
        :sample_container, :vial_type, :amount_uom, :amount_initial, :sample_remaining, :comments,
        sample_storage_containers_attributes: [
            :id, :sample_name_or_barcode, :container_type, :container_name,
            :position_in_container, :freezer_location_id, :storage_container_id, :notes, :_destroy
        ]
    )
  end

end