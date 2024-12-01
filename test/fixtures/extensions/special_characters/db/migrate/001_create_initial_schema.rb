class CreateInitialSchema < ActiveRecord::Migration[7.1]
  def self.up
    create_table "people", :force => true do |t|
    end
  end
  
  def self.down
    drop_table "people"
  end
end
