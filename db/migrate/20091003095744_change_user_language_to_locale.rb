class ChangeUserLanguageToLocale < ActiveRecord::Migration[7.1]
  def self.up
    rename_column 'users', 'language', 'locale'
  end

  def self.down
    rename_column 'users', 'locale', 'language'
  end
end
