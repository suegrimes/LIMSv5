class PsampleQueriesController < ApplicationController
  include SqlQueryBuilder

  layout 'main/main'

  authorize_resource :class => ProcessedSample
  
  before_action :dropdowns, :only => :new_query
  
  def new_query
    @psample_query = PsampleQuery.new(:to_date   =>  Date.today)
  end
  
  def index
    #@psample_query = PsampleQuery.new(params[:psample_query]) 
    @psample_query = PsampleQuery.new(psample_query_params) 
     
    if @psample_query.valid?
      condition_array = define_conditions(params)
      @processed_samples = ProcessedSample.find_for_query(sql_where(condition_array))
      if params[:rpt_type] == 'data_tables'
        render :action => 'data_index'
      else 
        render :action => :index
      end
    else
      dropdowns
      render :action => :new_query
    end
    #render :action => 'debug'
  end
  
  def export_samples
    export_type = 'T'
    @processed_samples = ProcessedSample.find_for_export(params[:export_id])
    file_basename = ['LIMS_Extractions', Date.today.to_s].join("_")
    
    case export_type
      when 'T'  # Export to tab-delimited text using csv_string
        @filename = file_basename + '.txt'
        csv_string = export_samples_csv(@processed_samples)
        send_data(csv_string,
                  :type => 'text/csv; charset=utf-8; header=present',
                  :filename => @filename, :disposition => 'attachment')
                  
      else # Use for debugging
        csv_string = export_samples_csv(@processed_samples, with_mrn)
        render :text => csv_string
    end
  end
  
protected
  def dropdowns
    @consent_protocols  = ConsentProtocol.populate_dropdown
    @protocols          = Protocol.find_for_protocol_type('E')  #Extraction protocols
    @category_dropdowns = Category.populate_dropdowns([Cgroup::CGROUPS['Clinical'], Cgroup::CGROUPS['Sample'], Cgroup::CGROUPS['Extraction']])
    @clinics            = category_filter(@category_dropdowns, 'clinic')
    @sample_type        = category_filter(@category_dropdowns, 'sample type')
    @source_tissue      = category_filter(@category_dropdowns, 'source tissue')
    @preservation       = category_filter(@category_dropdowns, 'tissue preservation')
    @tumor_normal       = category_filter(@category_dropdowns, 'tumor_normal')
    @extraction_type    = category_filter(@category_dropdowns, 'extraction type')
    @users              = User.all
  end

  def define_conditions(params)
    @where_select = []; @where_values = [];

    if !params[:psample_query][:mrn].blank?
      patient_id = Patient.find_id_using_mrn(params[:psample_query][:mrn])
      @where_select.push("samples.patient.id = #{patient_id ||= 0}")
    end

    @where_select, @where_values = build_sql_where(params[:psample_query], PsampleQuery::QUERY_FLDS, @where_select, @where_values)

    dt_fld = 'processed_samples.processing_date'
    @where_select, @where_values = sql_conditions_for_date_range(@where_select, @where_values, params[:psample_query], dt_fld)

    return sql_where_clause(@where_select, @where_values)
  end

  def export_samples_csv(processed_samples)    
    hdgs, flds = export_samples_setup
    
    csv_string = CSV.generate(:col_sep => "\t") do |csv|
      csv << hdgs
   
      processed_samples.each do |processed_sample|
        fld_array    = []
        sample_xref  = model_xref(processed_sample)
        
        flds.each do |obj_code, fld|
          obj = sample_xref[obj_code.to_sym]     
          if obj
            fld_array << obj.send(fld)
          else
            fld_array << nil
          end
        end    
        csv << [Date.today.to_s].concat(fld_array)
      end
    end
    return csv_string
  end
  
  def export_samples_setup
    hdgs  = (%w{DownloadDt Patient_ID Consent_Protocol Barcode Type FromSample ProcessDt Amt(ug) Conc A260/280 A260/A230 Rem? Room_Freezer Container})
    
    flds  = [['sm', 'patient_id'],
             ['cs', 'consent_name'],
             ['ps', 'barcode_key'],
             ['ps', 'extraction_type'],
             ['sm', 'barcode_key'],
             ['ps', 'processing_date'],
             ['ps', 'final_amt_ug'],
             ['ps', 'final_conc'],
             ['ps', 'final_a260_a280'],
             ['ps', 'final_a260_a230'],
             ['ps', 'psample_remaining'],
             ['pc', 'room_and_freezer'],
             ['pc', 'container_and_position']]
             
    return hdgs, flds
  end
  
  def model_xref(psample)
    return {:ps => psample, :sm => psample.sample, :cs => psample.sample.sample_characteristic.consent_protocol, :pc => psample.sample_storage_container}
  end
    
  def psample_query_params
    params.require(:psample_query).permit(
      :mrn, :patient_string, :barcode_string, :consent_protocol_id, :clinic_or_location,
      :sample_tissue, :sample_type, :tissue_preservation, :tumor_normal, :protocol_id,
      :extraction_type, :from_date, :to_date, :updated_by
    )
  end

 end
