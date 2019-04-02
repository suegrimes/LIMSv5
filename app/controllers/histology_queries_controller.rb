class HistologyQueriesController < ApplicationController
  include SqlQueryBuilder

  layout 'main/main'

  authorize_resource :class => Histology
  before_action :dropdowns, :only => :new_query
  
  def new_query
    @histology_query = HistologyQuery.new(:from_date => (Date.today - 2.years).beginning_of_month,
                                          :to_date   =>  Date.today)
  end
 
  def index
    @histology_query = HistologyQuery.new(histology_query_params)
    
    if @histology_query.valid?
      @condition_array = define_conditions(params)
      if @condition_array.size > 0 && @condition_array[0] == '**error**'
        dropdowns
        flash.now[:error] = "Error in sample barcode parameters, please enter alphanumeric only"
        render :action => :new_query
      else
        @hdr = 'H&E Details (Filtered)'
        @histologies = Histology.find_with_conditions(@condition_array)
        render :action => :index
      end
      
    else
      dropdowns
      render :action => :new_query
    end
  end

protected
  def dropdowns
    @consent_protocols  = ConsentProtocol.populate_dropdown
    @clinics            = Category.populate_dropdown_for_category('clinic')
    @preservation       = Category.populate_dropdown_for_category('tissue preservation')
  end

  def define_conditions(params)
    @where_select = []; @where_values = [];

    if !params[:histology_query][:mrn].blank?
      patient_id = Patient.find_id_using_mrn(params[:histology_query][:mrn])
      @where_select.push("samples.patient.id = #{patient_id ||= 0}")
    end

    @where_select, @where_values = build_sql_where(params[:histology_query], HistologyQuery::QUERY_FLDS, @where_select, @where_values)

    dt_fld = 'histologies.he_date'
    @where_select, @where_values = sql_conditions_for_date_range(@where_select, @where_values, params[:histology_query], dt_fld)

    return sql_where_clause(@where_select, @where_values)
  end

  def histology_query_params
    params.require(:histology_query).permit(
        :mrn, :patient_string, :barcode_string, :alt_identifier,
        :consent_protocol_id, :clinic_or_location, :tissue_preservation, :from_date, :to_date
    )
  end

end