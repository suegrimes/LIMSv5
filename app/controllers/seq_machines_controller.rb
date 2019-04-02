class SeqMachinesController < ApplicationController
  layout 'main/main'
  authorize_resource :class => SeqMachine
  before_action :dropdowns, :only => [:new, :edit]

  # GET /seq_machines
  def index
    @seq_machines = SeqMachine.all_sorted
  end

  # GET /seq_machines/new
  def new
    @seq_machine = SeqMachine.new
  end

  # GET /seq_machines/1/edit
  def edit
    @seq_machine = SeqMachine.find(params[:id])
  end
  
  def show
    @seq_machine = SeqMachine.find(params[:id])
  end

  # POST /seq_machines
  def create
    @seq_machine = SeqMachine.new(create_params)

    if @seq_machine.save
      flash[:notice] = 'SeqMachine was successfully created.'
      redirect_to(seq_machines_url)
    else
      render :action => "new" 
    end
  end

  # PUT /seq_machines/1
  def update
    @seq_machine = SeqMachine.find(params[:id])
    
    if @seq_machine.update_attributes(update_params)
      flash[:notice] = 'SeqMachine was successfully updated.'
      redirect_to(seq_machines_url)
    else
      render :action => "edit" 
    end
  end

  # DELETE /seq_machines/1
  def destroy
    @seq_machine = SeqMachine.find(params[:id])
    @seq_machine.destroy
    redirect_to(seq_machines_url) 
  end

protected
  def dropdowns
    @machine_types = Category.populate_dropdown_for_category('machine type')
  end

  def create_params
    params.require(:seq_machine).permit(:machine_name, :bldg_location, :machine_type, :machine_desc, :notes)
  end

  def update_params
    create_params
  end
end
