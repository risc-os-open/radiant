module Admin::NodeHelper
  def render_node(page, locals = {})
    @current_node = page
    page.extend MenuRenderer
    page.view = self
    if page.additional_menu_features?
      page.extend(*page.menu_renderer_modules)
    end
    locals.reverse_merge!(:level => 0, :simple => false).merge!(:page => page)
    render :partial => 'admin/pages/node', :locals =>  locals
  end

  def homepage
    @homepage ||= Page.find_by_parent_id(nil)
  end

  def show_all?
    controller.action_name == 'remove'
  end

  def expanded_rows
    unless @expanded_rows
      @expanded_rows = case
      when rows = cookies[:expanded_rows]
        rows.split(',').map { |x| Integer(x) rescue nil }.compact
      else
        []
      end

      if homepage and !@expanded_rows.include?(homepage.id)
        @expanded_rows << homepage.id
      end
    end
    @expanded_rows
  end

  def expanded
    show_all? || expanded_rows.include?(@current_node.id)
  end

  def padding_left(level)
    (level * 23) + 9
  end

  def children_class
    unless @current_node.children.empty?
      if expanded
        ' children_visible'
      else
        ' children_hidden'
      end
    else
      ' no_children'
    end
  end

  def virtual_class
    @current_node.virtual? ? ' virtual': ''
  end

  def expander(level)
    if @current_node.children.empty? || level == 0
      ''.html_safe()
    else
      image(
        expanded ? 'collapse' : 'expand',
        class:               'expander',
        alt:                 'Toggle children',
        'data-after-toggle': image_path(expanded ? 'admin/expand.png' : 'admin/collapse.png')
      )
    end
  end

  def icon
    icon_name = @current_node.virtual? ? 'virtual_page' : 'page'
    image(icon_name, class: 'icon')
  end

  def node_title
    tag.span(@current_node.title, class: 'title')
  end

  def page_type
    display_name = @current_node.class.display_name

    if display_name == 'Page'
      ''.html_safe()
    else
      tag.span(display_name, class: 'info')
    end
  end

  def spinner
    image(
      'spinner.gif',
      class: 'busy',
      id:    "busy_#{@current_node.id}",
      style: 'display: none;'
    )
  end
end
