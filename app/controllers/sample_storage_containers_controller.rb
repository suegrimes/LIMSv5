class SampleStorageContainersController < ApplicationController
  layout 'main/main'

  load_and_authorize_resource

  include StorageManagement
  before_action :dropdowns, :only => [:new, :edit, :edit_from_source]

  def new
    klass = Object.const_get(params[:model_class])
    @source_obj = klass.find(params[:id])
    @source_obj.build_sample_storage_container
  end

  # POST /sample_storage_containers
  def create
    @sample_storage_container = SampleStorageContainer.new(create_params)

    if @sample_storage_container.save
      flash[:notice] = 'Sample storage container was successfully created.'
      redirect_to :controller => @sample_storage_container.stored_sample_type.tableize, :action => 'show',
                  :id => @sample_storage_container.stored_sample_id
    else
      render :action => "new"
    end
  end

  # GET /sample_storage_containers/1/edit
  def edit
    @sample_storage_container = SampleStorageContainer.find(params[:id])
    klass = Object.const_get(@sample_storage_container.stored_sample_type)
    @source_obj = klass.find(@sample_storage_container.stored_sample_id)
    render :action => 'edit'
  end
  #
  def edit_from_source
    klass = Object.const_get(params[:model_class])
    @source_obj = klass.find(params[:source_id])
    @sample_storage_container = @source_obj.sample_storage_container
    render :action => 'edit'
    #render :action => 'debug'
  end

  # PUT /sample_storage_containers/1
  def update
    @sample_storage_container = SampleStorageContainer.find(params[:id])

    if @sample_storage_container.update_attributes(update_params)
      flash[:notice] = 'Sample storage container was successfully updated.'
      redirect_to :controller => @sample_storage_container.stored_sample_type.tableize, :action => 'show',
        :id => @sample_storage_container.stored_sample_id
    else
      dropdowns
      flash[:error] = 'ERROR - Unable to update sample storage container'
      render :action => 'edit'
    end
  end

  def destroy
    @sample_storage_container = SampleStorageContainer.find(params[:id])
    container_id = @sample_storage_container.storage_container_id
    @sample_storage_container.destroy
    redirect_to container_contents_url(id: container_id), notice: 'Sample deleted from storage container'
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
