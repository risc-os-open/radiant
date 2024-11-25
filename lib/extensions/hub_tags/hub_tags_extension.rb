# Hub tags
# ========
#
# Define tags for Hub integration.
#
#
# History
# -------
#
# 2011-03-06 (ADH): Imported into Radiant 0.9.1 as an Extension.

require_dependency 'application_controller'

class HubTagsExtension < Radiant::Extension
  version "2.0"
  description %{
Support integration with Hub through a set of Radiant tags and by running the
prerequisite Hub integration support code inside the Application Controller.
}
  url "http://hub.pond.org.uk/"

  # extension_config do |config|
  #   config.gem 'some-awesome-gem
  #   config.after_initialize do
  #     run_something
  #   end
  # end

  # See your config/routes.rb file in this extension to define custom routes

  def activate
    ApplicationController.class_eval do
      require 'hub_sso_lib'
      include HubSsoLib::Core
      before_action :hubssolib_beforehand
      after_action :hubssolib_afterwards
    end

    Page.send :include, HubTags
  end
end
