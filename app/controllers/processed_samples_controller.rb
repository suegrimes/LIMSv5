class ProcessedSamplesController < ApplicationController
  include StorageManagement

  layout 'main/main'

  load_and_authorize_resource
  
  before_action :dropdowns, :only => [:new, :create, :edit, :edit_by_barcode, :update]
  
  autocomplete :processed_sample, :barcode_search
    
  # GET /processed_samples
  def index
    @processed_samples = ProcessedSample.find_all_incl_sample
  end
  
  def show_by_sample
    # find_all_by_ is deprecated
    #@processed_samples = ProcessedSample.find_all_by_sample_id(params[:sample_id])
    @processed_samples = ProcessedSample.where(sample_id: params[:sample_id])
    @sample  = Sample.find_by_id(params[:sample_id])
    render :action => 'index'
  end
  
  # GET /processed_samples/1
  def show
    @processed_sample = ProcessedSample.includes({:sample => {:sample_characteristic => :pathology}},
                                     {:lib_samples => :seq_lib}, :molecular_assays, :sample_storage_container)
                                    .find(params[:id])
  end
  
  def new_params
    
  end
  
  # GET /processed_samples/new
  def new
    # Find sample from which processed sample will be extracted
    if params[:source_id]
      @sample = Sample.includes(:sample_characteristic).find(params[:source_id])
    else
      @sample = Sample.includes(:sample_characteristic).where('barcode_key = ?', params[:barcode_key]).first
    end
    
    if @sample.nil?
      flash.now[:error] = 'Source sample barcode not found - please try again'
      render :action => 'new_params'
    
    #  proceed to new extraction screen if dissected sample barcode entered, or clinical sample has no dissections
    elsif @sample.clinical_sample == 'no' || Sample.where('samples.source_sample_id = ?', @sample.id).first.nil?

      # Populate date and default volume for new processed sample
      @processed_sample = ProcessedSample.new(:processing_date => Date.today,
                                              :protocol_id => 12,
                                              :vial => '2ml',
                                              :final_vol => 50,
                                              :elution_buffer => 'TB')
      @processed_sample.build_sample_storage_container
      render :action => 'new'
      
    else  # clinical sample with one or more dissections, so show list to select from
      @samples = Sample.where('samples.id = ? OR samples.source_sample_id = ?', @sample.id, @sample.id).order('samples.barcode_key').all
      render :action => 'new_list'
    end
  end

  def edit_by_barcode
    @processed_sample = ProcessedSample.find_one_incl_patient(["processed_samples.barcode_key = ?", params[:barcode_key]])
    if @processed_sample
      if @processed_sample.sample_storage_container.nil?
        @processed_sample.build_sample_storage_container
        @edit_sample_storage = false
      else
        @storage_container_id = @processed_sample.sample_storage_container.storage_container_id
        @edit_sample_storage = true
      end
      # special edit form for ajax calls, otherwise defaults to standard :edit view
      render :ajax_edit if request.xhr?
    else
      flash[:error] = 'No entry found for extraction barcode: ' + params[:barcode_key]
      redirect_to :controller => :samples, :action => :edit_params
    end
  end
  
  # GET /processed_samples/1/edit
  def edit
    @processed_sample = ProcessedSample.find_one_incl_patient(["processed_samples.id = ?", params[:id]])
    if @processed_sample.sample_storage_container.nil?
      @processed_sample.build_sample_storage_container
      @edit_sample_storage = false
    else
      @storage_container_id = @processed_sample.sample_storage_container.storage_container_id
      @edit_sample_storage = true
    end
    # special edit form for ajax calls, otherwise defaults to standard :edit view
    render :ajax_edit if request.xhr?
    #render :action => 'debug'
  end

  # POST /processed_samples
  def create
    @processed_sample = ProcessedSample.new(create_params)
    @sample = Sample.find(params[:processed_sample][:sample_id])

    #this_is_a_deliberate_error
    
    Sample.transaction do
      @processed_sample.save!
      if params[:processed_sample][:input_amount]
        params[:sample].merge!(:amount_rem => @sample.amount_rem - params[:processed_sample][:input_amount].to_f)
      end
      if params[:sample]
        @sample.update_attributes!(update_sample_params)
      end
      flash[:notice] = 'Processed sample was successfully created'
      redirect_to(:action => 'show_by_sample',
                  :sample_id => params[:processed_sample][:sample_id])
    end

  rescue ActiveRecord::RecordInvalid
      dropdowns
      #flash[:notice] = 'Error adding processed sample - Please contact system admin'
      render :action => "new"
  end

  # PUT /processed_samples/1
  # PUT /processed_samples/1.xml
  def update
    @processed_sample = ProcessedSample.find(params[:id])
 
    ProcessedSample.transaction do
      @processed_sample.update_attributes!(update_params)
      flash[:notice] = 'Processed sample successfully updated'
      redirect_to(@processed_sample)
    end

  rescue ActiveRecord::RecordInvalid
    if @processed_sample.sample_storage_container.nil?
      @processed_sample.build_sample_storage_container
      @edit_sample_storage = false
    else
      @storage_container_id = @processed_sample.sample_storage_container.storage_container_id
      @edit_sample_storage = true
    end
    render :action => "edit"
  end

  # DELETE /processed_samples/1
  def destroy
    @processed_sample = ProcessedSample.find(params[:id])
    @processed_sample.destroy
    
    redirect_to :action => :show_by_sample, :sample_id => @processed_sample.sample_id
  end
  
  def testing
    @sql_mask = mask_barcode('6451A.D01')
    render :action => 'debug'
  end
  
  #def auto_complete_for_barcode_key
  def autocomplete_processed_sample_barcode_search
    @processed_samples = ProcessedSample.barcode_search(params[:term])
    #render :inline => "<%= auto_complete_result(@processed_samples, 'barcode_key') %>"
    list = @processed_samples.map {|ps| Hash[ id: ps.id, label: ps.barcode_key, name: ps.barcode_key]}
    render json: list
  end

protected
  def dropdowns
    @category_dropdowns = Category.populate_dropdowns([Cgroup::CGROUPS['Sample'], Cgroup::CGROUPS['Extraction']])
    @extraction_type    = category_filter(@category_dropdowns, 'extraction type')
    @amount_uom         = category_filter(@category_dropdowns, 'unit of measure')
    @support            = category_filter(@category_dropdowns, 'support')
    @elution_buffer     = category_filter(@category_dropdowns, 'elution buffer')
    @vial_vol           = category_filter(@category_dropdowns, 'vial volume')
    @protocols          = Protocol.find_for_protocol_type('E')  #Extraction protocols
    @containers         = category_filter(@category_dropdowns, 'container')
    @freezer_locations  = FreezerLocation.all
    # following for new Storage Management UI
    storage_container_ui_data
  end

  def create_params
    #Don't add blank container record
    container_params = params[:processed_sample][:sample_storage_container_attributes].to_unsafe_h
    container_params.delete(:sample_name_or_barcode)
    if params_all_blank?(container_params)
      params.require(:processed_sample).permit(*(sample_params))
    else
      params.require(:processed_sample).permit(*(sample_params + [storage_params]))
    end
  end

  def update_params
    create_params
    #params.require(:processed_sample).permit(*(sample_params + [storage_params]))
  end

  def sample_params
    [:sample_id, :barcode_key, :patient_id, :input_uom, :extraction_type, :processing_date, :protocol_id, :vial,
     :support, :elution_buffer, :final_vol, :final_conc, :psample_remaining, :final_a260_a280, :final_a260_a230,
     :final_rin_nr, :comments, :updated_by]
  end

  def storage_params
    {sample_storage_container_attributes: [
      :id, :sample_name_or_barcode, :container_type, :container_name,
      :position_in_container, :storage_container_id, :freezer_location_id, :notes, :_destroy
    ]}
  end

  def update_sample_params
    params.require(:sample).permit(:amount_rem, :sample_remaining)
  end

 end
