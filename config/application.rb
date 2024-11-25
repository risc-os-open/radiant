require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
# require "active_job/railtie"
require "active_record/railtie"
# require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
# require "action_mailbox/engine"
# require "action_text/engine"
require "action_view/railtie"
# require "action_cable/engine"
require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Radiant
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w(assets tasks))

    # Load all plugins in "lib".
    #
    Dir.glob(Rails.root.join('lib', 'plugins', '**/init.rb')) { | ruby_file | require ruby_file }

    # Load all extensions in "lib" once everything else is set up (so that the
    # lazy autoloader etc. all work).
    #
    Rails::Application::Finisher.initializer 'zebra.rool.radiant.extensions.load' do
      extensions = []

      Dir.glob(Rails.root.join('lib', 'extensions', '**/*')) do | item |
        components = Pathname.new(item).each_filename.to_a()
        next if components.include?('test') || components.include?('spec')

        if item.end_with?('.yml')
          I18n.load_path << item
        elsif item == 'Rakefile'
          require item
        elsif item.end_with?('.rb')
          require item

          leaf_name = File.basename(item)[..-4] # (remove 'rb')
          new_thing = leaf_name.camelize.constantize rescue nil

          extensions << new_thing if new_thing.try(:superclass) == Radiant::Extension
        end
      end

      extensions.each { | extension | extension.new.activate() }
    end

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")
  end
end
