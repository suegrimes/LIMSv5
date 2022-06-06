class HistologiesController < ApplicationController
  layout  'main/main'
  #load_and_authorize_resource
  include StorageManagement
  before_action :dropdowns, :only => [:new, :edit, :edit_by_barcode, :edit_storage]
  
  def new_params
    authorize! :create, Histology
    render :action => 'new_params'
  end
  
  def new
    if param_blank?(params[:barcode_key])
      flash.now[:error] = 'Error - sample barcode cannot be blank'
      render :action => 'new_params'
      
    else
      @sample = Sample.includes(:sample_characteristic => :pathology).where('barcode_key = ?', params[:barcode_key]).first
      if @sample && @sample.histology.nil?
        # Determine next increment number for barcode suffix (only use this if allowing >1 H&E slide per sample)
        #he_barcode = Histology.next_he_barcode(@sample.id, @sample.barcode_key)
        @histology = Histology.new(:sample_id => @sample.id,
                                   :he_barcode_key => Histology.new_he_barcode(@sample.barcode_key),
                                   :he_date => Date.today)
        #@histology = @sample.build_histology
        @histology.build_sample_storage_container
        render :action => 'new'
        
      elsif @sample  #Have sample, and histology is not nil
        #flash[:notice] = 'H&E slide exists for sample barcode: ' + params[:barcode_key] 
        redirect_to :action => 'edit', :id => @sample.histology.id
        
      else
        flash.now[:error] = 'Error - sample barcode ' + params[:barcode_key] + ' not found'
        render :action => 'new_params'
      end
    end
  end
  
  def create
    @histology = Histology.new(create_params)
    _deliberate_error_here

    # If new storage container being created, add it before adding H&E slide
    if params[:which_container] and params[:which_container] == 'new'
      ok, emsg = create_storage_container(params[:histology][:sample_storage_container_attributes])
      unless ok
        flash[:error] = "Error: #{emsg}"
        prepare_for_render_new(@histology.sample_id)
        render :action => "new"
        return
      end
    end

    if @histology.save
      flash[:notice] = 'H&E slide was successfully created.'
      redirect_to(@histology)
    else
      prepare_for_render_new(@histology.sample_id)
      render :action => "new" 
    end
  end
  
  def edit
    @histology = Histology.includes(:sample_storage_container).find(params[:id])
    @edit_sample_storage = (@histology.sample_storage_container.nil? ? false : true)
  end

  def edit_by_barcode
    @histology = Histology.find_by_he_barcode_key(params[:barcode_key],
                          :include => {:sample => [{:sample_characteristic => :pathology}, :patient]})
    if @histology
      redirect_to :action => :edit, :id => @histology.id
    else
      flash[:error] = 'No entry found for H&E barcode: ' + params[:barcode_key]
      redirect_to :action => :new_params
    end
  end

  def edit_storage
    @histology = Histology.includes(:sample_storage_container).find(params[:id])
    @edit_sample_storage = (@histology.sample_storage_container.nil? ? false : true)
  end
  
  def update
    @histology = Histology.find(params[:id])
    #_deliberate_error_here

    if params[:new_storage_container]
      ok, emsg = create_storage_container(params[:histology][:sample_storage_container_attributes])
      unless ok
        #dropdowns
        flash[:error] = "Error: #{emsg}"
        redirect_to :action => 'edit', :id => @histology.id
        return
      end
    end

    if @histology.update_attributes(update_params)
      flash[:notice] = 'H&E slide was successfully updated'
      redirect_to(@histology)
    #render :action => 'debug'
    else
      flash[:error] = 'Error in updating H&E slide or location'
      redirect_to :action => 'edit'
    end
  end

  def show
    @histology = Histology.includes(:sample => [{:sample_characteristic => :pathology}, :patient]).find(params[:id])
    render :action => :show
  end

  def index
  end

# DELETE /patients/1
  def destroy
    @histology = Histology.find(params[:id])
    flash[:notice] = "H&E slide #{@histology.he_barcode_key} deleted"
    @histology.destroy  
    redirect_to :controller => :samples, :action => :edit_params
  end

  def auto_complete_for_barcode_key
    @histologies = Histology.where('he_barcode_key LIKE ?', params[:search]+'%').all
    render :inline => "<%= auto_complete_result(@histologies, 'he_barcode_key') %>"
  end

## Protected and private methods ##
protected
  def dropdowns
    @category_dropdowns = Category.populate_dropdowns([Cgroup::CGROUPS['Pathology'], Cgroup::CGROUPS['Histology']])
    @histopathology     = category_filter(@category_dropdowns, 'pathology')
    @inflam_type        = category_filter(@category_dropdowns, 'inflammation type')
    @inflam_infiltr     = category_filter(@category_dropdowns, 'inflammation infiltration')
    @freezer_locations  = FreezerLocation.list_all_by_room
    #@container_types = StorageType.populate_dropdown
    storage_container_ui_data
  end
  
  def prepare_for_render_new(sample_id)
    dropdowns
    @sample = Sample.includes(:sample_characteristic => :pathology).find(sample_id)
  end

  # define permitted attributes for strong parameters feature
  # cancancan will look for "create_params" and "update_params" methods while loading resources
  # so these are here to prevent an exception
  def create_params
    histology_params
  end

  def update_params
    histology_params
  end

  def histology_params
    params.require(:histology).permit(:sample_id, :he_barcode_key, :he_date, :histopathology, :he_classification,
           :pathologist, :tumor_cell_content, :inflammation_type, :inflammation_infiltration,
           :comments,
           sample_storage_container_attributes: [
               :id, :sample_name_or_barcode, :container_type, :container_name,
               :position_in_container, :freezer_location_id, :storage_container_id, :notes, :_destroy
           ]
    )
  end

end