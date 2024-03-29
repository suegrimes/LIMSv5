class SampleQueriesController < ApplicationController
  include SqlQueryBuilder

  layout 'main/main'

  authorize_resource :class => Sample
  before_action :dropdowns, :only => :new_query
  
  def new_query
    @sample_query = SampleQuery.new(:to_date   => Date.today)
    @type_of_sample = (params[:stype] ||= 'Source and Dissected')
  end
  
  def index
    params[:rpt_type] ||= 'tree'
    @type_of_sample = (params[:stype] ||= ' ')
    
    #@sample_query = SampleQuery.new(params[:sample_query])
    @sample_query = SampleQuery.new(sample_query_params)
    
    if @sample_query.valid?
      @condition_array = define_conditions(params)
      @nr_samples, @samples_by_patient = Sample.find_and_group_by_source(sql_where(@condition_array))
      @source_sample_ids = Sample.find_all_source_for_dissected
      
      @type_of_sample = (params[:stype] ||= 'Source and Dissected')
      @heading_string = ''
  
      if !@nr_samples
        @nr_samples = [0,0]
        @samples_by_patient = nil
      end
    
      flash.now[:notice] = 'No samples found for parameters entered' if @nr_samples == 0
   
      case params[:rpt_type]
      when "tree"
        render :action => 'list_as_tree'
      when "data_tables"
        render :action => 'data_index'
      else
        render :action => 'index'
      end

    else  # Validation errors found
      dropdowns
      render :action => :new_query
    end
  end
  
  def list_samples_for_patient
    @type_of_sample = (params[:stype] ||= ' ')
    
  # List samples for specific patient, and (optionally) source sample
  #   if params[:sample_id] or params[:sample_characteristic_id] also supplied, find patient id from model object
    if params[:sample_id] 
      @patient_nrs = find_patient_nr('Sample', params[:sample_id])
    elsif params[:sample_characteristic_id]
      @patient_nrs = find_patient_nr('SampleCharacteristic', params[:sample_characteristic_id])
    elsif params[:patient_id]
      @patient_nrs = format_patient_nr(params[:patient_id], 'array')
    end
      
    if @patient_nrs
      @nr_samples, @samples_by_patient = Sample.find_and_group_for_patient(@patient_nrs[0])
      @heading_string  = 'Patient: ' + format_patient_nr(@patient_nrs[0])   
    end
    
    if !@nr_samples
        @nr_samples = [0,0]
        @samples_by_patient = nil
        @heading_string = ''
    end
    
    render :action => 'index'
  end
  
  def list_samples_for_characteristic
  # All samples for a particular patient & sample_characteristic
  # Heading includes patient id/mrn, and sample collection date 
    @type_of_sample = (params[:stype] ||= ' ')
    
    if params[:sample_characteristic_id]
      patient_nrs = find_patient_nr('SampleCharacteristic', params[:sample_characteristic_id])
      @nr_samples, @samples_by_patient = Sample.find_and_group_for_clinical(params[:sample_characteristic_id])
      if SampleCharacteristic.exists?(params[:sample_characteristic_id])
        @collection_date = SampleCharacteristic.find(params[:sample_characteristic_id]).collection_date.to_s
      else
        @collection_date = ' '
      end
        @heading_string  = 'Patient: ' + format_patient_nr(patient_nrs[0]) + ' , ' + 
                           'Collection Date: '  + @collection_date
  
    elsif params[:source_sample_id]
      # All samples for a particular patient & source sample
      # Heading includes patient id/mrn, and source sample barcode
      patient_nrs = find_patient_nr('Sample', params[:source_sample_id])
      @nr_samples, @samples_by_patient = Sample.find_and_group_for_sample(params[:source_sample_id])
      @heading_string  = 'Patient: ' + format_patient_nr(patient_nrs[0]) + ' , ' + 
                         'Sample: '  + find_barcode('Sample', params[:source_sample_id])
    end
    
    if !@nr_samples
        @nr_samples = [0,0]
        @samples_by_patient = nil
        @heading_string = ''
    end
    
    #render :action => :debug
    render :action => 'index'
  end
  
  def export_samples
    export_type = 'T'
    file_basename = ['LIMS_Samples', Date.today.to_s].join("_")

    id_array = params[:export_id_tree] ||= params[:export_ids_all].split(' ')
    @samples = Sample.find_for_export(id_array)

    with_mrn = ((can? :read, Patient)? 'yes' : 'no')
    
    case export_type
      when 'T'  # Export to tab-delimited text using csv_string
        @filename = file_basename + '.txt'
        csv_string = export_samples_csv(@samples, with_mrn)
        send_data(csv_string,
                  :type => 'text/csv; charset=utf-8; header=present',
                  :filename => @filename, :disposition => 'attachment')
                  
      else # Use for debugging
        csv_string = export_samples_csv(@samples, with_mrn)
        render :text => csv_string
    end
  end
  
protected
  def dropdowns
    @consent_protocols  = ConsentProtocol.populate_dropdown
    @category_dropdowns = Category.populate_dropdowns([Cgroup::CGROUPS['Sample'], Cgroup::CGROUPS['Clinical']])
    @organisms          = category_filter(@category_dropdowns, 'organism')
    @races              = category_filter(@category_dropdowns, 'race')
    @ethnicities        = category_filter(@category_dropdowns, 'ethnicity')
    @clinics            = category_filter(@category_dropdowns, 'clinic')  
    @sample_type        = category_filter(@category_dropdowns, 'sample type')
    @source_tissue      = category_filter(@category_dropdowns, 'source tissue')
    @preservation       = category_filter(@category_dropdowns, 'tissue preservation')
    @dx_primary         = category_filter(@category_dropdowns, 'primary disease')
    @tumor_normal       = category_filter(@category_dropdowns, 'tumor_normal')
    @users              = User.all
  end

  def define_conditions(params)
    @where_select = []; @where_values = [];

    if params[:stype] == 'clinical' || params[:stype] == 'dissected'
      null_or_not = (params[:stype] == 'clinical' ? 'NULL' : 'NOT NULL')
      @where_select.push("samples.source_sample_id IS #{null_or_not}")
    end

    if !params[:sample_query][:mrn].blank?
      patient_id = Patient.find_id_using_mrn(params[:sample_query][:mrn])
      @where_select.push("samples.patient_id = #{patient_id ||= 0}")
    end

    @where_select, @where_values = build_sql_where(params[:sample_query], SampleQuery::QUERY_FLDS, @where_select, @where_values)

    dt_fld = (params[:sample_query][:date_filter] == 'Dissection Date' ? 'samples.sample_date' : 'sample_characteristics.collection_date')
    @where_select, @where_values = sql_conditions_for_date_range(@where_select, @where_values, params[:sample_query], dt_fld)

    return sql_where_clause(@where_select, @where_values)
  end
  
  def export_samples_csv(samples, with_mrn='no')    
    hdgs, flds1, flds2 = export_samples_setup(with_mrn)
    
    csv_string = CSV.generate(:col_sep => "\t") do |csv|
      csv << hdgs
   
      samples.each do |sample|
        fld_array    = []
        sample_xref  = model_xref(sample)
        
        flds1.each do |obj_code, fld|
          obj = sample_xref[obj_code.to_sym]     
          if obj
            fld_array << obj.send(fld) unless (fld == 'mrn' && with_mrn == 'no')
          else
            fld_array << nil
          end
        end    
        csv << [Date.today.to_s].concat(fld_array)
        
        sample.processed_samples.each do |processed_sample|
          fld_array = []
          psample_xref = model_xref(sample, processed_sample)
          
          flds2.each do |obj_code, fld|
            obj = psample_xref[obj_code.to_sym]
          
            if obj && fld != 'blank'
              fld_array << obj.send(fld) unless (fld == 'mrn' && with_mrn == 'no')
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
  
  def export_samples_setup(with_mrn='no')
    hdg1  =(with_mrn == 'yes'? ['Download_Dt', 'PatientID', 'MRN'] : ['Download_Dt', 'PatientID'])
    hdgs  = hdg1.concat(%w{Barcode AltID SampleType SampleDate Protocol PatientDX OR_Designation Preservation
                           FromSample Histopathology Remaining? Room_Freezer Container})
    
    flds1  = [['sm', 'patient_id'],
             ['pt', 'mrn'],
             ['sm', 'barcode_key'],
             ['sm', 'alt_identifier'],
             ['sm', 'sample_category'],
             ['sm', 'sample_date'],
             ['cs', 'consent_name'],
             ['sc', 'disease_primary'],
             ['pr', 'pathology_classification'],
             ['sm', 'tumor_normal'],
             ['sm', 'tissue_preservation'],
             ['sm', 'source_barcode_key'],
             ['he', 'histopathology'],
             ['sm', 'sample_remaining'],
             ['ss', 'room_and_freezer'],
             ['ss', 'container_and_position']]
             
    flds2 = [['sm', 'patient_id'],
             ['pt', 'mrn'],
             ['ps', 'barcode_key'],
             ['ps', 'blank'],
             ['ps', 'extraction_type'],
             ['ps', 'processing_date'],
             ['cs', 'consent_name'],
             ['ps', 'blank'],
             ['ps', 'blank'],
             ['sm', 'tumor_normal'],
             ['ps', 'blank'],
             ['sm', 'barcode_key'],
             ['ps', 'blank'],
             ['ps', 'psample_remaining'],
             ['pc', 'room_and_freezer'],
             ['pc', 'container_and_position']]
             
    return hdgs, flds1, flds2
  end
  
  def model_xref(xsample, psample=nil)
    sample_xref = {:pt => xsample.patient,
                   :sm => xsample,
                   :sc => xsample.sample_characteristic,
                   :cs => xsample.sample_characteristic.consent_protocol,
                   :pr => xsample.sample_characteristic.pathology,
                   :he => xsample.histology,
                   :ss => xsample.sample_storage_container}
    sample_xref.merge!({:ps => psample, :pc => psample.sample_storage_container}) if psample
    return sample_xref
  end

  def sample_query_params
    params.require(:sample_query).permit(
      :mrn, :patient_string, :organism, :race, :gender, :ethnicity, :barcode_string, :alt_identifier,
      :consent_protocol_id, :clinic_or_location, :disease_primary, :tumor_normal, :sample_tissue,
      :sample_type, :tissue_preservation, :date_filter, :from_date, :to_date, :updated_by
    )
  end
    
end
