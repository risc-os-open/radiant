require_dependency 'radiant'

class ApplicationController < ActionController::Base
  include LoginSystem

  protect_from_forgery

  # Hub single sign-on support. Run the Hub filters for all actions to ensure
  # activity timeouts etc. work properly. The login integration with Hub is
  # done using modifications to the forum's own mechanism in
  # 'lib/authentication_system.rb'.
  #
  require 'hub_sso_lib'
  include HubSsoLib::Core

  before_action :hubssolib_beforehand
  after_action  :hubssolib_afterwards

  # Rescue all exceptions (bad form) to rotate the Hub key (good) and render or
  # raise the exception again (rapid reload for default handling).
  #
  rescue_from ::Exception, with: :on_error_rotate_and_raise

  before_action :set_current_user
  before_action :set_timezone
  before_action :set_user_locale
  before_action :set_javascripts_and_stylesheets
  before_action :set_standard_body_style, :only => [:new, :edit, :update, :create]

  attr_accessor :configuration
  attr_reader :pagination_parameters
  helper_method :pagination_parameters

  def initialize
    super
    @configuration = Radiant::Configuration
  end

  # helpers to include additional assets from actions or views
  helper_method :include_stylesheet, :include_javascript

  def include_stylesheet(sheet)
    @stylesheets << sheet
  end

  def include_javascript(script)
    @javascripts << script
  end

  def template_name
    case self.action_name
      when 'index'
        'index'
      when 'new','create'
        'new'
      when 'show'
        'show'
      when 'edit', 'update'
        'edit'
      when 'remove', 'destroy'
        'remove'
      else
        self.action_name
    end
  end

  def rescue_action_in_public(exception)
    case exception
      when ActiveRecord::RecordNotFound, ActionController::UnknownController, ActionController::UnknownAction, ActionController::RoutingError
        render :template => "site/not_found", :status => 404
      else
        super
    end
  end

  private

    def set_current_user
      Current.user = current_user # lib/current.rb
    end

    def set_user_locale
      I18n.locale = current_user && !current_user.locale.blank? ? current_user.locale : Radiant::Configuration['default_locale']
    end

    def set_timezone
      zone = Radiant::Configuration['local.timezone']
      zone = Time.zone_default if zone.blank?

      Time.zone = zone
    rescue ArgumentError
      Time.zone = 'UTC'
    end

    def set_javascripts_and_stylesheets
      @stylesheets ||= []
      @stylesheets.concat %w(application)
      @javascripts ||= []
      @javascripts.concat %w(application)
    end

    def set_standard_body_style
      @body_classes ||= []
      @body_classes.concat(%w(reversed))
    end

    # Renders an exception, retaining Hub login. Regenerate any exception
    # within five seconds of a previous render to 'raise' to default Rails
    # error handling, which (in non-Production modes) gives additional
    # debugging context and an inline console, but loses the Hub session
    # rotated key, so you're logged out.
    #
    def on_error_rotate_and_raise(exception)
      hubssolib_get_session_proxy()
      hubssolib_afterwards()

      Rails.logger.debug(exception.message)
      Rails.logger.debug(exception.backtrace.join("\n"))

      if session[:last_exception_at].present?
        last_at = Time.parse(session[:last_exception_at]) rescue nil
        raise if last_at.present? && Time.now - last_at < 5.seconds
      end

      session[:last_exception_at] = Time.now.iso8601(1)
      render 'exception', locals: { exception: exception }
    end

end
