class RenameTypeColumnOnPageToClassName < ActiveRecord::Migration[7.1]
  def self.up
    rename_column 'pages', 'type', 'class_name'
  end

  def self.down
    rename_column 'pages', 'class_name', 'type'
  end
end
