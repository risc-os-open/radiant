class Filters::TextileFilter < ::Filters::TextFilter
  description_file File.dirname(__FILE__) + "/filter_descriptions/textile.html"

  def filter(text, _options)
    RedCloth.new(text).to_html
  end
end
