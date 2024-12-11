if CONFIGURED_DATABASE_AVAILABLE

  require_relative '../../app/models/application_record'
  require_relative '../../app/models/radiant/configuration'

  Radiant.configuration do |config|
    config.define 'admin.title', :default => "Radiant CMS"
    config.define 'dev.host'
    config.define 'local.timezone', :allow_change => true, :select_from => lambda { ActiveSupport::TimeZone::MAPPING.keys.sort }
    config.define 'defaults.locale', :select_from => lambda { Radiant::AvailableLocales.locales }, :allow_blank => true
    config.define 'defaults.page.parts', :default => "Body,Extended"
    config.define 'defaults.page.status', :select_from => lambda { Status.selectable_values }, :allow_blank => false, :default => "Draft"
    config.define 'defaults.page.filter', :select_from => lambda { ::Filters::TextFilter.descendants.map { |s| s.filter_name }.sort }, :allow_blank => true
    config.define 'defaults.page.fields'
    config.define 'admin.pagination.per_page', :type => :integer, :default => 50
    config.define 'site.title', :default => "Your site title", :allow_blank => false
    config.define 'site.host', :default => "www.example.com", :allow_blank => false
    config.define 'user.allow_password_reset?', :default => true
  end

end
