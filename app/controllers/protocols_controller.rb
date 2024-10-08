class ProtocolsController < ApplicationController
  layout 'main/main'
  authorize_resource :class => Protocol

  def query_params
    if request.post?
      selected_type = Protocol::PROTOCOL_TYPES[params[:protocol_type]]
      redirect_to :action => :index, :type => selected_type
    else
      @protocol_types = Protocol::PROTOCOL_TYPES.keys
    end
  end
  
  # GET /protocols
  def index
    if params[:type].blank?
      @protocols = Protocol.all.order(:protocol_type, :protocol_name)
    else
      @protocols = Protocol.find_for_protocol_type(params[:type])
    end
  end

  # GET /protocols/1
  def show
    @protocol = Protocol.find(params[:id])
    @protocol_type_name = Protocol::PROTOCOL_TYPE_NAMES[@protocol.protocol_type]
  end

  # GET /protocols/new
  def new
    #If passed protocol_type exists and is a single value (string or single value array),
    #  set protocol_type in the new object (to set selected value in drop-down)
    protocol_type = params[:protocol_type] ||= "TBD"
    protocol_type = protocol_type.length == 1 ? protocol_type[0] : "TBD"
    @protocol = Protocol.new(:protocol_type => protocol_type)
  end

  # GET /protocols/1/edit
  def edit
    @protocol = Protocol.find(params[:id])
  end

  # POST /protocols
  def create
    @protocol = Protocol.new(create_params)

    if @protocol.save
      flash[:notice] = 'Protocol was successfully created.'
      redirect_to(@protocol)
    else
      render :action => "new"
    end
  end

  # PUT /protocols/1
  def update
    @protocol = Protocol.find(params[:id])

    if @protocol.update_attributes(update_params)
      flash[:notice] = 'Protocol was successfully updated.'
      redirect_to(@protocol)
    else
      render :action => "edit"
    end
  end

  # DELETE /protocols/1
  def destroy
    @protocol = Protocol.find(params[:id])
    @protocol.destroy

   redirect_to(protocols_url)
  end

protected
  def create_params
    params.require(:protocol).permit(:protocol_name, :protocol_abbrev,  :protocol_version, :protocol_type,
                                   :protocol_code, :reference, :comments)
  end

  def update_params
    create_params
  end
end