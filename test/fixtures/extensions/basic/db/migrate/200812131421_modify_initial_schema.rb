class ModifyInitialSchema < ActiveRecord::Migration[7.1]
  def self.up
    create_table "places", :force => true do |t|
    end
  end
  
  def self.down
    drop_table "places"
  end
end