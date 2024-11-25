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
#                   but for now I still want to keep this behavior very
#                   simple for its users. There is an RSS behavior which
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

# Uncomment this if you reference any of your controllers in activate
# require_dependency 'application_controller'

require 'rss'

class NewsTagExtension < Radiant::Extension
  version "2.0"
  description %{
This extension provides a 'news' tag which generates a parsed HTML summary
of an RSS feed.
}
  url "http://pond.org.uk/"

  def activate
    Page.send :include, NewsTag
  end
end
