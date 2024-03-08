class ImagingSlidesController < ApplicationController
  include SqlQueryBuilder
  layout 'main/main'
  
  #CanCan tries to validate all param values in hash and complains about barcode_string
  # which is not a 'permitted' attribute since is not in model, so can't use load_and_authorize_resource
  #load_and_authorize_resource

  before_action :dropdowns, :only => [:setup_params, :new, :edit, :update, :create]
  def setup_params
    authorize! :new, ImagingSlide
  end
  def new
    authorize! :new, ImagingSlide
    @current_user = current_user
    @requester = (current_user.researcher ? current_user.researcher.researcher_name : nil)
    @imaging_slide  = ImagingSlide.new(:updated_by => current_user.id,
                                       :owner => @requester,
                                   :protocol_id => params[:imaging_slide][:protocol_id],
                                   :imaging_date => Date.today,
                                   :created_at => Date.today,)

    # Get samples (dissections) based on parameters entered
    condition_array = define_sample_conditions(params)
    @samples = Sample.where(sql_where(condition_array)).order('barcode_key').all.to_a

    @checked = true
    render :action => 'new'
  end
  
  # GET /imaging_slides/1/edit
  def edit
    @imaging_slide = ImagingSlide.includes(:samples).find(params[:id])
    authorize! :update, @imaging_slide
  end

  # POST /imaging_slides
  def create
    #_deliberate_error_here
    # TODO: Add error checking
    #       Require at least one sample with sample position number
    #       Require integer sample position numbers (sequential integers?)
    @imaging_slide = ImagingSlide.new(create_params)
    authorize! :create, @imaging_slide

    if params[:imaging_slide][:slide_samples_attributes].empty?
      flash[:error] = 'ERROR - No valid samples provided for this slide'
      redirect_to(slide_setup_path)
    else
      if !@imaging_slide.save
        #error_found = true  # Validation or other error when saving to database
        flash.now[:error] = 'ERROR - Unable to create imaging slide'
        @samples = Sample.find(params[:imaging_slide][:slide_samples_attributes].pluck(:sample_id))
        @positions = params[:imaging_slide][:slide_samples_attributes].pluck(:sample_position)
        render :new
      else
        flash[:notice] = "Imaging slide successfully created"
        redirect_to(@imaging_slide)
      end
    end
  end

  # PUT /imaging_slides/1
  def update
    #_deliberate_error_here
    # TODO: Add error checking
    #       Use javascript to allow adding a sample to slide
    #       Also allow deleting a sample from slide
    #       Make sure at least one valid sample remains after deleting
    @imaging_slide = ImagingSlide.find(params[:id])
    authorize! :update, @imaging_slide

    # Deal with new samples which may have been added to slide
    sample_error = false
    if !params[:barcode_string].blank?
      @condition_array = define_sample_conditions(params)
      @samples = Sample.where(sql_where(@condition_array))
      if @samples.empty?
        sample_error = true
      else
        @imaging_slide.slide_samples.build(:sample_id => @samples[0].id, :sample_position => 9)
      end
    end

    if sample_error == true
      flash.now[:error] = "Invalid sample barcode(s) #{params[:barcode_string]} entered"
      dropdowns
      render :action => 'edit'
    elsif @imaging_slide.update_attributes(update_params)
      flash[:notice] = "Imaging slide has been updated"
      render :action => 'show'
    else
      flash.now[:error] = "Error updating imaging slide"
      render :action => 'edit'
    end
  end

  def show
    @imaging_slide = ImagingSlide.find(params[:id])
  end

  def index
    @imaging_slides = ImagingSlide.all
  end

  # DELETE /imaging_slides/1
  def destroy
    @imaging_slide = ImagingSlide.find(params[:id])
    authorize! :delete, @imaging_slide

    @imaging_slide.destroy
    flash[:notice] = 'Imaging slide successfully deleted'
    redirect_to imaging_slides_url
  end

protected
  def dropdowns
    @imaging_protocols = Protocol.find_for_protocol_type('I')
    @owners = Researcher.populate_dropdown('active_only')
  end

  def define_sample_conditions(params)
    combo_fields = {:barcode_string => {:sql_attr => ['samples.barcode_key']}}
    query_flds = {'standard' => {}, 'multi_range' => combo_fields, 'search' => {}}
    query_params = {:barcode_string => params[:barcode_string]}
    @where_select, @where_values = build_sql_where(query_params, query_flds, ["samples.source_sample_id IS NOT NULL"], [])

    return sql_where_clause(@where_select, @where_values)
  end

  def create_params
    params.require(:imaging_slide).permit(:protocol_id, :slide_number, :slide_description, :imaging_date, :notebook_ref,
                                          :owner,
                                        slide_samples_attributes: [:sample_id, :sample_position, :_destroy])
  end

  def update_params
    # Need to have :id in slide_samples_attributes to avoid duplicating existing samples
    #   on the slide, when adding another sample
    params.require(:imaging_slide).permit(:protocol_id, :slide_number, :slide_description, :imaging_date, :notebook_ref,
                                          :owner,
                                          slide_samples_attributes: [:id, :sample_id, :sample_position, :_destroy])
  end

end
