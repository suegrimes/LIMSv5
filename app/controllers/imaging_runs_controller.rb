class ImagingRunsController < ApplicationController
  include SqlQueryBuilder
  layout 'main/main'

  before_action :setup_dropdowns, :only => [:setup_params, :new, :edit]
  def setup_params
    authorize! :new, ImagingRun
    @from_date = (Date.today - 90).beginning_of_month
    @to_date   = Date.today
    @date_range = DateRange.new(@from_date, @to_date)
  end

  def new
    authorize! :new, ImagingRun
    @requester = (current_user.researcher ? current_user.researcher.researcher_name : nil)
    @imaging_run  = ImagingRun.new(:updated_by => @requester,
                                   :protocol_id => params[:imaging_run][:protocol_id],
                                   :created_at => Date.today,)

    # Get samples (dissections) based on parameters entered
    @condition_array = define_slide_conditions(params)
    @image_slides = ImageSlide.where(sql_where(@condition_array)).order('slide_number').all.to_a

    render :action => 'new'
  end
  
  # GET /imaging_runs/1/edit
  def edit
    @imaging_run = ImagingRun.includes(:samples).find(params[:id])
    authorize! :update, @imaging_run
  end

  # POST /imaging_runs
  def create
    #_deliberate_error_here
    # TODO: Add error checking
    #       Require at least one slide per run

    @imaging_run = ImagingRun.new(create_params)
    authorize! :create, @imaging_run

    if !@imaging_run.save
      #error_found = true  # Validation or other error when saving to database
      flash.now[:error] = 'ERROR - Unable to create imaging run'
    else
      flash[:notice] = "Imaging run successfully created"
      redirect_to(@imaging_run)
    end
  end

  # PUT /imaging_runs/1
  def update
    #_deliberate_error_here
    # TODO: Add error checking

    @imaging_run = ImagingRun.find(params[:id])
    authorize! :update, @imaging_run

    if @imaging_run.update_attributes(update_params)
      flash[:notice] = "Imaging run has been updated"
      render :action => 'show'
    else
      flash.now[:error] = "Error updating imaging run"
      render :action => 'edit'
    end
  end

  def show
    @imaging_run = ImagingRun.find(params[:id])
  end

  def index
    @imaging_runs = ImagingRun.all
  end

  # DELETE /imaging_runs/1
  def destroy
    @imaging_run = ImagingRun.find(params[:id])
    authorize! :delete, @imaging_run

    @imaging_run.destroy
    flash[:notice] = 'Imaging run successfully deleted'
    redirect_to imaging_runs_url
  end

protected
  def setup_dropdowns
    @owners    =  Researcher.populate_dropdown('incl_inactive')
    @imaging_protocols = Protocol.find_for_protocol_type('I')
  end

  def define_slide_conditions(params)
    combo_fields = {:slide_nr_string => {:sql_attr => ['image_slides.slide_number']}}
    query_flds = {'standard' => {}, 'multi_range' => combo_fields, 'search' => {}}
    #query_params = params[:imaging_run].merge({:slide_nr_string => params[:slide_nr_string]})
    query_params = {:slide_nr_string => params[:slide_nr_string]}
    @where_select, @where_values = build_sql_where(query_params, query_flds, [], [])

    return sql_where_clause(@where_select, @where_values)
  end

  def create_params
    params.require(:imaging_run).permit(:machine_type, :slide_number, :slide_name, :protocol_id,
                                        :owner,
                                        slide_samples_attributes: [:sample_id, :sample_position])
  end

  def update_params
    params.require(:imaging_run).permit(:machine_type, :slide_number, :slide_name, :protocol_id,
                                        :owner,
                                        slide_samples_attributes: [:id, :sample_id, :sample_position])
  end
end
