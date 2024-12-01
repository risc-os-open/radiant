# A page kind which does nothing except bypass any and all cacheing. The use
# case intended is for an inclusion of e.g. RSS feed data from a third party
# source, which could change at any time.
#
class NewsPage < Page
  def cache?
    false
  end
end
