class Filters::MarkdownFilter < ::Filters::TextFilter
  description_file File.dirname(__FILE__) + "/filter_descriptions/markdown.html"

  def filter(text)
    Commonmarker.to_html(text).html_safe()
  end
end
