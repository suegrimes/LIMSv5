class SequencerKitsController < ApplicationController
  layout 'main/main'
  authorize_resource :class => SequencerKit

  before_action :dropdowns, :only => [:new, :edit, :create, :update]
  before_action :set_sequencer_kit, only: [:show, :edit, :update, :destroy]

  # GET /sequencer_kits
  def index
    @sequencer_kits = SequencerKit.order(:machine_type, :kit_name).all
  end

  # GET /sequencer_kits/1
  def show
  end

  # GET /sequencer_kits/new
  def new
    @sequencer_kit = SequencerKit.new
  end

  # GET /sequencer_kits/1/edit
  def edit
  end

  # POST /sequencer_kits
  def create
    @sequencer_kit = SequencerKit.new(create_params)

    if @sequencer_kit.save
      redirect_to sequencer_kits_url, notice: 'Sequencing kit was successfully created.'
    else
      render :new
    end
  end

  # PATCH/PUT /sequencer_kits/1
  def update
    if @sequencer_kit.update_attributes(update_params)
      redirect_to sequencer_kits_url, notice: 'Sequencing kit was successfully updated.'
    else
      render :edit
    end
  end

  # DELETE /sequencer_kits/1
  def destroy
    @sequencer_kit.destroy
    redirect_to sequencer_kits_url, notice: 'Storage type was successfully destroyed.'
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_sequencer_kit
      @sequencer_kit = SequencerKit.find(params[:id])
    end

    def dropdowns
      @machine_types = Category.populate_dropdown_for_category('machine type')
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def create_params
      params.require(:sequencer_kit).permit(:machine_type, :kit_type, :kit_name)
    end

    def update_params
      create_params
    end
end
