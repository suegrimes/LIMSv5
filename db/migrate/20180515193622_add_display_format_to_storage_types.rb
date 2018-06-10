class AddDisplayFormatToStorageTypes < ActiveRecord::Migration[5.1]
  def change
    add_column :storage_types, :display_format, "char(8)"
  end
end
