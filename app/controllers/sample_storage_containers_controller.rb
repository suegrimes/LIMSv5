class SampleStorageContainersController < ApplicationController
  layout 'main/main'

  load_and_authorize_resource

  include StorageManagement
  before_action :dropdowns, :only => :edit

  # GET /sample_storage_containers/1/edit
  def edit
    @sample_storage_container = SampleStorageContainer.find(params[:id])
    @storage_container_id = @sample_storage_container.storage_container_id
    @source_obj = get_source_obj(@sample_storage_container)
    render :action => 'edit'
    #render :action => 'debug'
  end

  # PUT /sample_storage_containers/1
  def update
    @sample_storage_container = SampleStorageContainer.find(params[:id])

    if @sample_storage_container.update_attributes(update_params)
      flash[:notice] = 'Sample storage container was successfully updated.'
      redirect_to :controller => :storage_containers, :action => :list_contents, :id => @sample_storage_container.storage_container_id
    else
      dropdowns
      flash[:error] = 'ERROR - Unable to update sample storage container'
      render :action => 'edit'
    end
  end

  protected
  def dropdowns
    @freezer_locations = FreezerLocation.populate_dropdown
    @storage_types = StorageType.populate_dropdown
    # following for new Storage Management UI
    storage_container_ui_data
  end

  # define permitted attributes for strong parameters feature
  # cancancan will look for "create_params" and "update_params" methods while loading resources
  # so these are here to prevent an exception
  def create_params
    sample_storage_container_params
  end

  def update_params
    sample_storage_container_params
  end

  def sample_storage_container_params
    params.require(:sample_storage_container).permit(:container_type, :container_name, :position_in_container, :freezer_location_id,
                   :notes)
  end

  def get_source_obj(sample_storage_container)
    klass = Object.const_get(sample_storage_container.stored_sample_type)
    obj = klass.getwith_storage(sample_storage_container.stored_sample_id)
    return obj
  end

end
