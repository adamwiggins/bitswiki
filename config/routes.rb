ActionController::Routing::Routes.draw do |map|

  # ===== pages =====

    map.page_feed 'page/:name/:key/feed.xml', :controller => 'feed', :name => 'Contents', :action => 'page'
    map.page 'page/:title/:action/:rev/:rev2',
      :controller => 'page',
      :title => 'Contents',
      :action => 'show',
      :rev => nil,
      :rev2 => nil

  # ===== tags =====

    map.tag_feed 'tag/:name/:key/feed.xml', :controller => 'feed', :action => 'tag'
    map.tag 'tags/', :controller => 'tag'
    map.tag 'tag/:tag', :controller => 'tag'

  # ===== recent =====

    map.recent_feed 'recent/:key/feed.xml', :controller => 'feed', :action => 'recent'
    map.recent 'recent', :controller => 'recent'

  # ===== default =====

    map.connect '', :controller => 'page', :action => 'show', :title => 'Contents'
    map.connect ':controller/:action/:id'

end
