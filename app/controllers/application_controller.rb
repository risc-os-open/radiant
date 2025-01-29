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
  # Some old Rails-2 style handling by Radiant is wrapped up in here too, via
  # calling a method which subclasses can override if they wish.
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

  # This is a sort of hack for the ERB filter and snippets that we want to
  # keep identical in shared files across applications, or in the database
  # copy that Radiant has (which is considered the master).
  #
  # In 2025 the render mechanism was updated to include a controller binding
  # so that ERB ran as if rendered as a view, but this means calling "render"
  # is forbidden else Double Render Error issues arise. Older snippet code
  # could check "respond_to? :render" since there was no controller binding
  # and no render method available. Newer snippets now use the unique helper
  # method below, that's only ever defined in Radiant and nowhere else.
  #
  def appctrl_radiant_snippets_are_available
    true
  end

  protected

    # Overridable in subclasses and invoked from #on_error_rotate_and_raise.
    # Subclass implementation should handle whichever exceptions they want via
    # a 'case' statement; in 'else', you must call 'super'.
    #
    def handle_special_case_exception(exception)
      case exception
        when ActiveRecord::RecordNotFound, AbstractController::ActionNotFound
          render template: 'site/not_found', status: 404
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

    # Used for the unusual range of ".foo" formats that might arise for a
    # family of XML-based responses; #on_error_rotate_and_raise needs to
    # know what the format in which to render an error.
    #
    XML_LIKE_MAP = {
      xml:           'application/xml',
      rss:           'application/rss+xml',
      rss20:         'application/rss+xml',
      atom:          'application/atom+xml',
      atom10:        'application/atom+xml',
      rsd:           'application/rsd+xml',
      googlesitemap: 'application/xml',
    }

    XML_LIKE_MAP.each do | format, mime |
      known_mime = Mime::Type.lookup_by_extension(format)
      Mime::Type.register(mime, format) if known_mime.blank?
    end

    XML_LIKE_FORMATS = XML_LIKE_MAP.keys.freeze

    # Renders an exception, retaining Hub login. Regenerate any exception
    # within five seconds of a previous render to 'raise' to default Rails
    # error handling, which (in non-Production modes) gives additional
    # debugging context and an inline console, but loses the Hub session
    # rotated key, so you're logged out.
    #
    def on_error_rotate_and_raise(exception)
      handle_special_case_exception(exception)

      hubssolib_get_session_proxy()
      hubssolib_afterwards()

      Rails.logger.debug(exception.message)
      Rails.logger.debug(exception.backtrace.join("\n"))

      if session[:last_exception_at].present?
        last_at = Time.parse(session[:last_exception_at]) rescue nil
        raise if last_at.present? && Time.now - last_at < 5.seconds
      end

      session[:last_exception_at] = Time.now.iso8601(1)
      locals                      = { exception: exception }

      # The top-of-this-method call to #handle_special_case_exception may have
      # caused a redirection or render already, so check #performed? for that.
      #
      # Depending on application, XML variants can be numerous - e.g. ".rss",
      # ".rss20" and so-on - so use that as a default for anything that is not
      # otherwise explicitly recognised as a JSON or HTML request.
      #
      unless performed?
        respond_to do | format |
          format.html { render 'exception', locals: locals }
          format.json { render 'exception', locals: locals, formats: :json }

          format.any(*XML_LIKE_FORMATS) do
            render 'exception', locals: locals, formats: :xml
          end
        end
      end
    end

end
