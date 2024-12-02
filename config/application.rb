require_relative "boot"

require "rails"
require "active_model/railtie"
require "active_record/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_view/railtie"
require "rails/test_unit/railtie"

Bundler.require(*Rails.groups)

module Radiant
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w(assets tasks))

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # https://guides.rubyonrails.org/caching_with_rails.html#activesupport-cache-memorystore
    config.cache_store = :memory_store, { size: 32*1024*1024 }

    # Custom validation error handling.
    #
    config.action_view.field_error_proc = Proc.new do |html_tag, instance|
      if html_tag !~ /label/
        error_span = tag.span([instance.error_message].flatten.first, class: 'error')
        tag.span(html_tag << error_span, class: 'error-with-field')
      else
        html_tag
      end
    end
  end
end
