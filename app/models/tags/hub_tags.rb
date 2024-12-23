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
# 2024-12-01 (ADH): Moved into Rails 7 rebuild core.
#
module Tags::HubTags
  require 'hub_sso_lib'

  include Radiant::Taggable
  include HubSsoLib::Core

  desc %{
Renders the containing elements only if the used <em>is</em> logged into Hub.
<pre><code><r:if_hubssolib_logged_in>...</r:if_hubssolib_logged_in></code></pre>
  }
  tag "if_hubssolib_logged_in" do |tag|
    page = tag.locals.page
    tag.expand if hubssolib_logged_in?
  end

  desc %{
Renders the containing elements only if the used <em>is not</em> logged into Hub.
<pre><code><r:unless_hubssolib_logged_in>...</r:unless_hubssolib_logged_in></code></pre>
  }
  tag "unless_hubssolib_logged_in" do |tag|
    page = tag.locals.page
    tag.expand unless hubssolib_logged_in?
  end


  desc %{
Renders the unique name of the currently logged in user (which will be
something like 'Anonymous' if not logged in - exact text depends on the
HubSsoLib Gem).
<pre><code><r:hubssolib_unique_name /></code></pre>
  }
  tag "hubssolib_unique_name" do |tag|
    page = tag.locals.page
    hubssolib_unique_name
  end

  desc %{
Calls HubSsoLib to obtain Flash tags, from the persistent cookie or the local
application, in order to display messages above pages. <strong>Beware of page
caching!</strong> You neither want transient flash messages cached, nor do you
want them ignored because the page is already in the cache. Use only with a
page type which bypasses caching, such as NewsPage.
<pre><code><r:hubssolib_flash_tags /></code></pre>
  }
  tag "hubssolib_flash_tags" do |tag|
    page = tag.locals.page
    apphelp_flash()
  end
end
