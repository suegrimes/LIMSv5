class DissectedSamplesController < ApplicationController
  include StorageManagement

  layout  Proc.new {|controller| controller.request.xhr? ? false : 'main/main'}

  #before_action :dropdowns, :only => :edit
  before_action :dropdowns, :only => [:edit, :add_multi]

  def index
  end

  def new_params  
  end
  
  # GET /dissected_samples/new
  def new
    authorize! :create, Sample
    
    if params[:source_sample_id]
      @source_sample = Sample.includes(:histology).find(params[:source_sample_id])
    else
      @source_sample = Sample.includes(:histology).where('barcode_key = ?',params[:barcode_key]).first
    end 
    
    if !@source_sample.nil?
      prepare_for_render_new(@source_sample.id)
      sample_params = {:barcode_key      => @sample_barcode,
                       :source_sample_id => @source_sample.id,
                       :amount_uom       => 'Weight (mg)',
                       :sample_date      => Date.today}
      @sample = Sample.new(sample_params)  
      @sample.build_sample_storage_container
      render :ajax_new if request.xhr?
    else
      flash[:error] = 'Sample barcode not found, please try again'
      redirect_to :action => 'new_params'
    end
  end
  
  def edit
    @sample = Sample.find(params[:id])
    @source_sample = Sample.includes(:sample_characteristic).find(@sample.source_sample_id)
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
  
  def update
    @sample        = Sample.find(params[:id])
    @source_sample = Sample.find(@sample.source_sample_id)
    
    #if @sample.update_attributes(params[:sample])
    if @sample.update_attributes(update_params)
      #@source_sample.update_attributes(:sample_remaining => params[:source_sample][:sample_remaining]) if params[:source_sample]
      @source_sample.update_attributes(update_source_params) if params[:source_sample]
      flash[:notice] = 'Dissected sample was successfully updated'
      if request.xhr?
        render :ajax_show
      else
        redirect_to(@sample)
      end
    else
      flash[:error] = 'Error updating dissected sample'
      redirect_to :action => 'edit'
    end
  end
  
  # POST /dissected_samples
  def create
    authorize! :create, Sample
    
    params[:sample].merge!(:amount_rem => params[:sample][:amount_initial].to_f)
    #@sample        = Sample.new(params[:sample])
    @sample        = Sample.new(create_params)
    @source_sample = Sample.find(params[:sample][:source_sample_id])

    if @sample.save
      #@source_sample.update_attributes(:sample_remaining => params[:source_sample][:sample_remaining]) if params[:source_sample]
      @source_sample.update_attributes(update_source_params) if params[:source_sample]
      flash[:notice] = 'Sample successfully created'
      if request.xhr?
        render :ajax_show
      else
        redirect_to samples_list1_path(:source_sample_id => params[:sample][:source_sample_id], :add_new => 'yes')
      end
    else
      prepare_for_render_new(params[:sample][:source_sample_id])
      render :action => "new" 
    end
  end

  # add multiple dissections
  def add_multi
    begin
      @sample = Sample.includes(:sample_characteristic, :patient).find(params[:id])
    rescue ActiveRecord::RecordNotFound
      flash[:error] = "Source sample not found, id: #{params[:id]}"
      redirect_back fallback_location:  {:action => 'new_params'}
      return
    end
    @sample.build_sample_storage_container if @sample.sample_storage_container.nil?
    @next_barcode_key = Sample.next_dissection_barcode(@sample.id, @sample.barcode_key)
  end
  
  # create multiple dissections in one request
  # return a JSON response with array of saved ids and any error(s) that may have occured
  # operation will stop after the first dissection save that fails
  # return status 201 CREATED if any were created and 200 OK if not
  # actual save error messages and status will be packaged in the JSON repsonse
  def create_multi
    authorize! :create, Sample
logger.debug "#{self.class}#create_multi: request.xhr: #{request.xhr?}"

    @source_sample_id = params[:id]
    return bad_request_error("Missing source sample id parameter") if @source_sample_id.nil?
    @source_sample = Sample.find(@source_sample_id)
    return bad_request_error("Cannot find source sample for id: #{@source_sample_id}") if @source_sample.nil?

    # convert hash with index keys to an array of sample params hashes
    @sample_params_hash = params[:sample]
    return bad_request_error("Missing sample parameter") if @sample_params_hash.nil?
    @sample_params_array = []
    @sample_params_hash.each do |k, v|
      i = k.to_i
      return  bad_request_error("Unexpected key value: #{k}") if (i > 25 || (i == 0 && k != "0"))
      @sample_params_array[i] = v 
    end
    @sample_params_array.compact!
    @saved_ids = []
    @sample_params_array.each do |sample|
      sample.merge!(amount_rem: sample[:amount_initial].to_f)
      sample.merge!(source_sample_id: @source_sample_id)

      @sample = Sample.new(sample.permit(*create_multi_attr))
      unless @sample.save
        # on error we stop saving and return errors on failing object
        if @saved_ids.size > 0
          flash[:notice] = "#{@saved_ids.size} Dissections saved" 
        end
        flash[:error] = "#{@sample_params_array.size - @saved_ids.size} Dissections not saved"

        respond_to do |format|
          format.json do
            render json: {
              saved_ids: @saved_ids,
              last_status: :unprocessable_entity,
              errors: @sample.errors.full_messages
            }, status: :ok
          end
        end
        return
      end
      @saved_ids << @sample.id
    end
    flash[:notice] = "All #{@sample_params_array.size} Dissections successfully created"
    respond_to do |format|
      format.json do
        render json: {saved_ids: @saved_ids}, status: :created
      end
    end
  end
  
protected
  def prepare_for_render_new(source_sample_id)
    # Find source sample, and sample characteristic associated with new (dissected) sample
    @source_sample    = Sample.find(source_sample_id)
    @sample_characteristic = SampleCharacteristic.find(@source_sample.sample_characteristic_id)
    
    # Determine next increment number for barcode suffix
    @sample_barcode = Sample.next_dissection_barcode(source_sample_id, @source_sample.barcode_key)
    
    # populate drop-down lists
    dropdowns
  end
  
  def dropdowns
    @category_dropdowns = Category.populate_dropdowns([Cgroup::CGROUPS['Sample']])
    @tumor_normal       = category_filter(@category_dropdowns, 'tumor_normal')
    @amount_uom         = category_filter(@category_dropdowns, 'unit of measure') 
    @sample_units       = category_filter(@category_dropdowns, 'sample unit')
    @vial_types         = category_filter(@category_dropdowns, 'vial type')
    @containers         = category_filter(@category_dropdowns, 'container')
    @freezer_locations  = FreezerLocation.list_all_by_room
    # following for new Storage Management UI
    storage_container_ui_data
  end

  # allow params for new sample save
  def create_params
    params.require(:sample).permit(
      :source_sample_id, :barcode_key, :sample_date, :tumor_normal, :sample_container,
      :vial_type, :amount_uom, :amount_initial, :amount_rem, :sample_remaining, :comments,
      {sample_storage_container_attributes: [
        :sample_name_or_barcode, :container_type, :container_name,
        :position_in_container, :freezer_location_id
      ]}
    )
  end

  def create_multi_attr
    [:source_sample_id, :barcode_key, :sample_date, :tumor_normal, :sample_container,
    :vial_type, :amount_uom, :amount_initial, :amount_rem, :sample_remaining, :comments,
    sample_storage_container_attributes: [
      :container_type, :container_name, :position_in_container, :freezer_location_id
      ]
    ]
  end

  def update_source_params
    {sample_remaining: params.require(:source_sample).permit(:sample_remaining)}
  end

  def update_params
    create_params
  end

end
