class Recent
  def name
    "Recent Changes"
  end
  
  def recent_items(options)
    Page.recent_items(options)
  end
  
  def last_modified
    Page.last_modified
  end
end