class SampleLocQueriesController < ApplicationController
  include SqlQueryBuilder
  layout 'main/main'

  authorize_resource :class => SampleLoc
  before_action :dropdowns, :only => :new_query
  
  def new_query
    @sample_loc_query = SampleLocQuery.new(:to_date   => Date.today)
  end
  
  def index
    @sample_loc_query = SampleLocQuery.new(query_params)
    
    if @sample_loc_query.valid?
      @condition_array = define_conditions(params)
      @sample_locs = SampleLoc.find_for_storage_query(@condition_array)
    
      flash.now[:notice] = 'No samples found for parameters entered' if @sample_locs.nil?
      render :action => 'index'
    
    else  # Validation errors found
      dropdowns
      render :action => :new_query
    end
  end

  def export_samples
    export_type = 'T'
    file_basename = ['LIMS_Sample_Locs', Date.today.to_s].join("_")

    #id_array = params[:export_ids_all].split(' ')
    #@sample_locs = SampleLoc.find_for_export(id_array)
    @sample_locs = SampleLoc.find_for_export(params[:export_id])

    case export_type
      when 'T'  # Export to tab-delimited text using csv_string
        @filename = file_basename + '.txt'
        csv_string = export_samples_csv(@sample_locs)
        send_data(csv_string,
                  :type => 'text/csv; charset=utf-8; header=present',
                  :filename => @filename, :disposition => 'attachment')
                  
      else # Use for debugging
        csv_string = export_samples_csv(@sample_locs)
        render :text => csv_string
    end
  end
  
protected
  def dropdowns
    @consent_protocols  = ConsentProtocol.populate_dropdown
    @category_dropdowns = Category.populate_dropdowns([Cgroup::CGROUPS['Sample'], Cgroup::CGROUPS['Clinical']])
    @clinics            = category_filter(@category_dropdowns, 'clinic')  
    @sample_type        = category_filter(@category_dropdowns, 'sample type')
    @source_tissue      = category_filter(@category_dropdowns, 'source tissue')
    @preservation       = category_filter(@category_dropdowns, 'tissue preservation')
    @tumor_normal       = category_filter(@category_dropdowns, 'tumor_normal')
    @date_options       = [{:datetxt => 'Acquisition Date', :datefld => 'sample_characteristics.collection_date'},
                           {:datetxt => 'LIMS Entry Date',  :datefld => 'samples.created_at'},
                           {:datetxt => "Dissection Date",  :datefld => 'samples.sample_date'},
                           {:datetxt => "Extraction Date",  :datefld => 'processed_samples.processing_date'}]
  end

  def query_params
    params.require(:sample_loc_query).permit(
        :mrn, :patient_string, :barcode_string, :alt_identifier,
        :consent_protocol_id, :clinic_or_location, :tumor_normal, :sample_tissue, :sample_type,
        :tissue_preservation, :date_filter, :from_date, :to_date )
  end

  def define_conditions(params)
    @where_select = []; @where_values = [];

    if !params[:sample_loc_query][:mrn].blank?
      patient_id = Patient.find_id_using_mrn(params[:sample_loc_query][:mrn])
      @where_select.push("samples.patient.id = #{patient_id ||= 0}")
    end

    @where_select, @where_values = build_sql_where(params[:sample_loc_query], SampleLocQuery::QUERY_FLDS, @where_select, @where_values)

    date_fld = params[:sample_loc_query][:date_filter]
    if date_fld == 'samples.sample_date'
      @where_select.push('samples.source_sample_id IS NOT NULL')
    end
    @where_select, @where_values = sql_conditions_for_date_range(@where_select, @where_values, params[:sample_loc_query], date_fld)
    return sql_where_clause(@where_select, @where_values)
  end

  def export_samples_csv(sample_locs)
    hdgs, flds1, flds2 = export_samples_setup
    
    csv_string = CSV.generate(:col_sep => "\t") do |csv|
      csv << hdgs
   
      sample_locs.each do |sample_loc|
        fld_array    = []
        sample_xref  = model_xref(sample_loc)
        
        flds1.each do |obj_code, fld|
          obj = sample_xref[obj_code.to_sym]     
          if obj
            fld_array << obj.send(fld)
          else
            fld_array << nil
          end
        end    
        csv << [Date.today.to_s].concat(fld_array)

        sample_loc.processed_samples.each do |processed_sample|
          fld_array = []
          psample_xref = model_xref(sample_loc, processed_sample)

          flds2.each do |obj_code, fld|
            obj = psample_xref[obj_code.to_sym]

            if obj && fld != 'blank'
              fld_array << obj.send(fld)
            else
              fld_array << nil
            end
          end
          csv << [Date.today.to_s].concat(fld_array)
        end
      end
    end
    return csv_string
  end
  
  def export_samples_setup
    hdgs  = %w{DownloadDt PatientID Barcode AcquiredDt ProcessedDt SampleType Tissue Preservation OR_Designation Rem?
                           Room_Freezer Container}
    
    flds1  = [['sm', 'patient_id'],
              ['sm', 'barcode_key'],
              ['sc', 'collection_date'],
              ['sm', 'sample_date'],
              ['sm', 'sample_type'],
              ['sm', 'sample_tissue'],
              ['sm', 'tissue_preservation'],
              ['sm', 'tumor_normal'],
              ['sm', 'sample_remaining'],
              ['ss', 'room_and_freezer'],
              ['ss', 'container_and_position']]

    flds2 = [['sm', 'patient_id'],
             ['ps', 'barcode_key'],
             ['ps', 'blank'],
             ['ps', 'processing_date'],
             ['ps', 'extraction_type'],
             ['sm', 'sample_tissue'],
             ['sm', 'tissue_preservation'],
             ['sm', 'tumor_normal'],
             ['ps', 'psample_remaining'],
             ['pc', 'room_and_freezer'],
             ['pc', 'container_and_position']]
             
    return hdgs, flds1, flds2
  end
  
  def model_xref(xsample, psample=nil)
    sample_xref = {:sm => xsample,
                   :sc => xsample.sample_characteristic,
                   :ss => xsample.sample_storage_container}
    sample_xref.merge!({:ps => psample, :pc => psample.sample_storage_container}) if psample
    return sample_xref
  end
    
end
