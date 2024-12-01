class AddUserLanguage < ActiveRecord::Migration[7.1]
  def self.up  
    add_column :users, :language, :string
  end

  def self.down    
    remove_column :users, :language
  end
end
