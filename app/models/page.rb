class Page < ActiveRecord::Base
  has_many :index_revisions, :class_name => "Revision", :order => "created_at DESC", :select => 'id, created_at', :include => :user
  has_many :revisions, :dependent => :destroy, :order => "created_at DESC", :include => :user
  has_many :comments, :through => :revisions, :order => "comments.created_at DESC", :include => :user
  acts_as_taggable

  validates_uniqueness_of :title, :message => "is already in use by another page"
  validates_presence_of :title, :message => "can't be blank"

  def name; title end

  def tags_edit
    self.tags.collect { |t| t.name }.join("\n")
  end

  def tags_with_counts
    subquery = "(SELECT COUNT(*) FROM taggings WHERE taggings.tag_id = tags.id)"
    Tag.find_by_sql "SELECT tags.*, #{subquery} AS count FROM taggings JOIN tags ON tag_id = tags.id WHERE taggable_id = #{self.id} GROUP BY tags.id, tags.name ORDER BY tags.name"
  end

  def last_modified
    @last_modified ||= self.class.last_modified(self.id)
  end

  def self.last_modified(id = nil)
    options = { :order => "revisions.created_at DESC" }
    options[:conditions] = "page_id = #{id}" if id
    rev = Revision.find(:first, options).created_at rescue nil
    options[:include] = :revision
    options[:order] = "comments.created_at DESC"
    com = Comment.find(:first, options).created_at rescue nil
    return com && (!rev || com > rev) ? com : rev
  end
  
  def recent_items(options = {})
    options[:limit] ||= 10
    options[:pages] = [self.id]
    self.class.recent_items(options)
  end

  def self.recent_items(options = {})
    options[:limit] ||= 100
    where = [ ]
    if options[:since]
      time = options[:since].strftime('%Y-%m-%d %H:%M:%S')
      where << "(revisions.created_at >= '#{time}' OR comments.created_at >= '#{time}')"
    end
    where << "(pages.id IN (#{options[:pages].join(',')}))" if options[:pages]
    where = where.join(' AND ')
    where = "WHERE #{where}" unless where.empty?
    which = (connection.select_all(
      "SELECT revisions.id as rev, revisions.created_at, comments.id as comm, comments.created_at,
       (CASE WHEN comments.created_at IS NULL THEN '2000-01-01 00:00:00' ELSE comments.created_at END) as c2 FROM pages
       JOIN revisions ON (pages.id = revisions.page_id)
       LEFT JOIN comments ON (comments.revision_id = revisions.id) #{where}
       ORDER BY c2 DESC, revisions.created_at DESC LIMIT #{options[:limit]}"
    ))
    
    rev_ids, comm_ids = [ ], [ ]
    which.each do |e|
      if e['comm']
        comm_ids << e['comm']
      else
        rev_ids << e['rev']
      end
    end
    
    r = Revision.find(rev_ids, :include => [ :page, :user ])
    c = Comment.find(comm_ids, :include => [ { :revision => :page }, :user ])
    coallesce(r, c)
  end

  def self.exists?(arg)
    if arg.is_a?(String)
      @existing_pages ||= Page.connection.select_values("SELECT DISTINCT title FROM pages")
      return @existing_pages.include?(arg)
    end
    super
  end
  
  def self.search(terms)
    return [ ] if terms.blank?
    
    to_clean = [ ]
    conditions = terms.split.collect { |t| to_clean << t; "content ILIKE '%' || ? || '%'" }.join(' AND ')
    r = Revision.find(:all, :conditions => to_clean.unshift(conditions), :include => [ :page, :user ], :group => "page_id")

    to_clean = [ ]
    conditions = terms.split.collect { |t| to_clean << t; "comment ILIKE '%' || ? || '%'" }.join(' AND ')
    c = Comment.find(:all, :conditions => to_clean.unshift(conditions), :include => [ { :revision => :page }, :user ])

    coallesce(r, c)
  end
  
  protected
  
  def self.coallesce(r, c)
    (r | c).sort do |a, b|
      b.created_at <=> a.created_at
    end
  end
end
