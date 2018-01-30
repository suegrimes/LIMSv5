class DissectedSamplesController < ApplicationController
  layout 'main/processing'

  before_action :dropdowns, :only => :edit

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
    else
      flash[:error] = 'Sample barcode not found, please try again'
      redirect_to :action => 'new_params'
    end
  end
  
  def edit
    @sample = Sample.find(params[:id])
    @source_sample = Sample.includes(:sample_characteristic).find(@sample.source_sample_id)
    @sample.build_sample_storage_container if @sample.sample_storage_container.nil?
  end
  
  def update
    @sample        = Sample.find(params[:id])
    @source_sample = Sample.find(@sample.source_sample_id)
    
    #if @sample.update_attributes(params[:sample])
    if @sample.update_attributes(update_params)
      #@source_sample.update_attributes(:sample_remaining => params[:source_sample][:sample_remaining]) if params[:source_sample]
      @source_sample.update_attributes(update_source_params) if params[:source_sample]
      flash[:notice] = 'Dissected sample was successfully updated'
      redirect_to(@sample)
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
      redirect_to samples_list1_path(:source_sample_id => params[:sample][:source_sample_id], :add_new => 'yes')
    else
      prepare_for_render_new(params[:sample][:source_sample_id])
      render :action => "new" 
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
  end

  # allow params for new sample save
  def create_params
    params.require(:sample).permit(
      :source_sample_id, :barcode_key, :sample_date, :tumor_normal, :sample_container,
      :vial_type, :amount_uom, :amount_initial, :sample_remaining, :comments,
      {sample_storage_container_attributes: [
        :sample_name_or_barcode, :container_type, :container_name,
        :position_in_container, :freezer_location_id
       ]}
    )
  end

  def update_source_params
    {sample_remaining: params.require(:source_sample).permit(:sample_remaining)}
  end

  def update_params
    create_params
  end

end
