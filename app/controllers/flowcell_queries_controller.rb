class FlowcellQueriesController < ApplicationController
  include SqlQueryBuilder, SqlQueryExport
  layout 'main/main'
  
  before_action :dropdowns, :only => :new_query
  
  def new_query
    @flowcell_query = FlowcellQuery.new(:from_date => (Date.today - 6.months).beginning_of_month,
                                        :to_date   =>  Date.today)
  end
 
  def index
    @flowcell_query = FlowcellQuery.new(query_params)
    
    if @flowcell_query.valid?
      @condition_array = define_conditions(params)
      @hdr = 'Sequencing Runs (Filtered)'
      @flow_cells = FlowCell.find_sequencing_runs(SEQ_ORDER, sql_where(@condition_array))
      if @flow_cells.size == 1 
        @flow_cell = @flow_cells[0]
        redirect_to :controller => 'flow_cells', :action => :show, :id => @flow_cell.id
      else
        render :action => :index
      end
      
    else
      dropdowns
      render :action => :new_query
    end
  end

  def export_seqruns
    export_type = 'T'

    #@flow_cells = FlowCell.find_for_export(params[:export_id_page])
    id_array = params[:export_ids_all].split(' ')
    @flow_cells = FlowCell.find_for_export(id_array)
    csv_string = export_results_to_csv(FlowcellQuery,@flow_cells)

    case export_type
      when 'T'  # Export to tab-delimited text using csv_string
        file_basename = ['LIMS_SeqRuns', Date.today.to_s].join("_")
        send_data(csv_string,
                  :type => 'text/csv; charset=utf-8; header=present',
                  :filename => file_basename + '.txt', :disposition => 'attachment')

      else # Use for debugging
        #render :text => id_array.inspect
        #render :text => csv_string
    end
  end

protected
  def dropdowns
    @machine_types = Category.populate_dropdown_for_category('machine type')
  end
  
  def define_conditions(params)
    #If run number provided, specific run is requested, so only use that parameter in query
    if !params[:flowcell_query][:seq_run_nr].blank?
      run_nr_i = params[:flowcell_query][:seq_run_nr].to_i
      @where_select = ["flow_cells.seq_run_nr = ?"]
      @where_values = [run_nr_i]
    else
      @where_select, @where_values = build_sql_where(params[:flowcell_query], FlowcellQuery::QUERY_FLDS, [], [])
      dt_fld = 'flow_cells.sequencing_date'
      @where_select, @where_values = sql_conditions_for_date_range(@where_select, @where_values, params[:flowcell_query], dt_fld)
    end

    return sql_where_clause(@where_select, @where_values)
  end

  def query_params
    params.require(:flowcell_query).permit(:seq_run_nr, :hiseq_xref, :machine_type, :from_date, :to_date)
  end
end