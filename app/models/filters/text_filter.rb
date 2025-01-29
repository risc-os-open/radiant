module Filters; end

class Filters::TextFilter
  include Simpleton
  include Annotatable

  annotate :filter_name, :description

  def filter(text, _options)
    text
  end

  class << self
    def inherited(subclass)
      subclass.filter_name = subclass.name.to_name(remove_prefix: 'Filters::', remove_suffix: 'Filter')
    end

    def filter(text, _options)
      instance.filter(text, _options)
    end

    def description_file(filename)
      text = File.read(filename) rescue ""
      self.description text
    end

    def descendants_names
      descendants.map { |s| s.filter_name }.sort
    end

    def find_descendant(filter_name)
      descendants.each do |s|
        return s if s.filter_name == filter_name
      end
      nil
    end
  end
end
