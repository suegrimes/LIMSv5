class StorageContainersController < ApplicationController
  layout  Proc.new {|controller| controller.request.xhr? ? false : 'main/samples'}

  include StorageManagement
  before_action :dropdowns, :only => :new_query

  def new_query
  end

  def index
    @freezer = FreezerLocation.find(params[:freezer_location][:freezer_location_id])
    condition_array = define_conditions(params)
    @storage_containers = StorageContainer.find_for_summary_query(condition_array)
    render :action => :index
  end

  def list_contents
    @ss_container = StorageContainer.find_for_contents_query(params[:id])
    render :action => :list_contents
  end

  def export_container
    export_type = 'T'
    @sample_storage_containers = SampleStorageContainer.find_for_export(params[:export_id])
    file_basename = ['LIMS_Sample_Containers', Date.today.to_s].join("_")

    case export_type
      when 'T'  # Export to tab-delimited text using csv_string
        @filename = file_basename + '.txt'
        csv_string = export_container_csv(@sample_storage_containers)
        send_data(csv_string,
                  :type => 'text/csv; charset=utf-8; header=present',
                  :filename => @filename, :disposition => 'attachment')

      else # Use for debugging
        csv_string = export_container_csv(@sample_storage_containers)
        render :text => csv_string
    end
  end

  def positions_used
    @id = params[:id]
    @storage_container = StorageContainer.find(@id)
    if @storage_container.nil?
      emsg = "Storage container not found for id: #{@id}"
      flash[:error] = emsg;
      if  request.xhr?
        return generic_error(:not_found, emsg)
      end
    end

    ssc = @storage_container.sample_storage_containers.to_a
    @positions_used = ssc.inject([]) {|array, r| array << r.position_in_container }
    respond_to do |format|
      format.json do
        render json: {positions_used: @positions_used}, status: :ok
      end
    end
  end

  protected
  def dropdowns
    @freezers = FreezerLocation.populate_dropdown
    @storage_types = StorageType.populate_dropdown
    # following for new Storage Management UI
    storage_container_ui_data
  end

  def define_conditions(params)
    @where_select = []
    @where_values = []

    unless param_blank?(params[:freezer_location][:freezer_location_id])
      @where_select.push('storage_containers.freezer_location_id = ?')
      @where_values.push(params[:freezer_location][:freezer_location_id])
    end

    if param_blank?(params[:storage_type][:container_type])
      @where_select.push('storage_containers.container_type IS NOT NULL')
    else
      @where_select.push('storage_containers.container_type = ?')
      @where_values.push(params[:storage_type][:container_type])
    end

    sql_where_clause = (@where_select.empty? ? [] : [@where_select.join(' AND ')].concat(@where_values))
    return sql_where_clause
  end

end
