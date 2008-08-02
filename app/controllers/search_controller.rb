class SearchController < ApplicationController
  before_filter :show_search

  def index
    @terms = params[:search]
    if request.post? && @terms.blank?
      flash.now[:notice] = "No search terms given."
    end
    @tags = Tag.search(@terms) || [ ]
    @page_items = Page.search(@terms) || [ ]
  end

  protected

  def show_search
    params[:show_search] = 1
  end
end
