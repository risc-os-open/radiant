module Radiant

  # The Radiant::Config object emulates a hash with simple bracket methods
  # which allow you to get and set values in the configuration table:
  #
  #   Radiant::Config['setting.name'] = 'value'
  #   Radiant::Config['setting.name'] #=> "value"
  #
  # Currently, there is not a way to edit configuration through the admin
  # system so it must be done manually. The console script is probably the
  # easiest way to this:
  #
  #   % script/console production
  #   Loading production environment.
  #   >> Radiant::Config['setting.name'] = 'value'
  #   => "value"
  #   >>
  #
  # Radiant currently uses the following settings:
  #
  # admin.title               :: the title of the admin system
  # admin.subtitle            :: the subtitle of the admin system
  # defaults.page.parts       :: a comma separated list of default page parts
  # defaults.page.status      :: a string representation of the default page status
  # defaults.page.filter      :: the default filter to use on new page parts
  # dev.host                  :: the hostname where draft pages are viewable
  # local.timezone            :: the timezone name (`rake -D time` for full list)
  #                              used to correct displayed times
  # page.edit.published_date? :: when true, shows the datetime selector
  #                              for published date on the page edit screen
  #
  class Configuration < ::ApplicationRecord
    self.table_name = "config"

    after_save :update_cache

    class ConfigError < RuntimeError; end

    class << self
      def [](key)
        if table_exists?
          Radiant::Configuration.initialize_cache
          Rails.cache.read('Radiant::Configuration')[key]
        end
      end

      def []=(key, value)
        if table_exists?
          setting = find_or_initialize_by(key: key)
          setting.value = value
        end
      end

      def to_hash
        Hash[ *self.all.pluck(:key, :value).flatten ]
      end

      def initialize_cache
        if Rails.cache.read('Radiant::Configuration').nil?
          Rails.cache.write('Radiant::Configuration', Radiant::Configuration.to_hash)
        end
      end

      def site_settings
        @site_settings ||= %w{ site.title site.host local.timezone }
      end

      def default_settings
        @default_settings ||= %w{ default_locale defaults.page.filter defaults.page.parts defaults.page.fields defaults.page.status defaults.snippet.filter }
      end

      def user_settings
        @user_settings ||= ['user.allow_password_reset?']
      end

      # A convenient drying method for specifying a prefix and options common to several settings.
      #
      #   Radiant::Configuration do |config|
      #     config.namespace('secret', :allow_display => false) do |secret|
      #       secret.define('identity', :default => 'batman')      # defines 'secret.identity'
      #       secret.define('lair', :default => 'batcave')         # defines 'secret.lair'
      #       secret.define('longing', :default => 'vindication')  # defines 'secret.longing'
      #     end
      #   end
      #
      def namespace(prefix, options = {}, &block)
        prefix = [options[:prefix], prefix].join('.') if options[:prefix]
        with_options(options.merge(:prefix => prefix), &block)
      end
    end

    # The usual way to use a config item:
    #
    #    Radiant.configuration['key'] = value
    #
    # is equivalent to this:
    #
    #   Radiant::Configuration.find_or_create_by_key('key').value = value
    #
    def value=(param)
      newvalue = param.to_s
      if newvalue != self[:value]
        if boolean?
          self[:value] = (newvalue == "1" || newvalue == "true") ? "true" : "false"
        else
          self[:value] = newvalue
        end
        self.save!
      end
      self[:value]
    end

    # Requesting a config item:
    #
    #    key = Radiant.configuration['key']
    #
    # is equivalent to this:
    #
    #   key = Radiant::Configuration.find_or_create_by(key: 'key').value
    #
    # If the config item is boolean the response will be true or false. For items with :type => :integer it will be an integer,
    # for everything else a string.
    #
    def value
      if boolean?
        checked?
      else
        self[:value]
      end
    end

    # Returns true if the item key ends with '?'
    #
    def boolean?
      self.key.ends_with?("?")
    end

    # Returns true if the item is boolean and true.
    #
    def checked?
      return nil if self[:value].nil?
      boolean? && self[:value] == "true"
    end

    def update_cache
      Rails.cache.write('Radiant::Configuration', Radiant::Configuration.to_hash)
    end
  end
end

module Radiant
  def self.configuration
    Radiant::Configuration
  end
end
