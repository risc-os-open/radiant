class ResetConfigurationDefaults < ActiveRecord::Migration[8.0]

  # This asserts "lib/radiant/setup.rb" #load_default_configuration values,
  # for configuration that differs from at-time-of-writing ROOL live data.
  #
  def up
    Radiant::Configuration['defaults.page.parts' ] = 'body, extended'
    Radiant::Configuration['defaults.page.status'] = 'Draft'
    Radiant::Configuration['defaults.page.filter'] = nil
    Radiant::Configuration['defaults.page.fields'] = 'Keywords, Description'
    Radiant::Configuration['default_locale'      ] = 'en'
    Radiant::Configuration['session_timeout'     ] = 2.weeks
  end

  # This restores settings in the current ROOL live data.
  #
  def down
    Radiant::Configuration['defaults.page.status'] = ''
    Radiant::Configuration['defaults.page.fields'] = ''

    Radiant::Configuration.find_by_key('default_locale' )&.destroy
    Radiant::Configuration.find_by_key('session_timeout')&.destroy
  end

end
