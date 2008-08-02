module PageHelper

  def show_errors
    if @page && !@page.errors.empty?
      content_tag(
        "div",
        content_tag("ul", @page.errors.full_messages.collect { |msg| content_tag("li", msg) }),
        :class => "errorExplanation"
      )
    end
  end

  def comparing?
    controller.action_name == "compare"
  end

  def editing?
    controller.action_name == "edit"
  end

  def show_revisions?
    params[:show_revisions]
  end

  def show_tags?
    params[:show_tags] || params[:show_edit_tags]
  end
  
  def show_edit_tags?
    params[:show_edit_tags]
  end

  def show_add_comment?
    params[:show_add_comment]
  end
end
