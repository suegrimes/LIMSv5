class AdaptersController < ApplicationController
  layout 'main/main'
  authorize_resource :class => Adapter
  
  # GET /adapters
  def index
    @adapters = Adapter.order(:runtype_adapter).includes(:index_tags).all
  end

  # GET /adapters/1
  def show
    @adapter = Adapter.includes(:index_tags).order('index_tags.index_read, index_tags.tag_nr').find(params[:id])
  end

  # GET /adapters/new
  def new
    @adapter = Adapter.new
    12.times {@adapter.index_tags.build}
  end

  # POST /adapters
  def create
    @adapter = Adapter.new(create_params)

    if @adapter.save
      flash[:notice] = 'Adapter and multiplex indices were successfully created.'
      redirect_to(@adapter)
    else
      render :action => "new"
    end
  end

  # GET /adapters/1/edit
  def edit
    @adapter = Adapter.includes(:index_tags).order('index_tags.index_read, index_tags.tag_nr').find(params[:id])
  end

  # PUT /adapters/1
  def update
    
    @adapter = Adapter.find(params[:id])
    if @adapter.update_attributes(update_params)
      
      # Delete any adapter value records which were removed/deleted from edit screen
      params[:adapter][:index_tags_attributes].each do |ikey, iattrs|
        IndexTag.destroy(iattrs[:id]) if iattrs[:tag_sequence].blank?
      end
      
      flash[:notice] = "Successfully updated adapter and multiplex indices"
      redirect_to(@adapter)
    else
      render :action => 'edit'
    end
    
  end

  # DELETE /adapters/1
  def destroy
    @adapter = Adapter.find(params[:id])
    @adapter.destroy

    redirect_to(adapters_url)
  end

protected
  def create_params
    params.require(:adapter).permit(:runtype_adapter, :mplex_splex, :multi_indices, :index_position, :tag_length,
                                    :index1_prefix, :index2_prefix,
                                    index_tags_attributes: [:id, :index_read, :tag_nr, :tag_sequence, :_destroy] )
  end

  def update_params
    create_params
  end
end
