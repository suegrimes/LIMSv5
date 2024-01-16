class PatientQueriesController < ApplicationController
  include SqlQueryBuilder

  layout 'main/main'

  before_action :dropdowns, :only => :new_query
  
  def new_query
    authorize! :read, Sample
    @patient_query = PatientQuery.new()
  end
  
  def index
    authorize! :read, Sample
    @patient_query = PatientQuery.new(patient_query_params)
    
    if @patient_query.valid?
      @condition_array = define_conditions(params)
      @patients = Patient.find_with_conditions(@condition_array)

      flash.now[:notice] = 'No samples found for parameters entered' if @patients.nil?
      render :action => :index

    else  # Validation errors found
      dropdowns
      render :action => :new_query
    end
  end

  def export_patients
    export_type = 'T'
    file_basename = ['LIMS_Patients', Date.today.to_s].join("_")

    id_array = params[:export_ids]
    @sample_characteristics = SampleCharacteristic.find_for_export(id_array)

    with_mrn = ((can? :edit, Patient)? 'yes' : 'no')
    
    case export_type
      when 'T'  # Export to tab-delimited text using csv_string
        @filename = file_basename + '.txt'
        csv_string = export_patients_csv(@sample_characteristics, with_mrn)
        send_data(csv_string,
                  :type => 'text/csv; charset=utf-8; header=present',
                  :filename => @filename, :disposition => 'attachment')
                  
      else # Use for debugging
        csv_string = export_patients_csv(@sample_characteristics, with_mrn)
        render :text => csv_string
    end
  end
  
protected
  def dropdowns
    @consent_protocols  = ConsentProtocol.populate_dropdown
    @category_dropdowns = Category.populate_dropdowns([Cgroup::CGROUPS['Sample'], Cgroup::CGROUPS['Clinical']])
    @organisms          = category_filter(@category_dropdowns, 'organism')
    @clinics            = category_filter(@category_dropdowns, 'clinic')  
    @sample_type        = category_filter(@category_dropdowns, 'sample type')
    @source_tissue      = category_filter(@category_dropdowns, 'source tissue')
    @preservation       = category_filter(@category_dropdowns, 'tissue preservation')
    @dx_primary         = category_filter(@category_dropdowns, 'primary disease')
    @tumor_normal       = category_filter(@category_dropdowns, 'tumor_normal')
    @users              = User.all
  end

  def define_conditions(params)
    @where_select = ["samples.source_sample_id IS NULL"]; @where_values = [];

    if !params[:patient_query][:mrn].blank?
      patient_id = Patient.find_id_using_mrn(params[:patient_query][:mrn])
      @where_select.push("sample_characteristics.patient_id = #{patient_id ||= 0}")
    end

    @where_select, @where_values = build_sql_where(params[:patient_query], PatientQuery::QUERY_FLDS, @where_select, @where_values)
    @where_select, @where_values = sql_conditions_for_date_range(@where_select, @where_values, params[:patient_query],
                                                                 'sample_characteristics.collection_date')
    return sql_where_clause(@where_select, @where_values)
  end
  
  def export_patients_csv(scollections, with_mrn='no')
    hdgs, flds = export_patients_setup(with_mrn)
    
    csv_string = CSV.generate(:col_sep => "\t") do |csv|
      csv << hdgs
   
      scollections.each do |scollection|
        fld_array    = []
        scollection_xref  = model_xref(scollection)
        
        flds.each do |obj_code, fld|
          obj = scollection_xref[obj_code.to_sym]
          if obj
            fld_array << obj.send(fld) unless (fld == 'mrn' && with_mrn == 'no')
          else
            fld_array << nil
          end
        end

        #Add aggregated values for samples per each sample characteristic record
        nr_samples = scollection.samples.size
        tn_values = scollection.samples.pluck(:tumor_normal).reject(&:blank?)
        tn_string = tn_values.size < 2 ? tn_values[0] : helpers.arr_tally_to_str(tn_values)

        csv << [Date.today.to_s].concat(fld_array).concat([nr_samples, tn_string])
      end
    end
    return csv_string
  end
  
  def export_patients_setup(with_mrn='no')
    hdg1  =(with_mrn == 'yes'? ['Download_Dt', 'PatientID', 'MRN'] : ['Download_Dt', 'PatientID'])
    hdgs  = hdg1.concat(%w{Organism Gender CollectionDt ConsentNr Protocol Clinic PatientDX NrSamples Tumor_Normal})
    
    flds   = [['pt', 'id'],
             ['pt', 'mrn'],
             ['pt', 'organism'],
             ['pt', 'gender'],
             ['sc', 'collection_date'],
             ['sc', 'consent_nr'],
             ['cs', 'consent_name'],
             ['sc', 'clinic_or_location'],
             ['sc', 'disease_primary']]
             
    return hdgs, flds
  end
  
  def model_xref(sample_characteristic)
    scollection_xref = {:pt => sample_characteristic.patient,
                   :sc => sample_characteristic,
                   :cs => sample_characteristic.consent_protocol}
    return scollection_xref
  end

  def patient_query_params
    params.require(:patient_query).permit(
      :mrn, :patient_string, :organism, :race, :gender, :ethnicity, :consent_protocol_id,
      :clinic_or_location, :disease_primary
    )
  end
    
end
