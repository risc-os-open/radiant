class AddSaltToUsers < ActiveRecord::Migration[7.1]
  def self.up
    add_column :users, :salt, :string
    User.reset_column_information
    User.update_all :salt => "sweet harmonious biscuits"
  end

  def self.down
    remove_column :users, :salt
  end
end
