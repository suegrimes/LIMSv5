class SeqLibsController < ApplicationController
  include StorageManagement

  layout 'main/main'
  #load_and_authorize_resource (# can't use because create method for singleplex lib has array of seq_libs instead of single lib) '

  before_action :dropdowns, :only => [:new, :edit, :populate_libs]
  before_action :query_dropdowns, :only => :query_params

  # GET /seq_libs
  # This method is used to show all libs just added (via params[:lib_id] array)
  def index
    authorize! :read, SeqLib
    if params[:lib_id]
      @seq_libs = SeqLib.where(id: params[:lib_id].to_a).order('seq_libs.preparation_date DESC')
    else
      @seq_libs = SeqLib.order('seq_libs.preparation_date DESC').all
    end
    render :action => 'index'
  end
  
  # GET /seq_libs/1
  def show
    @seq_lib = SeqLib.includes({:lib_samples => :splex_lib}, :attached_files).find(params[:id])
    @protocol = Protocol.find(@seq_lib.protocol_id) if @seq_lib.protocol_id
    authorize! :read, @seq_lib
  end
  
  # GET /seq_libs/new
  def new
    authorize! :create, SeqLib
    @requester = (current_user.researcher ? current_user.researcher.researcher_name : nil)
    @lib_default = SeqLib.new(:alignment_ref_id => AlignmentRef.default_id)
    render :action => 'new'
  end

  # GET /seq_libs/1/edit
  def edit
    @seq_lib = SeqLib.includes(:lib_samples).find(params[:id])
    authorize! :edit, @seq_lib
    # ToDo:  Add existing owner to drop-down list if he/she is inactive
    
    if @seq_lib.library_type == 'M'
      redirect_to :controller => 'mplex_libs', :action => :edit, :id => params[:id]
    else
      if !@seq_lib.adapter_id.nil?
        adapter = Adapter.find(@seq_lib.adapter_id)
        @i1_tags = adapter.index1_tags
        @i2_tags = adapter.index2_tags
      else
        @i1_tags = []
        @i2_tags = []
      end
      render :action => 'edit'
    end
  end
  
  # Used to populate rows of libraries/samples to be entered for singleplex libraries
  def populate_libs
    @new_lib = []
    @lib_samples = []
    params[:nr_libs] ||= 4

    @lib_default = SeqLib.new(default_lib_params)
    @sample_default = LibSample.new(:source_DNA => params[:sample_default][:source_DNA],
                                    :enzyme_code => array_to_string(params[:sample_default][:enzyme_code]))
    @requester = params[:lib_default][:owner]
    @adapter = Adapter.find(params[:lib_default][:adapter_id])
    @index1_tags  = (@adapter.nil? ? nil : @adapter.index1_tags)
    @index2_tags  = (@adapter.nil? ? nil : @adapter.index2_tags)

    0.upto(params[:nr_libs].to_i - 1) do |i|
      @new_lib[i]    = SeqLib.new(default_lib_params)
      @lib_samples[i] = LibSample.new(:adapter_id => params[:sample_default][:adapter_id],
                                      :source_DNA => params[:sample_default][:source_DNA],
                                      :enzyme_code => array_to_string(params[:sample_default][:enzyme_code]))
    end

    respond_to {|format| format.js}
  end

  def create
    authorize! :create, SeqLib
    @new_lib = []; @lib_id = []; nr_libs = params[:nr_libs].to_i;
    @lib_index = 0; libs_created = 0
    
    #***** Libraries are created as a transaction - either all created or none ****#
    #***** otherwise when error occurs with one library, all libraries are created again, resulting in duplicates ****#
    SeqLib.transaction do 
    0.upto(nr_libs-1) do |i|
      lib_param = params['seq_lib_' + i.to_s]
      sample_param = params['lib_sample_' + i.to_s]
      @new_lib[i] = build_simplex_lib(lib_param, sample_param)
      if !@new_lib[i][:lib_name].blank?
        @lib_index = i
        if @new_lib[i].save
          @lib_id.push(@new_lib[i].id)
          libs_created += 1
        else
          raise ActiveRecord::Rollback, "Error saving library line #{i+1}"
        end
      end
    end
    end
    
    if libs_created < nr_libs  # One or more errors
      flash[:error] = 'Error creating sequencing library(ies) - please enter all required fields'
      @lib_with_error = (libs_created == 0 ? nil : @new_lib[@lib_index])
      @hide_defaults = true
      reload_lib_defaults(params, nr_libs)
      render :action => 'new'

    else
      flash[:notice] = libs_created.to_s + ' sequencing library(ies) successfully created'
      redirect_to :action => 'index', :lib_id => @lib_id
    end
  end
  
  # PUT /seq_libs/1
  def update
    @seq_lib = SeqLib.find(params[:id])
    authorize! :update, @seq_lib
    
    pool_label = Pool.get_pool_label(params[:seq_lib][:pool_id]) if !param_blank?(params[:seq_lib][:pool_id])
    alignment_key = AlignmentRef.get_align_key(params[:seq_lib][:alignment_ref_id])
    adapter = Adapter.find(params[:seq_lib][:adapter_id])

    params[:seq_lib].merge!(:alignment_ref => alignment_key,
                            :oligo_pool => pool_label)

    params[:seq_lib][:lib_samples_attributes]["0"][:adapter_id] = params[:seq_lib][:adapter_id]
    if adapter.multi_indices != 'Y'
      params[:seq_lib][:lib_samples_attributes]["0"].merge!(:index2_tag_id => nil)
    end
    
    if @seq_lib.update_attributes(update_params)
      if @seq_lib.in_multiplex_lib?
        LibSample.upd_mplex_sample_fields(@seq_lib)
        SeqLib.upd_mplex_splex(@seq_lib) 
      end
       
      if @seq_lib.on_flow_lane?
        FlowLane.upd_lib_lanes(@seq_lib)
      end
      
      flash[:notice] = 'Sequencing library was successfully updated.'
      redirect_to(@seq_lib) 
    else
      flash[:error] = 'ERROR - Unable to update sequencing library'
      dropdowns
      render :action => 'edit' 
    end
  end

  # DELETE /seq_libs/1
  def destroy
    # to delete seq_lib, need to first delete associated lib_samples
    # make this an admin only function in production
    @seq_lib = SeqLib.find(params[:id])
    authorize! :destroy, @seq_lib

    lib_barcode = @seq_lib.barcode_key
    @seq_lib.destroy
    flash[:notice] = "Sequencing library #{lib_barcode} was successfully deleted"
    redirect_to(seq_libs_url) 
  end

  def auto_complete_for_barcode_key
    @seq_libs = SeqLib.where('barcode_key LIKE ?', params[:search]+'%').all
    render :inline => "<%= auto_complete_result(@seq_libs, 'barcode_key') %>"
  end

  def get_adapter_info
    params[:nested] ||= 'no'
    @lib_row     = (params[:nested] == 'yes' ? 'seq_lib' : 'seq_lib_' + params[:row])
    @lsample_row = (params[:nested] == 'yes' ? 'seq_lib_lib_samples_attributes_' + params[:row] : 'lib_sample_' + params[:row])
    @adapter = Adapter.find(params[@lib_row][:adapter_id])
    @i1_tags = @adapter.index1_tags
    @i2_tags = @adapter.index2_tags
    render {|format| format.js}
  end
  
protected
  def create_params
    params.require(:seq_lib).permit(
        :barcode_key, :lib_name, :library_type, :lib_status, :protocol_id, :owner, :preparation_date, :adapter_id, :runtype_adapter,
        :project, :oligo_pool, :alignment_ref_id, :trim_bases, :sample_conc, :sample_conc_uom, :lib_conc_requested, :lib_conc_uom,
        :notebook_ref, :notes, :quantitation_method, :starting_amt_ng, :pcr_size, :dilution, :updated_by,
        lib_samples_attributes: [
            :id, :splex_lib_id, :splex_lib_barcode, :processed_sample_id, :sample_name, :source_DNA, :source_sample_name,
            :runtype_adapter, :adapter_id, :index1_tag_id, :index2_tag_id, :enzyme_code, :notes, :updated_by
        ],
        sample_storage_container_attributes: [
            :id, :sample_name_or_barcode, :container_type, :container_name,
            :position_in_container, :freezer_location_id, :storage_container_id, :notes, :_destroy
        ]
    )
  end

  def update_params
    create_params
  end

  def default_lib_params
    params.require(:lib_default).permit(:preparation_date, :owner, :protocol_id, :adapter_id, :pcr_size,
                                        :quantitation_method, :lib_conc_requested, :pool_id, :alignment_ref_id,
                                        :trim_bases, :notebook_ref, :notes)
  end

  def default_sample_params
    params.require(:sample_default).permit(:source_DNA, :adapter_id, :enzyme_code)
  end

  def dropdowns
    @adapters     = Adapter.populate_dropdown
    @enzymes      = Category.populate_dropdown_for_category('enzyme')
    @align_refs   = AlignmentRef.populate_dropdown
    @oligo_pools  = Pool.populate_dropdown('lib')
    @owners       = Researcher.populate_dropdown('active_only')
    @protocols    = Protocol.find_for_protocol_type('L')
    @quantitation= Category.populate_dropdown_for_category('quantitation')
  end
  
  def reload_lib_defaults(params, nr_libs)
    dropdowns
    @requester = (current_user.researcher ? current_user.researcher.researcher_name : nil)
    @lib_default = SeqLib.new(:alignment_ref_id => AlignmentRef.default_id)
    @adapter = Adapter.find(params[:seq_lib_0][:adapter_id])
    @index1_tags  = (@adapter.nil? ? nil : @adapter.index1_tags)
    @index2_tags  = (@adapter.nil? ? nil : @adapter.index2_tags)
    @add_with_defaults = 'Refresh from defaults'
   
    @new_lib = []     if !@new_lib
    @lib_samples = [] if !@lib_samples
    
    0.upto(nr_libs.to_i - 1) do |i|
      lib_param = request.params['seq_lib_' + i.to_s]
      sample_param = request.params['lib_sample_' + i.to_s]
      @new_lib[i] ||= SeqLib.new(lib_param)
      @lib_samples[i] = LibSample.new(:source_sample_name => sample_param[:source_sample_name],
                                      :index1_tag_id => sample_param[:index1_tag_id],
                                      :index2_tag_id => sample_param[:index2_tag_id])
    end
    @nr_libs = nr_libs
  end
  
  def build_simplex_lib(lib_param, sample_param)
     seq_lib = SeqLib.new(:library_type => 'S',
	                      :owner => lib_param[:owner],
	                      :preparation_date => lib_param[:preparation_date],
						  :protocol_id => lib_param[:protocol_id],
						  :barcode_key => lib_param[:barcode_key],
						  :lib_name => lib_param[:lib_name],
						  :sample_conc => lib_param[:sample_conc],
						  :sample_conc_uom => lib_param[:sample_conc_uom],
						  :quantitation_method => lib_param[:quantitation_method],
						  :pcr_size => lib_param[:pcr_size],
						  :lib_conc_requested => lib_param[:lib_conc_requested],
						  :adapter_id => lib_param[:adapter_id],
						  :runtype_adapter => lib_param[:runtype_adapter],
						  :alignment_ref_id => lib_param[:alignment_ref_id],
						  :alignment_ref => AlignmentRef.get_align_key(lib_param[:alignment_ref_id]),
						  :pool_id => lib_param[:pool_id],
						  :oligo_pool => (param_blank?(lib_param[:pool_id]) ? nil : Pool.get_pool_label(lib_param[:pool_id])),
						  :notes => lib_param[:notes],
						  :notebook_ref => lib_param[:notebook_ref])

     # For some adapters, we want to force the pairing of index1/index2, by matching the tag numbers
     if Adapter::IDS_FORCEI2.include?(sample_param[:adapter_id].to_i)
       sample_param[:index2_tag_id] = IndexTag.i2id_for_i1tag(sample_param[:index1_tag_id].to_i)
     end

     seq_lib.lib_samples.build(:sample_name => lib_param[:lib_name],
	                           :runtype_adapter => lib_param[:runtype_adapter],
	                           :adapter_id => lib_param[:adapter_id],
							   :processed_sample_id => sample_param[:processed_sample_id],
							   :source_sample_name => sample_param[:source_sample_name],
							   :index1_tag_id => sample_param[:index1_tag_id],
							   :index2_tag_id => sample_param[:index2_tag_id],
							   :enzyme_code => sample_param[:enzyme_code],
							   :notes => lib_param[:notes],
							   :updated_by => sample_param[:updated_by])
     return seq_lib
  end
 
end