class StorageTypesController < ApplicationController
  layout 'main/main'
  authorize_resource :class => StorageType

  before_action :set_storage_type, only: [:show, :edit, :update, :destroy]

  # GET /storage_types
  def index
    @storage_types = StorageType.all
  end

  # GET /storage_types/1
  def show
  end

  # GET /storage_types/new
  def new
    @storage_type = StorageType.new
  end

  # GET /storage_types/1/edit
  def edit
  end

  # POST /storage_types
  def create
    @storage_type = StorageType.new(create_params)

    if @storage_type.save
      redirect_to storage_types_url, notice: 'Storage type was successfully created.'
    else
      render :new
    end
  end

  # PATCH/PUT /storage_types/1
  def update
    if @storage_type.update_attributes(update_params)
      redirect_to storage_types_url, notice: 'Storage type was successfully updated.'
    else
      render :edit
    end
  end

  # DELETE /storage_types/1
  def destroy
    @storage_type.destroy
    redirect_to storage_types_url, notice: 'Storage type was successfully deleted'
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_storage_type
      @storage_type = StorageType.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def create_params
      params.require(:storage_type).permit(:container_type, :nr_cols, :nr_rows, :first_col, :first_row, :freezer_type, :notes)
    end

    def update_params
      create_params
    end
end
