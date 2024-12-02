class Admin::PagesController < Admin::ResourceController
  before_action :initialize_meta_rows_and_buttons, :only => [:new, :edit, :create, :update]
  before_action :count_deleted_pages, :only => [:destroy]

  class PreviewStop < ActiveRecord::Rollback
    def message
      'Changes not saved!'
    end
  end

  declare_responses do |r|
    r.plural.js do
      @level = params[:level].to_i
      @template_name = 'index'
      self.models = Page.find(params[:page_id]).children.all
      render template: 'admin/pages/_children', formats: [:html], layout: false
    end
  end

  def index
    @homepage = Page.find_by_parent_id(nil)
    response_for :plural
  end

  def new
    @page = self.model = model_class.new_with_defaults(config)
    assign_page_attributes
    response_for :new
  end

  def preview
    Page.transaction do
      page_class  = Page.descendants.include?(model_class) ? model_class : Page
      safe_params = params.require(:page).permit(Page.permitted_params())

      if request.referer =~ %r{/admin/pages/(\d+)/edit}
        page = Page.find($1).becomes(page_class)
        page.update!(safe_params)
        page.published_at ||= Time.now
      else
        page = page_class.new(safe_params)
        page.published_at = page.updated_at = page.created_at = Time.now
        page.parent = Page.find($1) if request.referer =~ %r{/admin/pages/(\d+)/children/new}
      end

      page.pagination_parameters = pagination_parameters()

      result = page.process(self.session(), self.cookies(), self.request(), self.response())
      render(html: result[:body], status: result[:status])

      raise ActiveRecord::Rollback
    end
  end

  private
    def assign_page_attributes
      if params[:page_id].blank?
        self.model.slug = '/'
      end
      self.model.parent_id = params[:page_id]
      self.model.parts = [ PagePart.new(name: 'body') ]
    end

    def model_class
      if Page.descendants.any? { |d| d.to_s == params[:page_class] }
        params[:page_class].constantize
      elsif params[:page_id]
        Page.find(params[:page_id]).children
      else
        Page
      end
    end

    def count_deleted_pages
      @count = model.children.count + 1
    end

    def initialize_meta_rows_and_buttons
      @buttons_partials ||= []
      @meta ||= []
      @meta << {:field => "slug", :type => "text_field", :args => [{:class => 'textbox', :maxlength => 100}]}
      @meta << {:field => "breadcrumb", :type => "text_field", :args => [{:class => 'textbox', :maxlength => 160}]}
    end
end
