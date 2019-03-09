class FreezerLocationsController < ApplicationController
  layout 'main/samples'
  authorize_resource :class => FreezerLocation

  # GET /freezer_locations
  def index
    @freezer_locations = FreezerLocation.list_all_by_room
  end

  # GET /freezer_locations/1
  def show
    @freezer_location = FreezerLocation.find(params[:id])
  end

  # GET /freezer_locations/new
  def new
    @freezer_location = FreezerLocation.new
  end

  # GET /freezer_locations/1/edit
  def edit
    @freezer_location = FreezerLocation.find(params[:id])
  end

  # POST /freezer_locations
  def create
    @freezer_location = FreezerLocation.new(create_params)

    if @freezer_location.save
      flash[:notice] = 'FreezerLocation was successfully created.'
      redirect_to(@freezer_location)
    else
      render :action => "new" 
    end
  end

  # PUT /freezer_locations/1
  def update
    @freezer_location = FreezerLocation.find(params[:id])

    if @freezer_location.update_attributes(update_params)
      flash[:notice] = 'FreezerLocation was successfully updated.'
      redirect_to(@freezer_location)
    else
      render :action => "edit" 
    end
  end

  # DELETE /freezer_locations/1
  def destroy
    @freezer_location = FreezerLocation.find(params[:id])
    @freezer_location.destroy
    redirect_to(freezer_locations_url) 
  end

  protected
  def create_params
    params.require(:freezer_location).permit(:room_nr, :freezer_nr, :owner_name, :owner_email, :comments)
  end

  def update_params
    create_params
  end
end
