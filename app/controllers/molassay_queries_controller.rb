class MolassayQueriesController < ApplicationController
  include SqlQueryBuilder

  layout 'main/samples'

  authorize_resource :class => MolecularAssay
  
  before_action :dropdowns, :only => :new_query
  
  def new_query
    @molassay_query = MolassayQuery.new(:from_date => (Date.today - 2.years).beginning_of_month,
                                          :to_date   =>  Date.today)
  end
  
   def index
    @molassay_query = MolassayQuery.new(molassay_query_params)
     
    if @molassay_query.valid?
      condition_array = define_conditions(params)
      @molecular_assays = MolecularAssay.find_for_query(sql_where(condition_array))
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
    @where_select, @where_values = build_sql_where(params[:molassay_query], MolassayQuery::QUERY_FLDS, [], [])

    dt_fld = 'molecular_assays.preparation_date'
    @where_select, @where_values = sql_conditions_for_date_range(@where_select, @where_values, params[:psample_query], dt_fld)

    sql_where_clause = (@where_select.length == 0 ? [] : [@where_select.join(' AND ')].concat(@where_values))
    return sql_where_clause

  end

  def molassay_query_params
    params.require(:molassay_query).permit(:patient_string, :owner, :from_date, :to_date)
  end
  
 end