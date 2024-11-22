class ConfigDataset < Dataset::Base
  def load
    # Simulates the defaults on bootstrapped Radiant instances
    Radiant::Configuration['admin.title'] = 'Radiant CMS'
    Radiant::Configuration['admin.subtitle'] = 'Publishing for Small Teams'
    Radiant::Configuration['defaults.page.parts'] = 'body, extended'
    Radiant::Configuration['defaults.page.status'] = 'Draft'
    Radiant::Configuration['defaults.page.filter'] = nil
    Radiant::Configuration['defaults.page.fields'] = 'Keywords, Description'
    Radiant::Configuration['defaults.snippet.filter'] = nil
    Radiant::Configuration['session_timeout'] = 2.weeks
    Radiant::Configuration['default_locale'] = 'en'
  end
end
