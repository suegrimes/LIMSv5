class ImagingRunsController < ApplicationController
  include SqlQueryBuilder
  layout 'main/main'

  before_action :dropdowns, :only => [:setup_params, :new, :edit, :create, :update]
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
                                   :run_date => Date.today,
                                   :created_at => Date.today,)

    # Get samples (dissections) based on parameters entered
    @condition_array = define_slide_conditions(params)
    @imaging_slides = ImagingSlide.where(sql_where(@condition_array)).order('slide_number').all.to_a

    render :action => 'new'
  end
  
  # GET /imaging_runs/1/edit
  def edit
    @imaging_run = ImagingRun.includes(:imaging_slides).find(params[:id])
    authorize! :update, @imaging_run
  end

  # POST /imaging_runs
  def create
    #_deliberate_error_here
    # TODO: Add error checking
    #       Require at least one slide per run
    authorize! :create, ImagingRun
    @imaging_run = ImagingRun.new(create_params)
    @imaging_run.imaging_key = "%s_%s_%04d" % [@imaging_run.run_date.strftime("%Y%m%d"), "XEN", ImagingRun.last_run_nr + 1]

    if !@imaging_run.save
      #error_found = true  # Validation or other error when saving to database
      flash.now[:error] = 'ERROR - Unable to create imaging run'
      @imaging_slides = ImagingSlide.find(params[:imaging_run][:slide_imagings_attributes].pluck(:imaging_slide_id))
      @positions = params[:imaging_run][:slide_imagings_attributes].pluck(:imaging_position)
      render :new
    else
      flash[:notice] = "Imaging run successfully created"
      redirect_to(@imaging_run)
    end
  end

  # PUT /imaging_runs/1
  def update
    #_deliberate_error_here
    # TODO: Add error checking
    #       Use javascript to allow adding a slide to a run
    #       Make sure at least one valid slide remains after deleting

    @imaging_run = ImagingRun.find(params[:id])
    authorize! :update, @imaging_run

    if @imaging_run.update_attributes(update_params)
      flash[:notice] = "Imaging run has been updated"
      render :action => 'show'
    else
      flash.now[:error] = "Error updating imaging run"
      @imaging_slides = ImagingSlide.find(params[:imaging_run][:slide_imagings_attributes].pluck(:imaging_slide_id))
      @positions = params[:imaging_run][:slide_imagings_attributes].pluck(:imaging_position)
      render :action => 'edit'
    end
  end

  def show
    @imaging_run = ImagingRun.find(params[:id])
  end

  def index
    @imaging_runs = ImagingRun.find_for_query([])
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
  def dropdowns
    @owners    =  Researcher.populate_dropdown('incl_inactive')
    @imaging_protocols = Protocol.find_for_protocol_type('I')
  end

  def define_slide_conditions(params)
    combo_fields = {:slide_nr_string => {:sql_attr => ['imaging_slides.slide_number']}}
    query_flds = {'standard' => {}, 'multi_range' => combo_fields, 'search' => {}}
    #query_params = params[:imaging_run].merge({:slide_nr_string => params[:slide_nr_string]})
    query_params = {:slide_nr_string => params[:slide_nr_string]}
    @where_select, @where_values = build_sql_where(query_params, query_flds, [], [])

    return sql_where_clause(@where_select, @where_values)
  end

  def create_params
    params.require(:imaging_run).permit(:imaging_key, :imaging_alt_id, :protocol_id, :run_date,
                                        :run_description, :notebook_ref, :owner,
                                        slide_imagings_attributes: [:id, :imaging_slide_id, :imaging_position, :_destroy])
  end

  def update_params
    params.require(:imaging_run).permit(:imaging_key, :imaging_alt_id, :protocol_id, :run_date,
                                        :run_description, :notebook_ref, :owner,
                                        slide_imagings_attributes: [:id, :imaging_slide_id, :imaging_position, :_destroy])
  end
end
