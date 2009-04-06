class FeedController < ApplicationController
  session :off 
  before_filter :since
  layout nil

  def page
    @feed = Page.find_by_title(params[:name])
    feed
  end

  def tag
    @feed = Tag.find_by_name(params[:name])
    feed
  end

  def recent
    @feed = Recent.new
    feed
  end

  protected

  def feed
    if @since && @feed.last_modified <= @since
      render :nothing => true, :status => 304 # not modified
      return false
    end
    headers["Content-Type"] = "application/rss+xml; charset=utf-8"
    render :action => "feed"
  end

  def since
    @since = Time.rfc2822(@request.env["HTTP_IF_MODIFIED_SINCE"]) rescue nil
  end
end
