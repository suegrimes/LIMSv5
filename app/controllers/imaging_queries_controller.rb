class ImagingQueriesController < ApplicationController
  include SqlQueryBuilder
  layout 'main/main'
  
  before_action :dropdowns, :only => :new_query
  
  def new_query
    @imaging_query = ImagingQuery.new(:from_date => (Date.today - 2.years).beginning_of_month,
                                          :to_date   =>  Date.today)
  end
  
   def index
    @imaging_query = ImagingQuery.new(imaging_query_params)
     
    if @imaging_query.valid?
      condition_array = define_conditions(params)
      @imaging_runs = ImagingRun.find_for_query(sql_where(condition_array))
      render :action => :index
    else
      dropdowns
      render :action => :new_query
    end
    #render :action => 'debug'
  end
  
protected
  def dropdowns
    @owners       = Researcher.populate_dropdown('all')
  end

  def define_conditions(params)
    @where_select, @where_values = build_sql_where(params[:imaging_query], ImagingQuery::QUERY_FLDS, [], [])

    dt_fld = 'imaging_slides.imaging_date'
    @where_select, @where_values = sql_conditions_for_date_range(@where_select, @where_values, params[:imaging_query], dt_fld)

    return sql_where_clause(@where_select, @where_values)
  end

  def imaging_query_params
    params.require(:imaging_query).permit(:slide_nr_string, :owner, :protocol_id, :from_date, :to_date)
  end
  
 end