require 'acts_as_tree'

class Page < ApplicationRecord
  class MissingRootPageError < StandardError
    def initialize(message = 'Database missing root page'); super end
  end

  include UserActionObserverConcern

  self.inheritance_column = 'class_name'

  # Callbacks
  before_save :update_virtual, :update_status, :set_allowed_children_cache

  # Associations
  acts_as_tree order: 'virtual DESC, title ASC'

  has_many :parts, class_name: 'PagePart', dependent: :destroy
  accepts_nested_attributes_for :parts, allow_destroy: true

  has_many :fields, class_name: 'PageField', dependent: :destroy
  accepts_nested_attributes_for :fields, allow_destroy: true

  belongs_to :layout
  belongs_to :created_by, class_name: 'User'
  belongs_to :updated_by, class_name: 'User'

  # Validations
  validates_presence_of :title, :slug, :breadcrumb, :status_id

  validates_length_of :title, maximum: 255
  validates_length_of :slug, maximum: 100
  validates_length_of :breadcrumb, maximum: 160

  validates_format_of :slug, with: %r{\A([-_.A-Za-z0-9]*|/)\z}
  validates_uniqueness_of :slug, scope: :parent_id

  validate :valid_class_name

  def self.permitted_params
    [
      :lock_version,
      :parent_id,
      :title,
      :slug,
      :breadcrumb,
      :layout_id,
      :class_name,
      :status_id,
      :published_at,
      parts_attributes:  [:id] +  PagePart.permitted_params(),
      fields_attributes: [:id] + PageField.permitted_params(),
    ]
  end

  # Load all tags
  #
  include Radiant::Taggable

  Dir.glob(Rails.root.join(__FILE__, '..', 'tags/*')).to_a.sort_by do | filename |
    if filename.end_with?('standard_tags.rb')
      0
    elsif filename.end_with?('deprecated_tags.rb')
      1
    else
      2
    end
  end.each do | filename |
    require filename

    leaf_name  = File.basename(filename)[..-4] # (remove 'rb')
    new_module = "Tags::#{leaf_name.camelize}".constantize

    include new_module
  end

  include Annotatable

  annotate :description
  attr_accessor :session, :cookies, :request, :response, :pagination_parameters
  class_attribute :default_child
  self.default_child = self

  # def layout_with_inheritance
  #   unless layout_without_inheritance
  #     parent.layout if parent?
  #   else
  #     layout_without_inheritance
  #   end
  # end
  # alias_method_chain :layout, :inheritance

  def description
    self["description"]
  end

  def description=(value)
    self["description"] = value
  end

  def cache?
    true
  end

  def child_path(child)
    clean_path(path + '/' + child.slug)
  end
  alias_method :child_url, :child_path

  def part(name)
    if new_record? or parts.to_a.any?(&:new_record?)
      parts.to_a.find {|p| p.name == name.to_s }
    else
      parts.find_by_name name.to_s
    end
  end

  def has_part?(name)
    !part(name).nil?
  end

  def has_or_inherits_part?(name)
    has_part?(name) || inherits_part?(name)
  end

  def inherits_part?(name)
    !has_part?(name) && self.ancestors.any? { |page| page.has_part?(name) }
  end

  def field(name)
    if new_record? or fields.any?(&:new_record?)
      fields.detect { |f| f.name.downcase == name.to_s.downcase }
    else
      fields.find_by_name name.to_s
    end
  end

  def published?
    status == Status[:published]
  end

  def scheduled?
    status == Status[:scheduled]
  end

  def status
   Status.find(self.status_id)
  end

  def status=(value)
    self.status_id = value.id
  end

  def path
    if parent?
      parent.child_path(self)
    else
      clean_path(slug)
    end
  end
  alias_method :url, :path

  def process(session, cookies, request, response)
    self.session  = session   # (see attr_accessor earlier; tag blocks can access this)
    self.cookies  = cookies   #  "
    self.request  = request   #  "
    self.response = response  #  "

    return { body: render().html_safe(), status: response_code() }
  end

  def headers
    # Return a blank hash that child classes can override or merge
    {}
  end

  def response_code
    200
  end

  def render
    if layout
      parse_object(layout)
    else
      render_part(:body)
    end
  end

  def render_part(part_name)
    part = part(part_name)
    if part
      parse_object(part)
    else
      ''
    end
  end

  def render_snippet(snippet)
    parse_object(snippet)
  end

  def find_by_path(path, live = true, clean = true)
    return nil if virtual?
    path = clean_path(path) if clean
    my_path = self.path
    if (my_path == path) && (not live or published?)
      self
    elsif (path =~ /^#{Regexp.quote(my_path)}([^\/]*)/)
      slug_child = children.find_by_slug($1)
      if slug_child
        found = slug_child.find_by_url(path, live, clean) # TODO: set to find_by_path after deprecation
        return found if found
      end
      children.each do |child|
        found = child.find_by_url(path, live, clean) # TODO: set to find_by_path after deprecation
        return found if found
      end
      file_not_found_types = ([FileNotFoundPage] + FileNotFoundPage.descendants)
      file_not_found_names = file_not_found_types.collect { |x| x.name }
      condition = (['class_name = ?'] * file_not_found_names.length).join(' or ')
      condition = "status_id = #{Status[:published].id} and (#{condition})" if live
      children.where([condition] + file_not_found_names).first
    end
  end
  alias_method :find_by_url, :find_by_path

  def update_status
    self.published_at = Time.zone.now if published? && self.published_at == nil

    if self.published_at != nil && (published? || scheduled?)
      self[:status_id] = Status[:scheduled].id if self.published_at  > Time.zone.now
      self[:status_id] = Status[:published].id if self.published_at <= Time.zone.now
    end

    true
  end

  def to_xml(options={}, &block)
    super(options.reverse_merge(include: :parts), &block)
  end

  def default_child
    self.class.default_child
  end

  def allowed_children_lookup
    [default_child, *Page.descendants.sort_by(&:name)].uniq
  end

  def set_allowed_children_cache
    self.allowed_children_cache = allowed_children_lookup.collect(&:name).join(',')
  end

  def allowed_children_cache
    allowed_children_lookup.collect(&:name).join(',')
  end

  class << self

    def root
      find_by_parent_id(nil)
    end

    def find_by_path(path, live = true)
      raise MissingRootPageError unless root
      root.find_by_path(path, live)
    end
    def find_by_url(*args)
      Rails.logger.warn("`find_by_url' has been deprecated; use `find_by_path' instead.", caller)
      find_by_path(*args)
    end

    def date_column_names
      self.columns.collect{|c| c.name if c.sql_type =~ /(date|time)/}.compact
    end

    def display_name(string = nil)
      if string
        @display_name = string
      else
        @display_name ||= begin
          n = name.to_s.dup
          n.sub!(/^(.+?)Page$/, '\1')
          n.gsub!(/([A-Z])/, ' \1')
          n.strip
        end
      end
      @display_name = @display_name + " - not installed" if missing? && @display_name !~ /not installed/
      @display_name
    end

    def display_name=(string)
      display_name(string)
    end

    def new_with_defaults(config = Radiant::Configuration)
      page = new
      page.parts.concat default_page_parts(config)
      page.fields.concat default_page_fields(config)
      default_status = config['defaults.page.status']
      page.status = Status[default_status] if default_status
      page
    end

    def is_descendant_class_name?(class_name)
      (Page.descendants.map(&:to_s) + [nil, "", "Page"]).include?(class_name)
    end

    def descendant_class(class_name)
      raise ArgumentError.new("argument must be a valid descendant of Page") unless is_descendant_class_name?(class_name)
      if ["", nil, "Page"].include?(class_name)
        Page
      else
        class_name.constantize
      end
    end

    def missing?
      false
    end

    private

      def default_page_parts(config = Radiant::Configuration)
        default_parts = config['defaults.page.parts'].to_s.strip.split(/\s*,\s*/)
        default_parts.map do |name|
          PagePart.new(name: name, filter_id: config['defaults.page.filter'])
        end
      end

      def default_page_fields(config = Radiant::Configuration)
        default_fields = config['defaults.page.fields'].to_s.strip.split(/\s*,\s*/)
        default_fields.map do |name|
          PageField.new(name: name)
        end
      end
  end

  private

    def valid_class_name
      unless Page.is_descendant_class_name?(class_name)
        errors.add :class_name, "must be set to a valid descendant of Page"
      end
    end

    def attributes_protected_by_default
      super - [self.class.inheritance_column]
    end

    def update_virtual
      unless self.class == Page.descendant_class(class_name)
        self.virtual = Page.descendant_class(class_name).new.virtual?
      else
        self.virtual = virtual?
      end
      true
    end

    def clean_path(path)
      "/#{ path.to_s.strip }/".gsub(%r{//+}, '/')
    end
    alias_method :clean_url, :clean_path

    def parent?
      !parent.nil?
    end

    def lazy_initialize_parser_and_context
      unless @parser and @context
        @context = PageContext.new(self)
        @parser = Radius::Parser.new(@context, tag_prefix: 'r')
      end
      @parser
    end

    def parse(text)
      lazy_initialize_parser_and_context.parse(text)
    end

    def parse_object(object)
      text = object.content || ''
      text = parse(text)
      text = object.filter.filter(text) if object.respond_to? :filter_id
      text
    end

end
