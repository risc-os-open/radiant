# Directory listing tags
# ======================
#
# Define tags that provide various kinds of directory listing.
#
#
# History
# -------
#
# 2011-03-06 (ADH): Imported into Radiant 0.9.1 as an Extension.
# 2013-10-24 (ADH): All listing entry anchors now named so that external
#                   pages can refer directly to a table row.

# Uncomment this if you reference any of your controllers in activate
# require_dependency 'application_controller'

class DirListTagsExtension < Radiant::Extension
  version "2.1"
  description %{
Adds tags which enumerate directory contents and return the result as
an HTML fragment.
}
  url "http://pond.org.uk/"
  
  # extension_config do |config|
  #   config.gem 'some-awesome-gem
  #   config.after_initialize do
  #     run_something
  #   end
  # end

  # See your config/routes.rb file in this extension to define custom routes
  
  def activate
    Page.send :include, DirListTags
  end
end
