module BulkUploadCols
  extend ActiveSupport::Concern

  def get_attributes(models)
    models_columns = []

    models.each do |model|
      h = {}
      h[:model] = model
      h[:allowed_cols] = model.column_names - ["updated_by", "created_at", "updated_at"]
      content_cols = model.content_columns.map {|cc| cc.name}
      special_cols = model.column_names - content_cols
      # regular content columns for this model
      #content_cols = content_cols - ["updated_by", "created_at", "updated_at"]
      # foreign key columns
      h[:fk_cols] = special_cols - ["id"]
      h[:allowed_values] = allowed_values(model)
      h[:mapped_values] = mapped_values(model)
      h[:fk_finders] = {} # place to put fk finders mao
      h[:headers] = []  # place to put verified header names
      h[:dups] = {}     # place to put dup indexes
      models_columns << h
    end
    return models_columns
  end

  # return string with model names from models_columns structure for error report
  def model_column_names(models_columns)
    model_names = ""
    models_columns.each do |mc|
      if model_names.empty?
        model_names = mc[:model].name
      else
        model_names = model_names + ', ' + mc[:model].name
      end
    end
    return model_names
  end

end
