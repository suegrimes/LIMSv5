module StorageManagement
  extend ActiveSupport::Concern

  def storage_container_ui_data
logger.debug "storage_container_ui_data start"
    @container_types    = StorageType.all
    @container_dimensions = StorageType.container_dimensions
    @container_data     = StorageContainer.container_data
    @container_type_freezer = StorageContainer.container_type_freezer
logger.debug "storage_container_ui_data end"
  end

  # create a new storage_container based on data in an instance of
  # sample_storage_container attributes
  # if saved, merge the new storage container id into the attributes hash
  # return the status and an error message on error
  def create_storage_container(sample_storage_container_attributes)
    # find the matching storage_type
    container_type = sample_storage_container_attributes[:container_type]
    storage_type = StorageType.where(container_type: container_type).first
    unless storage_type
      return false, "Storage container type: #{container_type} not found"
    end
    storage_container_params = {
      container_type: container_type,
      container_name: sample_storage_container_attributes[:container_name],
      freezer_location_id: sample_storage_container_attributes[:freezer_location_id],
      notes: sample_storage_container_attributes[:notes],
      freezer_type: storage_type.freezer_type
    }
    storage_container = StorageContainer.new(storage_container_params)
    unless storage_container.save
      error_messages = ""
      storage_container.errors.full_messages.each {|e| error_messages << "#{e}; " } 
      return false, "New storage container could not be saved: #{error_messages}"
    end

    # set the new storage container id
    sample_storage_container_attributes.merge!(storage_container_id: storage_container.id)

    return true, nil
  end

end
