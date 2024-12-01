class RenameBehaviorColumn < ActiveRecord::Migration[7.1]
  def self.up
    rename_column :pages, :behavior, :behavior_id
  end

  def self.down
    rename_column :pages, :behavior_id, :behavior
  end
end
