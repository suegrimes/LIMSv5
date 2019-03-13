class IndexTagsController < ApplicationController
  layout 'main/samples'
  authorize_resource :class => IndexTag

  def edit
    @index_tag = IndexTag.find(params[:id])
  end

  def update
    @index_tag = IndexTag.find(params[:id])

    if @index_tag.update(update_params)
      flash[:notice] = "Index #{@index_tag.index_code} was successfully updated."
      redirect_to(adapter_path(:id => @index_tag.adapter_id))
    else
      render :action => "edit"
    end
  end

  # DELETE /categories/1
  def destroy
    @index_tag = IndexTag.find(params[:id])
    @index_tag.destroy

    redirect_to(adapter_path(:id => @index_tag.adapter_id))
  end

protected
  def update_params
    params.require(:index_tag).permit(:tag_nr, :tag_sequence)
  end
end
