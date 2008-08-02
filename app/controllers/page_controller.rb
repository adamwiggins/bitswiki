class PageController < ApplicationController
  include HTMLDiff

  before_filter :load_page, :except => :edit_preview

  def show
    redirect_to(:action => "edit", :title => @title) and return if @revision.new_record?
    @content = @revision.content.wikify if @revision.content
  end

  def popup
    show
    render :layout => "popup"
  end

  def edit
    @content = @revision.content.wikify unless @revision.new_record?
    render :action => "show"
  end

  def edit_preview
    @content = params[:edit_content].wikify if params[:edit_content]
  end

  def edit_cancel
    @content = @revision.content.wikify if @revision.content
  end

  Anonymous = 'anonymous'  

  def save
    redirect_to :action => "show" and return if params[:cancel]

    @user = User.find_or_create(session[:user_name]) if session[:user_name]
    return unless check_write_access

    if WikiOptions[:allow_anonymous_write]
      @user ||= User.find_or_create(params[:user][:name]) || Anonymous
    end

    session[:user_name] = @user.name unless @user.name == Anonymous

    page_saved = @page.update_attributes(params[:page])

    unless @revision.content == params[:edit_content]
      rev = { :content => params[:edit_content], :user_id => @user.id, :created_at => Time.now }

      if params[:minor] && !@page.new_record? && @revision.latest? && @revision.user_id == @user.id
        rev_saved = @revision.update_attributes(rev)
      else
        @revision = @page.revisions.build(rev)
        rev_saved = @revision.save
      end
    else
      rev_saved = true
    end

    if page_saved && rev_saved
      redirect_to :action => 'show', :title => @page.title, :rev => nil
    else
      render :action => 'edit'
    end
  end

  def compare_form
    redirect_to(:action => 'show', :show_revisions => 1) and return unless params[:compare] && params[:compare].length == 2

    compare = [ ]
    2.times { |x| compare << Revision.find_by_id(params[:compare][x].to_i) }
    compare = compare.compact.sort do |x, y|
      x.rid <=> y.rid
    end
    options = { :action => "compare" }
    options[:rev] = compare[1].id if compare[1]
    options[:rev2] = compare[0].id if compare[0]
    redirect_to options
  end

  def compare
    @rev_old = params[:rev2]
    unless @rev_old
      page = @page.index_revisions.find(:first, :conditions => "created_at < '#{@revision.created_at}'")
      @rev_old = page.id if page
    end
    redirect_to(:action => 'show', :title => @title, :rev => @rev) and return unless @rev_old

    @revision_old = @page.revisions.find(@rev_old)
    content_new = @revision.content.wikify
    content_old = @revision_old.content.wikify
    @content = diff(content_old, content_new)

    render :action => "show"
  end

  def save_tags
    return unless check_write_access

    if params[:save] && params[:edit_tags]
      @page.tag_with params[:edit_tags].split("\n").collect { |t| '"' + t.strip + '"' }.join(" ")
    end

    unless @page.errors.empty?
      flash.now[:error] = 'Tag names can only contain "." as a subtag separator.'
      show
      params[:show_edit_tags] = 1
      render :action => "show"
    else
      redirect_to :action => 'show'
    end
  end

  def add_comment
    if params[:save] && params[:comment] && !params[:comment].empty?
      Comment.new(:comment => params[:comment], :user_id => @user.id, :revision_id => @revision.id).save
    end
    redirect_to :action => "show"
  end

  def logout
    session[:user_name] = nil
    redirect_to '/'
  end

  private

  def load_page
    @title = params[:title]
    unless @page = Page.find(:first, :conditions => [ "title = ?", @title ])
      @page = Page.new(:title => @title)
    end
    @tags = @title == 'Contents' ? Tag.all_tags : (@page.new_record? ? [ ] : @page.tags_with_counts)

    @rev = params[:rev]
    @revision = @page.revisions.find_by_id @rev if @rev
    @revision ||= @page.revisions.find(:first)
    @revision ||= Revision.new
  end

  def check_write_access
    if !@user and (WikiOptions[:allow_anonymous_write] == false)
      redirect_to WikiOptions[:access_denied_url]
      return false
    end
    return true
  end
end
