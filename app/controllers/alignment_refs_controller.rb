class AlignmentRefsController < ApplicationController
  layout 'main/main'
  authorize_resource :class => AlignmentRef

  # GET /alignment_refs
  def index
    @alignment_refs = AlignmentRef.find_and_sort_all
  end

  # GET /alignment_refs/new
  def new
    @alignment_ref = AlignmentRef.new
  end

  # GET /alignment_refs/1/edit
  def edit
    @alignment_ref = AlignmentRef.find(params[:id])
  end

  # POST /alignment_refs
  def create
    @alignment_ref = AlignmentRef.new(create_params)

    if @alignment_ref.save
      flash[:notice] = 'AlignmentRef was successfully created.'
      redirect_to(alignment_refs_url)
    else
      render :action => "new" 
    end
  end

  # PUT /alignment_refs/1
  def update
    @alignment_ref = AlignmentRef.find(params[:id])

    if @alignment_ref.update_attributes(update_params)
      flash[:notice] = 'AlignmentRef was successfully updated.'
      redirect_to(alignment_refs_url)
    else
      render :action => "edit" 
    end
  end

  # DELETE /alignment_refs/1
  def destroy
    @alignment_ref.destroy
    redirect_to(alignment_refs_url) 
  end

protected
  def create_params
    params.require(:alignment_ref).permit(:alignment_key, :interface_name, :genome_build, :created_by)
  end

  def update_params
    create_params
  end
end

