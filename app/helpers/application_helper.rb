module ApplicationHelper

  def relative_time(from_time)
    from_time = from_time.to_time if from_time.respond_to?(:to_time)
    distance_in_minutes = (((Time.now - from_time).abs)/60).round

    case distance_in_minutes
      when 0..1          then (distance_in_minutes == 0) ? '< 1 min ago' : '1 min ago'
      when 2..45        then "#{distance_in_minutes} mins ago"
      when 46..90        then '1 hr ago'
      when 90..1049      then "#{(distance_in_minutes.to_f / 60.0).round} hrs ago"
      when 1050..2159    then "1 day ago"
      when 2160..8640    then "#{(distance_in_minutes / 1440.0).round} days ago"
      when 8641..10080  then '1 week ago'
      else
        from_time.strftime from_time.year == Time.now.year ? '%b %d' : '%b %d, %Y'
    end
  end

  def make_columns(list, options = {})
    options[:columns] ||= 5
    options[:min_rows] ||= 3
    
    per_column = (list.length.to_f / options[:columns]).ceil
    per_column = [ per_column, options[:min_rows] ].max
    per_column -= 1 if list.length % per_column == 1 && (list.length.to_f / per_column).ceil < options[:columns]
    columns = []
    x = 0
    while x < list.length
      columns << list[x..(x+(per_column-1))]
      x += per_column
    end
    columns.empty? ? [[]] : columns
  end

  def feed_url_options(item = nil)
    options = { :controller => 'feed' }
    options[:action] = item ? item.class.to_s.downcase : "recent"
    options[:name] = item.name if item
    options[:key] = @user.key if @user
    options
  end
  
  def recent_item_link(item, options = {})
    options[:title] = item.page.title
    if item.class == Revision
      options[:rev] = item.id
      options[:action] = "compare"
    else
      options[:anchor] = "comment_#{item.id}"
    end
    page_url(options)
  end

  def feed_icon(item = nil)
    link_to(image_tag("feed.png", :id => "feed_icon", :width => "16", :height => "16"), feed_url_options(item))
  end
  
  def link_for(item, options = {})
    if item.class == Page
      options[:title] = item.title
      page_url(options)
    elsif item.class == Tag
      options[:tag] = item.name
      tag_url(options)
    elsif item.class == Recent
      recent_url(options)
    else
      url_for(options)
    end
  end
  
  def indent_tags(list)
    hier = [ "" ]
    list.collect do |x|
      parents = x.name.split('.')[0..-2]
      while parents[0,hier.last.split('.').length].join('.') != hier.last && hier.pop; end
      hier << x.name
      [x, hier.length-2]
    end
  end
  
  def show_search?
    params[:show_search]
  end

  def group_by_page(list, options = {})
    options[:per_page] ||= 3
    pages = { }
    list.each { |i| (pages[i.page] ||= [ i.created_at ]) << i }
    pages = pages.collect { |page, items| [page, items] }
    pages = pages.sort { |a, b| b[1][0] <=> a[1][0] }.collect do |c|
      [ c[0], c[1][1, options[:per_page]] ]
    end
    options[:limit] ? pages[0, options[:limit]] : pages
  end

  def can_edit?
    return true if @user
    return WikiOptions[:allow_anonymous_write]
  end
end
