class ResearchersController < ApplicationController
  layout 'main/samples'
  authorize_resource :class => Researcher
  
  before_action :dropdowns, :only => [:new, :edit]
  
  # GET /researchers
  def index
    @researchers = Researcher.find_and_group_by_active_inactive
  end

  # GET /researchers/1
  def show
    @researcher = Researcher.includes(:user).find(params[:id])
  end

  # GET /researchers/new
  def new
    @researcher = Researcher.new
  end

  # GET /researchers/1/edit
  def edit
    @researcher = Researcher.includes(:user).find(params[:id])
  end

  # POST /researchers
  def create
    @researcher = Researcher.new(create_params)

    if @researcher.save
      flash[:notice] = 'Researcher was successfully created.'
      redirect_to(@researcher)
    else
      render :action => "new"
    end
  end

  # PUT /researchers/1
  def update
    @researcher = Researcher.find(params[:id])

    if @researcher.update_attributes(update_params)
      flash[:notice] = 'Researcher was successfully updated.'
      redirect_to(@researcher)
    else
      render :action => "edit"
    end
  end

  # DELETE /researchers/1
  def destroy
    @researcher = Researcher.find(params[:id])
    @researcher.destroy

    redirect_to(researchers_url)
  end
  
protected
  def dropdowns
    @users = User.all
  end

  def create_params
    params.require(:researcher).permit(:user_id, :researcher_name, :researcher_initials,
                                       :company, :phone_number, :active_inactive)
  end

  def update_params
    create_params
  end
end
