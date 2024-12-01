# News tag
# ========
#
# Defines a tag to produce a "latest news" summary based on an XML feed.
#
#
# History
# -------
#
# 2006-08-06 (ADH): Created.
# 2006-08-07 (ADH): It seems the core RSS features are easily sufficient
#                   so fun though Simple-RSS was, it makes sense to use
#                   something that doesn't add extra dependencies. Moved
#                   over to the Ruby RSS parser. Since tags get expanded
#                   before filters run, but there is no way to escape
#                   text filtered by (say) Textile, instead get rid of
#                   characters known to be a problem.
# 2006-08-08 (ADH): Now knows about the prevalent part filter during tag
#                   processing and takes steps to escape the generated
#                   content. Markdown doesn't seem to need it but Textile
#                   is escaped; it turns out there is a '<notextile>' tag
#                   which does the job. Generating HTML from a tag is
#                   still conceptually wrong because of filter operations
#                   but for now I still want to keep this behaviour very
#                   simple for its users. There is an RSS behaviour which
#                   can be used if a more flexible scheme is required at
#                   the expense of more effort and less clean handling of
#                   empty RSS item fields.
# 2006-11-09 (ADH): Added 'escaped' attribute to deal with feeds which
#                   have already had "%xx" hex escape sequences applied
#                   in URIs, as well as feeds that have not.
# 2011-03-06 (ADH): Imported into Radiant 0.9.1 as an Extension.
# 2011-03-16 (ADH): Added Atom feed compatibility.
# 2013-08-30 (ADH): Added SSL certificate chain fetch support.
# 2019-09-10 (ADH): Escape "[" and "]" in titles, as this seemed to cause
#                   layout problems; implication was that CMS parsed the
#                   output data as if Textile markup.
# 2024-12-01 (ADH): Moved into Rails 7 rebuild core.
#
require 'uri'
require 'net/https'

module Tags::NewsTags
  include Radiant::Taggable

  desc %{
Supply the tag with a "feed" parameter, which provides a
fully qualified URL pointing to an XML RSS feed. The feed is
parsed and a 'latest news' summary generated from it. Example:

<pre><code>
<r:news feed="http://my.url/news.xml" headlines="4" dates="0" />
</code></pre>

A 'headlines' attribute is optional; it defines how many entries
will be included in the news summary and defaults to '4'.

A 'dates' attribute is also optional; it says whether or not
article published or modified dates (if found) will be added in
small text after each headline. If '0' there are no dates, else
dates are shown. The default value is '1', to show dates. Dates are
extracted from the feed's "pubDate", "modified" or "dc_date" fields,
in that order.

An optional 'https' attribute defaults to '0'. If '1', HTTP URLs
are upgraded to HTTPS if request.ssl? is true, else they are left
alone.

An optional 'escaped' attribute (not to be confused with 'escape',
below!) states whether or not the feed URIs themselves are already
escaped for including in links (i.e. there is use of "%xx" escape
sequences where "xx" is a two digit hex number). Defaults to zero;
URI.escape() will be run on the links. If set to a non-zero value,
URI.escape() will not be called though "~" characters will still
be substituted with '%7E'.

Finally, an optional 'escape' attribute, defaulting to '1', ensures
that RSS titles or links cannot be accidentally interpreted as
Textile data for Textile filtered parts. Setting the attribute to
'0' disables escaping to allow headlines marked up in Textile to be
passed through to the Textile parser.

Note that '<' and '>' characters in RSS item titles will always be
escaped to HTML entities for security.

If you want to use HTTPS fetches for feeds and your HTTPS server
requires a certificate chain, you'll need to ensure that Radiant
runs with environment variable SSL_CERT_CHAIN pointing to the
full file path of the relevant ".crt" bundle. Otherwise you will
see SSL errors thrown by Ruby instead of your parsed XML data.
}
  tag "news" do |tag|

    feed      = tag.attr['feed']
    dates     = (tag.attr['dates']     || '1').to_i
    to_https  = (tag.attr['https']     || '0').to_i
    escape    = (tag.attr['escape']    || '1').to_i
    escaped   = (tag.attr['escaped']   || '0').to_i
    headlines = (tag.attr['headlines'] || '4').to_i

    raise TagError.new("No feed URL given in `news' tag") if (feed.nil? or feed.empty?)

    # Fetch the feed and parse it.

    uri = URI.parse(feed)
    rss = if (uri.scheme == 'https')

      cert_chain         = ENV['SSL_CERT_CHAIN']
      https              = Net::HTTP.new(uri.host, uri.port)
      https.use_ssl      = true
      https.verify_mode  = OpenSSL::SSL::VERIFY_NONE # OpenSSL::SSL::VERIFY_PEER
      https.ca_file      = cert_chain unless (cert_chain.nil? || cert_chain.empty?)

      feed_data = https.start do |http|
        request  = Net::HTTP::Get.new(uri.request_uri)
        response = https.request(request)

        raise "#{ response.code }: #{ response.messages }" unless (response.code.to_i >= 200 && response.code.to_i <= 299)
        response.body
      end

      RSS::Parser.parse(feed_data)

    else
      RSS::Parser.parse(feed)

    end

    done = 0
    out  = "<ul>\n"

    # Escape the data for Textile filtered pages if required.

    if (escape != 0 and @filter == 'Textile')
      out = '<notextile>' + out
    end

    # Loop through all items in the feed.

    rss.items.each do |item|

      # The item must have at least a title. The respond_to? check is to
      # cope with normal (string) versus Atom (structure) feed behaviour.

      if item.title.respond_to?(:empty?)
        title = item.title
      else
        title = item.title.content
      end

      next if (title.blank?)

      # If we've got a title, increase the headline count and bail if
      # the limit has been exceeded.

      done += 1
      break if (done > headlines)

      # Add HTML for this item to the output string.

      out << '  <li>'

      # Ensure the title string doesn't contain unsafe characters -
      # RSS feeds can be used maliciously and square brackets can
      # confuse the CMS someties

      title = title.dup
      title.gsub!('<', '&lt;')
      title.gsub!('>', '%gt;')
      title.gsub!('[', '&#91;')
      title.gsub!(']', '&#93;')

      # Markdown doesn't process text here anyway, possibly because
      # the HTML list markup seems to stop it from doing so. Don't
      # escape Markdown for now - the code below has been tested and
      # does work though, so it can be introduced later if need be.
      #
      #if (escape != 0 and @filter == 'Markdown')
      #  title.gsub!(/([`*_{}\[\]()#.!])/) { '\\' + $& }
      #end

      # Insert link HTML if a link is present, escaping it and
      # manually converting "~" characters to the "%7E" equivalent.

      if item.link.respond_to?(:empty?)
        link = item.link
      else
        link = item.link.href
      end

      unless (link.blank?)
        if (to_https != 0 && self.request.ssl?)
          uri = URI.parse(link)
          uri.scheme = 'https' if (uri.scheme == 'http')
          link = uri.to_s
        end

        link = URI.escape(link) if (escaped == 0)
        link.gsub!(/\~/, '%7E')
        out << "<a href=\"#{link}\">#{title}</a>"
      else
        out << "#{title}"
      end

      # Attempt to extract an item publication/modification date.

      time = nil

      if item.respond_to?(:updated)
        # Atom feeds
        time = item.updated.content
      elsif item.respond_to?(:pubDate)
        # Typo blogs, The Register
        time = item.pubDate
      elsif item.respond_to?(:modified)
        # RForum installations, generic
        time = item.modified
      elsif item.respond_to?(:dc_date)
        # SlashDot
        time = item.dc_date
      end

      # Add the date if found and if attributes say to do so, then
      # close the list item.

      out << time.strftime(' <small>(%d-%b-%Y)</small>') if (time.class == Time and dates != 0)
      out << "</li>\n"
    end

    # Close the list, handle Textile escaping if necessary and
    # return the final chunk of data.

    out << "</ul>\n"

    if (escape != 0 and @filter == 'Textile')
      out << '</notextile>'
    end

    out

  end # 'tag "news" do |tag|'
end
