class StorageContainersController < ApplicationController
  layout  Proc.new {|controller| controller.request.xhr? ? false : 'main/samples'}

  def positions_used
    @id = params[:id]
    @storage_container = StorageContainer.find(@id)
    if @storage_container.nil?
      emsg = "Storage container not found for id: #{@id}"
      flash[:error] = emsg;
      if  request.xhr?
        return generic_error(:not_found, emsg)
      end
    end

    ssc = @storage_container.sample_storage_containers.to_a
    @positions_used = ssc.inject([]) {|array, r| array << r.position_in_container }
    respond_to do |format|
      format.json do
        render json: {positions_used: @positions_used}, status: :ok
      end
    end
  end
end
