class ImageSlidesController < ApplicationController
  include SqlQueryBuilder
  layout 'main/main'
  
  #CanCan tries to validate all param values in hash and complains about barcode_string
  # which is not a 'permitted' attribute since is not in model, so can't use load_and_authorize_resource
  #load_and_authorize_resource

  before_action :setup_dropdowns, :only => [:setup_params, :new, :edit]
  def setup_params
    authorize! :new, ImageSlide
  end
  def new
    authorize! :new, ImageSlide
    @requester = (current_user.researcher ? current_user.researcher.researcher_name : nil)
    @image_slide  = ImageSlide.new(:updated_by => @requester,
                                   :machine_type => params[:image_slide][:machine_type],
                                   :created_at => Date.today,)

    # Get samples (dissections) based on parameters entered
    @condition_array = define_sample_conditions(params)
    @samples = Sample.where(sql_where(@condition_array)).order('barcode_key').all.to_a

    @checked = true
    render :action => 'new'
  end
  
  # GET /image_slides/1/edit
  def edit
    @image_slide = ImageSlide.includes(:samples).find(params[:id])
    authorize! :update, @image_slide
  end

  # POST /image_slides
  def create
    #_deliberate_error_here
    @image_slide = ImageSlide.new(create_params)
    authorize! :create, @image_slide

    if params[:image_slide][:slide_samples_attributes].empty?
      flash[:error] = 'ERROR - No valid samples provided for this slide'
      redirect_to(slide_setup_path)
    else
      if !@image_slide.save
        #error_found = true  # Validation or other error when saving to database
        flash.now[:error] = 'ERROR - Unable to create imaging slide'
      else
        flash[:notice] = "Imaging slide successfully created"
        redirect_to(@image_slide)
      end
    end
  end

  # PUT /image_slides/1
  def update
    #_deliberate_error_here
    @image_slide = ImageSlide.find(params[:id])
    authorize! :update, @image_slide

    # If sample position has not been changed it will be blank => remove from params so that
    # duplicate record is not created
    #params[:image_slide][:slide_samples_attributes][:sample_id] ||= []
    #params[:image_slide][:sample_ids].reject!{|id| id.blank? || id == '0'}
    #@image_slide.samples = Sample.find(params[:image_slide][:sample_ids])

    # Deal with new samples which may have been added to slide
    sample_error = false
    if !params[:barcode_string].blank?
      @condition_array = define_sample_conditions(params)
      @samples = Sample.where(sql_where(@condition_array))
      if @samples.empty?
        sample_error = true
      else
        @image_slide.samples << @samples
      end
    end

    if sample_error == true
      flash.now[:error] = "Invalid sample barcode(s) #{params[:barcode_string]} entered"
      render :action => 'edit'
    elsif @image_slide.update_attributes(update_params)
      flash[:notice] = "Image slide has been updated"
      #redirect_to @image_slide
      render :action => 'show'
    else
      flash.now[:error] = "Error updating image slide"
      render :action => 'edit'
    end
  end

  def show
    @image_slide = ImageSlide.find(params[:id])
  end

  def index
    @image_slides = ImageSlide.all
  end

  # DELETE /image_slides/1
  def destroy
    @image_slide = ImageSlide.find(params[:id])
    authorize! :delete, @image_slide

    @image_slide.destroy
    flash[:notice] = 'Imaging slide successfully deleted'
    redirect_to image_slides_url
  end

protected
  def setup_dropdowns
    @category_dropdowns = Category.populate_dropdowns([Cgroup::CGROUPS['Imaging']])
    @imager_types      = category_filter(@category_dropdowns, 'imager_type')
  end
  def define_sample_conditions(params)
    combo_fields = {:barcode_string => {:sql_attr => ['samples.barcode_key']}}
    query_flds = {'standard' => {}, 'multi_range' => combo_fields, 'search' => {}}
    query_params = {:barcode_string => params[:barcode_string]}
    @where_select, @where_values = build_sql_where(query_params, query_flds, ["samples.source_sample_id IS NOT NULL"], [])

    return sql_where_clause(@where_select, @where_values)
  end

  def create_params
    params.require(:image_slide).permit(:machine_type, :slide_number, :slide_name,
                                        slide_samples_attributes: [:sample_id, :sample_position])
  end

  def update_params
    params.require(:image_slide).permit(:machine_type, :slide_number, :slide_name,
                                        slide_samples_attributes: [:id, :sample_id, :sample_position])
  end
end
