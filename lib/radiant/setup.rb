require "highline"
require "forwardable"

module Radiant
  class Setup

    def self.bootstrap(config)
      setup = self.new
      setup.bootstrap(config)
      setup
    end

    attr_accessor :config

    def bootstrap(config)

      # Curious bug seen; when creating the admin user, "developer" was set as
      # an attribute in the new User instance instead of "designer". This comes
      # from running the Rake "db:bootstrap" task that inherits "initialize".
      # The latter runs all migrations rather than loading schema, and some of
      # the migrations reference models such as User. This loads attribute data
      # from the database state *then* but for e.g. User, the "developer"
      # column is later renamed to "designer".
      #
      # Work around this by forcing a reset in all models.
      #
      ApplicationRecord.descendants.map(&:reset_column_information)

      @config = config
      @admin = create_admin_user(config[:admin_name], config[:admin_username], config[:admin_password])
      User.current_user = @admin
      load_default_configuration
      announce "Finished."
    end

    def create_admin_user(name, username, password)
      unless name and username and password
        announce "Create the admin user (press enter for defaults)."
        name = prompt_for_admin_name unless name
        username = prompt_for_admin_username unless username
        password = prompt_for_admin_password unless password
      end
      attributes = {
        :name => name,
        :login => username,
        :password => password,
        :password_confirmation => password,
        :admin => true
      }
      admin = User.new(attributes)
      admin.save!
      admin
    end

    def load_default_configuration
      feedback "\nInitializing configuration" do
        step { Radiant::Configuration['admin.title'   ] = 'Radiant CMS' }
        step { Radiant::Configuration['admin.subtitle'] = 'Publishing for Small Teams' }
        step { Radiant::Configuration['defaults.page.parts' ] = 'body, extended' }
        step { Radiant::Configuration['defaults.page.status' ] = 'Draft' }
        step { Radiant::Configuration['defaults.page.filter' ] = nil }
        step { Radiant::Configuration['defaults.page.fields'] = 'Keywords, Description' }
        step { Radiant::Configuration['session_timeout'] = 2.weeks }
        step { Radiant::Configuration['default_locale'] = 'en' }
      end
    end

    private

      def prompt_for_admin_name
        username = ask('Name (Administrator): ', String) do |q|
          q.validate = /^.{0,100}$/
          q.responses[:not_valid] = "Invalid name. Must be at less than 100 characters long."
          q.whitespace = :strip
        end
        username = "Administrator" if username.blank?
        username
      end

      def prompt_for_admin_username
        username = ask('Username (admin): ', String) do |q|
          q.validate = /^(|.{3,40})$/
          q.responses[:not_valid] = "Invalid username. Must be at least 3 characters long."
          q.whitespace = :strip
        end
        username = "admin" if username.blank?
        username
      end

      def prompt_for_admin_password
        password = ask('Password (radiant): ', String) do |q|
          q.echo = false unless defined?(::JRuby) # JRuby doesn't support stty interaction
          q.validate = /^(|.{5,40})$/
          q.responses[:not_valid] = "Invalid password. Must be at least 5 characters long."
          q.whitespace = :strip
        end
        password = "radiant" if password.blank?
        password
      end

      extend Forwardable
      def_delegators :terminal, :agree, :ask, :choose, :say

      def terminal
        @terminal ||= HighLine.new
      end

      def output
        terminal.instance_variable_get("@output")
      end

      def wrap(string)
        string = terminal.send(:wrap, string) unless terminal.wrap_at.nil?
        string
      end

      def print(string)
        output.print(wrap(string))
        output.flush
      end

      def puts(string = "\n")
        say string
      end

      def announce(string)
        puts "\n#{string}"
      end

      def feedback(process, &block)
        print "#{process}..."
        if yield
          puts "OK"
          true
        else
          puts "FAILED"
          false
        end
      rescue Exception => e
        puts "FAILED"
        raise e
      end

      def step
        yield if block_given?
        print '.'
      end

  end
end
