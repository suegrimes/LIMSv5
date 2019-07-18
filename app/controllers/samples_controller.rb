class SamplesController < ApplicationController
  include StorageManagement

  layout Proc.new {|controller| controller.request.xhr? ? false : 'main/main'}
  load_and_authorize_resource
  
  before_action :dropdowns, :only => [:new, :edit, :edit_by_barcode]

  def index
  end
  
  #########################################################################################
  #        Methods to show, edit, update samples                                          #
  #########################################################################################
  def show
    @sample_is_new = (params[:new_sample] ||= false)
    @sample = Sample.includes({:sample_characteristic => :pathology}, :patient, :histology, :sample_storage_container).find(params[:id])
  end
  
  # GET /samples/1/edit
  def edit
    @sample_is_new = (params[:new_sample] ||= false)
    @sample = Sample.includes(:sample_characteristic, :patient).find(params[:id])
    if @sample.sample_storage_container.nil?
      @sample.build_sample_storage_container
      @edit_sample_storage = false
    else
      @edit_sample_storage = true
      @storage_container_id = @sample.sample_storage_container.storage_container_id
    end

    # special edit form for ajax calls
    render :ajax_edit if request.xhr?
  end
  
  def edit_params 
    if request.post?
      btype = barcode_type(params[:barcode_key])
      case btype
        when 'S'
          redirect_to :action => :edit_by_barcode, :barcode_key => params[:barcode_key]
        when 'H'
          redirect_to :controller => :histologies, :action => :edit_by_barcode, :barcode_key => params[:barcode_key]
        when 'D', 'R', 'N', 'P'
          redirect_to :controller => :processed_samples, :action => :edit_by_barcode, :barcode_key => params[:barcode_key]      
        else
          flash[:notice] = 'Invalid barcode type - please try again'
          redirect_to :action => :edit_params
      end
    end
  end
  
  def edit_by_barcode
    @sample = Sample.find_by_barcode_key(params[:barcode_key])
    if @sample
      if @sample.clinical_sample == 'no' 
        redirect_to :controller => :dissected_samples, :action => :edit, :id => @sample.id
      else
        if @sample.sample_storage_container.nil?
          @sample.build_sample_storage_container
          @edit_sample_storage = false
        else
          @edit_sample_storage = true
          @storage_container_id = @sample.sample_storage_container.storage_container_id
        end
        # special edit form for ajax calls
        if request.xhr?
          render :ajax_edit
        else
          render :action => :edit
        end
      end
    else
      flash.now[:error] = 'No entry found for source barcode: ' + params[:barcode_key]
      render :action => :edit_params
    end
  end
  
  def update
    #  see if a new container is specified, if so create it
     if (params[:new_storage_container])
      sample_storage_container_attributes = params[:sample][:sample_storage_container_attributes]
      ok, emsg = create_storage_container(sample_storage_container_attributes)
      unless ok
        dropdowns
        flash[:error] = "Error creating storage container: #{emsg}"
        redirect_to :action => 'edit'
        #render :action => 'edit'
        return
      end
    end

    @sample = Sample.find(params[:id])

    #if @sample.update_attributes(update_params)
    # update_attributes is deprecated
    if @sample.update(update_params)
      flash[:notice] = 'Sample was successfully updated'
      if request.xhr?
        render :ajax_show
      else
        redirect_to(@sample)
      end
    else
      flash[:error] = 'Error updating sample'
      dropdowns
      @edit_sample_storage = (@sample.sample_storage_container ? true : false)
      render :action => 'edit'
    end
  end

  # DELETE /samples/1
  def destroy
    @sample = Sample.find(params[:id])
    patient_id = @sample.patient_id
    @sample.destroy

    redirect_to :controller => :sample_queries, :action => 'list_samples_for_patient', :patient_id => patient_id
  end
  
  def auto_complete_for_barcode_key
    @samples = Sample.where('barcode_key LIKE ?', params[:search]+'%').all
    render :inline => "<%= auto_complete_result(@samples, 'barcode_key') %>"
  end
  
  def testing
    @source_sample = Sample.find(params[:id]) 
    @new_barcode = Sample.next_dissection_barcode(@source_sample.id, @source_sample.barcode_key)
    render :action => 'debug'
  end

protected
  def dropdowns
    @category_dropdowns = Category.populate_dropdowns([Cgroup::CGROUPS['Sample'], Cgroup::CGROUPS['Clinical']])
    @tumor_normal       = category_filter(@category_dropdowns, 'tumor_normal')
    @source_tissue      = category_filter(@category_dropdowns, 'source tissue')
    @sample_type        = category_filter(@category_dropdowns, 'sample type')
    @preservation       = category_filter(@category_dropdowns, 'tissue preservation')
    @sample_units       = category_filter(@category_dropdowns, 'sample unit')
    @vial_types         = category_filter(@category_dropdowns, 'vial type')
    @amount_uom         = category_filter(@category_dropdowns, 'unit of measure') 
    #@containers         = category_filter(@category_dropdowns, 'container')
    @freezer_locations  = FreezerLocation.list_all_by_room
    # following for new Storage Management UI
    storage_container_ui_data
  end

  def update_params
    params.require(:sample).permit(
      :alt_identifier, :tumor_normal, :sample_tissue, :left_right, :sample_type, :tissue_preservation,
      :sample_container, :vial_type, :amount_uom, :amount_initial, :sample_remaining, :comments, :updated_by,
      sample_storage_container_attributes: [
        :sample_name_or_barcode, :container_type, :container_name,
        :position_in_container, :freezer_location_id, :storage_container_id, :notes
      ]
    )
  end

end
