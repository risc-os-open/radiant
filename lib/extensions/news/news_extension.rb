# News page type
# ==============
#
# Defines a NewsPage page type. See also NewsTagExtension.
#
#
# History
# -------
#
# 2011-03-06 (ADH): Imported into Radiant 0.9.1 as an Extension.

class NewsExtension < Radiant::Extension
  version "2.0"
  description "Defines a NewsPage page type which bypasses the cache, useful if <r:news> is in use on the page."
  url "http://pond.org.uk/"

  def activate
    # Nothing to do; this Extension really only exists to stop 'rake' raising
    # complaints about it being missing. It's the "app/models/news_page.rb"
    # code that really matters.
  end
end
