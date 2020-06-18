class PsampleLocsController < ApplicationController
  layout 'main/main'
  before_action :dropdowns, :only => [:edit]

  # GET /psample_locs/1/edit
  def edit
    @psample_loc = PsampleLoc.includes(:sample_storage_containers).find(params[:id])
    authorize! :edit, SampleStorageContainer
    render :action => 'edit'
  end

  # PUT /psample_locs/1
  def update
    @psample_loc = PsampleLoc.find(params[:id])
    authorize! :update, SampleStorageContainer

    invalid_container = false; container_string = 'NA';
    params[:psample_loc][:sample_storage_containers_attributes].each do |idx, container_params|
      sscontainer = SampleStorageContainer.find_ssc_key(container_params[:freezer_location_id], container_params[:container_type],
                                                        container_params[:container_name])
      container_string = [container_params[:container_type], container_params[:container_name]].join(': ')
      invalid_container = (sscontainer.nil? ? true : false)
      break if invalid_container
      params[:psample_loc][:sample_storage_containers_attributes][idx][:storage_container_id] = sscontainer.id
    end

    if invalid_container
      dropdowns
      flash.now[:error] = "ERROR - #{container_string} container not found in this freezer"
      render :action => 'edit'

    elsif @psample_loc.update_attributes(update_params)
      flash[:notice] = "Sample #{@psample_loc.barcode_key} location was successfully updated."
      redirect_to :action => 'show', :sample_id => @psample_loc.sample_id

    else
      dropdowns
      flash[:error] = 'ERROR - Unable to update processed sample location'
      render :action => 'edit' 
    end
  end

  def show
    @sample_locs = SampleLoc.find_for_storage_query(["samples.id = ?", params[:sample_id]]).to_a
    render 'sample_loc_queries/index'
  end

protected
  def dropdowns
    @freezer_locations  = FreezerLocation.list_all_by_room
    @container_types = StorageType.populate_dropdown
  end

  def update_params
    params.require(:psample_loc).permit(
        :processing_date, :extraction_type, :vial, :support, :elution_buffer, :final_vol, :final_conc, :psample_remaining,
        sample_storage_containers_attributes: [
            :id, :sample_name_or_barcode, :container_type, :container_name,
            :position_in_container, :freezer_location_id, :storage_container_id, :notes, :_destroy
        ]
    )
  end

end