class TagController < ApplicationController
  def index
    if params[:tag]
      @tag = Tag.find_or_new(params[:tag])
      render :action => "pages"
    else
      render :action => "tags"
    end
  end
end
