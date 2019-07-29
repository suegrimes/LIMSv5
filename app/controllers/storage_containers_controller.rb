class StorageContainersController < ApplicationController
  include StorageManagement, SqlQueryBuilder

  layout  Proc.new {|controller| controller.request.xhr? ? false : 'main/main'}

  before_action :dropdowns, :only => [:new, :edit, :new_query]

  # GET /storage_containers/new
  def new
    @storage_container = StorageContainer.new(:freezer_location_id => params[:freezer_location_id])
  end

  # GET /storage_containers/1/edit
  def edit
    @storage_container = StorageContainer.find(params[:id])
  end

  def show
    @storage_container = StorageContainer.find(params[:id])
  end

  # POST /storage_containers
  def create
    @storage_container = StorageContainer.new(create_params)

    if @storage_container.save
      flash[:notice] = 'StorageContainer was successfully created.'
      redirect_to(@storage_container)
    else
      render :action => "new"
    end
  end

  # PUT /storage_containers/1
  def update
    @storage_container = StorageContainer.find(params[:id])

    if @storage_container.update_attributes(update_params)
      flash[:notice] = 'StorageContainer was successfully updated.'
      redirect_to(@storage_container)
    else
      dropdowns
      render :action => "edit"
    end
  end

  def new_query
  end

  def index
    @freezer = StorageContainer.find(params[:freezer_location][:freezer_location_id])
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
  def create_params
    params.require(:storage_container).permit(:container_type, :container_name, :freezer_location_id, :notes)
  end

  def update_params
    create_params
  end

  def container_params
    params.require(:freezer_location).permit(:freezer_location_id, :container_type)
  end

  def dropdowns
    @freezers = FreezerLocation.populate_dropdown
    @storage_types = StorageType.populate_dropdown
    # following for new Storage Management UI
    storage_container_ui_data
  end

  def define_conditions(params)
    @where_select = []; @where_values = [];
    query_params = {:freezer_location_id => params[:freezer_location][:freezer_location_id],
                    :container_type => params[:storage_type][:container_type]}

    if param_blank?(query_params[:container_type])
      @where_select.push('storage_containers.container_type IS NOT NULL')
    end

    @where_select, @where_values = build_sql_where(query_params, StorageContainer::QUERY_FLDS, @where_select, @where_values)

    sql_where_clause = (@where_select.empty? ? [] : [@where_select.join(' AND ')].concat(@where_values))
    return sql_where_clause
  end

end
