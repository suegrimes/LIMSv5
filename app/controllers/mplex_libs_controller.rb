class MplexLibsController < ApplicationController
  include StorageManagement, SqlQueryBuilder
  layout 'main/main'
  #load_and_authorize_resource :class => 'SeqLib'

  before_action :dropdowns, :only => [:new, :edit]
  before_action :setup_dropdowns, :only => :setup_params

  def setup_params
   @from_date = (Date.today - 90).beginning_of_month
   @to_date   = Date.today
   @date_range = DateRange.new(@from_date, @to_date)
   @seq_lib   = SeqLib.new(:owner => (current_user.researcher ? current_user.researcher.researcher_name : nil),
                           :adapter_id => Adapter.default_adapter.id)
  end

  def new
    @requester = (current_user.researcher ? current_user.researcher.researcher_name : nil)
    barcode_key = (param_blank?(params[:seq_lib][:barcode_key]) ? SeqLib.next_lib_barcode : params[:seq_lib][:barcode_key])
    @seq_lib   = SeqLib.new(:library_type => 'M',
                            :owner => @requester,
                            :preparation_date => Date.today,
                            :barcode_key => barcode_key,
                            :adapter_id => params[:seq_lib][:adapter_id],
                            :alignment_ref_id => AlignmentRef.default_id)
    @seq_lib.build_sample_storage_container
    
    # Get sequencing libraries based on parameters entered
    @condition_array = define_lib_conditions(params)
    @singleplex_libs = SeqLib.includes(:mlib_samples, {:lib_samples => :processed_sample}).where(sql_where(@condition_array))
                             .order('barcode_key, lib_name').all.to_a
    if params[:excl_used] && params[:excl_used] == 'Y'
      @singleplex_libs.reject!{|s_lib| !s_lib.mlib_samples.empty?} #Exclude if already included in a multiplex library
    end
                                   
    # Populate lib_samples based on data in each sequencing library
    @lib_samples = []    
    @singleplex_libs.each_with_index do |s_lib, i|
      @lib_samples[i] = LibSample.new(:processed_sample_id => s_lib.lib_samples[0].processed_sample_id,
                                      :sample_name         => s_lib.lib_samples[0].sample_name,
                                      :source_DNA          => s_lib.lib_samples[0].source_DNA,
                                      :adapter_id          => s_lib.lib_samples[0].adapter_id,
                                      :index1_tag_id       => s_lib.lib_samples[0].index1_tag_id,
                                      :index2_tag_id       => s_lib.lib_samples[0].index2_tag_id,
                                      :enzyme_code         => s_lib.lib_samples[0].enzyme_code,
                                      :notes               => s_lib.lib_samples[0].notes)
    end     
    @checked = false
    render :action => 'new'
    #render :action => 'debug'
  end
  
  # GET /mplex_libs/1/edit
  def edit
    @seq_lib = SeqLib.includes(:lib_samples).find(params[:id])
    if @seq_lib.sample_storage_container.nil?
      @seq_lib.build_sample_storage_container
      @edit_lib_storage = false
    else
      @edit_lib_storage = true
      @storage_container_id = @seq_lib.sample_storage_container.storage_container_id
    end

  end

  # POST /mplex_libs
  def create
    @seq_lib       = SeqLib.new(create_params)
    @seq_lib[:library_type] = 'M'
    @seq_lib[:alignment_ref] = AlignmentRef.get_align_key(params[:seq_lib][:alignment_ref_id])

    if params[:which_container] and params[:which_container] == 'new'
      sample_storage_container_attributes = params[:seq_lib][:sample_storage_container_attributes]
      ok, emsg = create_storage_container(sample_storage_container_attributes)
      unless ok
        dropdowns
        flash[:error] = "Error: #{emsg}"
        redirect_to :action => 'setup_params'
        return
      end
    end

    #slib_params = array of arrays [][id, notes]; slib_ids = array of ids [id1, id2, ..]
    temp_params = params.to_unsafe_h
    lsample_params = temp_params[:lib_samples]

    if lsample_params.is_a?(Array)
      slib_params = lsample_params.collect{|lsample| [lsample[:splex_lib_id].to_i, lsample[:notes]]}
    elsif lsample_params.is_a?(Hash)
      slib_params = lsample_params.collect{|lkey, lsample| [lsample[:splex_lib_id].to_i, lsample[:notes]]}
    else
      slib_params = []
    end

    slib_params.delete_if{|sparam| sparam[0] == 0}
    slib_ids_checked = slib_params.collect{|sparam| sparam[0]}
    slib_ids_all = params[:lib_id].to_a

    splex_libs = SeqLib.includes(:lib_samples).where('seq_libs.id in (?)', slib_ids_checked).all
    error_found = false
    slib_tags = splex_libs.collect{|slib| [slib.lib_samples[0].index1_tag_id, slib.lib_samples[0].index2_tag_id] }
    slib_pools = splex_libs.collect{|slib| [slib.pool_id, slib.oligo_pool]}
    if slib_pools.uniq.size > 1 
      @seq_lib[:oligo_pool] =  'Multiple'
    elsif slib_pools.uniq.size == 1
      @seq_lib[:pool_id] = slib_pools[0][0]
      @seq_lib[:oligo_pool] = slib_pools[0][1]
    end
    
    if splex_libs.size > 1 && slib_tags.size == slib_tags.uniq.size # More than 1 library selected; All index tag combinations are unique,
      splex_libs.each do |s_lib|
        slib_notes = slib_params.assoc(s_lib.id)[1] #Find params array entry for this seq_lib.id, and extract notes field 
        @seq_lib.lib_samples.build(:processed_sample_id => s_lib.lib_samples[0].processed_sample_id,
                                   :sample_name         => s_lib.lib_samples[0].sample_name,
                                   :source_DNA          => s_lib.lib_samples[0].source_DNA,
                                   :adapter_id          => s_lib.lib_samples[0].adapter_id,
                                   :index1_tag_id       => s_lib.lib_samples[0].index1_tag_id,
                                   :index2_tag_id       => s_lib.lib_samples[0].index2_tag_id,
                                   :enzyme_code         => s_lib.lib_samples[0].enzyme_code,
                                   :splex_lib_id        => s_lib.id,
                                   :splex_lib_barcode   => s_lib.barcode_key,
                                   :notes               => slib_notes)
      end  
      if !@seq_lib.save
        error_found = true  # Validation or other error when saving to database
        flash.now[:error] = 'ERROR - Unable to create multiplex library'
      end
      
    elsif splex_libs.size < 2   #Only one sequencing library selected     
      flash.now[:error] = 'ERROR - Only one sequencing library selected for multiplexing'
      error_found = true 
      
    elsif slib_tags.size > slib_tags.uniq.size  # One or more duplicate tags
      flash.now[:error] = 'ERROR - Duplicate index tag combinations entered for this multiplex library'
      error_found = true
    end
     
    if error_found
      @singleplex_libs = SeqLib.includes(:lib_samples => :processed_sample).where('seq_libs.id IN (?)', slib_ids_all)
                               .order('barcode_key, lib_name')
      @lib_samples = []
      @singleplex_libs.each_with_index do |slib, i|
        @lib_samples[i] = LibSample.new(slib.lib_samples[0].attributes)
        if slib_ids_checked.include?(slib.id)
          @lib_samples[i][:splex_lib_id] = slib.id 
          @lib_samples[i][:notes] = slib_params.assoc(slib.id)[1]
        end
      end
      dropdowns
      render :action => 'new'
    else
     flash[:notice] = "Multiplex library successfully created from #{splex_libs.size} individual libraries"
     redirect_to(@seq_lib)
    end
    #render :action => 'debug'
  end

  # PUT /mplex_libs/1
  def update
    @seq_lib = SeqLib.find(params[:id])
    alignment_key = AlignmentRef.get_align_key(params[:seq_lib][:alignment_ref_id])
    params[:seq_lib].merge!(:alignment_ref => alignment_key)

    # See if new storage container is specified, and if so create it
    if (params[:new_storage_container])
      sample_storage_container_attributes = params[:seq_lib][:sample_storage_container_attributes]
      ok, emsg = create_storage_container(sample_storage_container_attributes)
      unless ok
        dropdowns
        flash[:error] = "Error: #{emsg}"
        redirect_to :action => 'edit', :id => @seq_lib.id
        return
      end
    end
     
    if @seq_lib.update_attributes(update_params)
      SeqLib.upd_mplex_fields(@seq_lib) if @seq_lib.barcode_key[0,1] == 'L'
      if @seq_lib.on_flow_lane?
        FlowLane.upd_lib_lanes(@seq_lib)
      end
      flash[:notice] = 'Multiplex library was successfully updated'
      redirect_to(@seq_lib) 
      
    else
      flash[:error] = 'ERROR - Unable to update sequencing library'
      dropdowns
      render :action => "edit"
    end
  end

  # DELETE /mplex_libs/1
  def destroy
    @seq_lib = SeqLib.find(params[:id])
    @seq_lib.destroy
    flash[:notice] = 'Multiplex sequencing library successfully deleted'
    redirect_to seq_libs_url
  end
  
protected
  def dropdowns
    @enzymes      = Category.populate_dropdown_for_category('enzyme')
    @align_refs   = AlignmentRef.populate_dropdown
    @projects     = Category.populate_dropdown_for_category('project')
    @owners       = Researcher.populate_dropdown('active_only')
    @protocols    = Protocol.find_for_protocol_type('L')
    @quantitation= Category.populate_dropdown_for_category('quantitation')
    @freezer_locations  = FreezerLocation.list_all_by_room
    # following for new Storage Management UI
    storage_container_ui_data
  end
  
  def setup_dropdowns
    @owners    =  Researcher.populate_dropdown('incl_inactive')
    @mplex_adapters  = Adapter.mplex_adapters
  end
  
  def define_lib_conditions(params)
    combo_fields = {:barcode_string => {:sql_attr => ['seq_libs.barcode_key'], :str_prefix => 'L', :pad_len => 6}}
    query_flds = {'standard' => {'seq_libs' => %w(owner adapter_id)}, 'multi_range' => combo_fields, 'search' => {}}
    query_params = params[:seq_lib].merge({:barcode_string => params[:barcode_string]})
    @where_select, @where_values = build_sql_where(query_params, query_flds, ["seq_libs.library_type = 'S'"], [])
                                     
    if params[:excl_used] && params[:excl_used] == 'Y'
      @where_select.push("seq_libs.lib_status <> 'F'")
    end
      
    date_fld = 'seq_libs.preparation_date'
    @where_select, @where_values = sql_conditions_for_date_range(@where_select, @where_values, params, date_fld)

    return sql_where_clause(@where_select, @where_values)
  end

  def create_params
    #Don't add blank container record
    container_params = params[:seq_lib][:sample_storage_container_attributes].to_unsafe_h
    container_params.delete(:sample_name_or_barcode)
    if params_all_blank?(container_params)
      params.require(:seq_lib).permit(*(lib_params + [sample_params]))
    else
      params.require(:seq_lib).permit(*(lib_params + [sample_params] + [storage_params]))
    end
  end

  def update_params
    #Don't add blank container record
    container_params = params[:seq_lib][:sample_storage_container_attributes].to_unsafe_h
    container_params.delete(:sample_name_or_barcode)
    if params_all_blank?(container_params)
      params.require(:seq_lib).permit(*(lib_params))
    else
      params.require(:seq_lib).permit(*(lib_params + [storage_params]))
    end
  end

  def lib_params
    [:barcode_key, :lib_name, :library_type, :lib_status, :protocol_id, :owner, :preparation_date, :adapter_id, :runtype_adapter,
     :project, :oligo_pool, :alignment_ref_id, :trim_bases, :sample_conc, :sample_conc_uom, :lib_conc_requested, :lib_conc_uom,
     :notebook_ref, :notes, :quantitation_method, :starting_amt_ng, :pcr_size, :dilution, :updated_by]
  end

  def sample_params
    {lib_samples_attributes: [
        :id, :splex_lib_id, :splex_lib_barcode, :processed_sample_id, :sample_name, :source_DNA, :runtype_adapter, :adapter_id,
        :index1_tag_id, :index2_tag_id, :enzyme_code, :notes, :updated_by
    ]}
  end

  def storage_params
    {sample_storage_container_attributes: [
        :id, :sample_name_or_barcode, :container_type, :container_name,
        :position_in_container, :storage_container_id, :freezer_location_id, :notes, :_destroy
    ]}
  end

end
