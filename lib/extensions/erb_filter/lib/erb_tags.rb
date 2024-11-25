# See "erb_filter_extension.rb" for details.

module ErbTags
  include Radiant::Taggable

  desc %{
Filters its contents with Embedded Ruby.

*Usage*:

<pre><code><r:erb><% Time.now %></r:erb></code></pre>

produces something like:

<pre><code>Tue Mar 08 09:34:26 +0000 2011</code></pre>

You can use <code>@request</code> and <code>@session</code> to access request
and session details from your page in a manner similar to Rails 1.x views.
  }

  tag 'erb' do | tag |
    ErbFilter.filter( tag.expand )
  end
end