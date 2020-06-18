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

    invalid_container = false; container_string = 'NA';
    params[:sample_loc][:sample_storage_containers_attributes].each do |idx, container_params|
      sscontainer = SampleStorageContainer.find_ssc_key(container_params[:freezer_location_id], container_params[:container_type],
                                            container_params[:container_name])
      container_string = [container_params[:container_type], container_params[:container_name]].join(': ')
      invalid_container = (sscontainer.nil? ? true : false)
      break if invalid_container
      params[:sample_loc][:sample_storage_containers_attributes][idx][:storage_container_id] = sscontainer.id
    end

    if invalid_container
      dropdowns
      flash.now[:error] = "ERROR - #{container_string} container not found in this freezer"
      render :action => 'edit'

    elsif @sample_loc.update_attributes(update_params)
      flash[:notice] = "Sample #{@sample_loc.barcode_key} location was successfully updated."
      redirect_to :action => 'show'

    else
      dropdowns
      flash[:error] = 'ERROR - Unable to update sample location'
      render :action => 'edit' 
    end
  end

  def show
    @sample_locs = SampleLoc.find_for_storage_query(["samples.id = ?", params[:id]]).to_a
    render 'sample_loc_queries/index'
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