class Tag < ActiveRecord::Base
  has_many :taggings
  validates_format_of :name, :with => /^([^.]+\.)*([^.]+)$/, :message => 'can only contain "." as a subtag separator'
  # TODO: created a has_many :subtags relationship and cleanup the queries below

  def count
    self[:count].to_i
  end
  
  def count=(value)
    self[:count] = value.to_i
  end

  def self.parse(list)
    tag_names = []

    # first, pull out the quoted tags
    list.gsub!(/\"(.*?)\"\s*/ ) { tag_names << $1; "" }

    # then, replace all commas with a space
    list.gsub!(/,/, " ")

    # then, get whatever's left
    tag_names.concat list.split(/\s/)

    # strip whitespace from the names
    tag_names = tag_names.map { |t| t.strip }

    # delete any blank tag names
    tag_names = tag_names.delete_if { |t| t.empty? }
    
    return tag_names
  end

  def tagged
    @tagged ||= Page.find_tagged_with(name).sort { |a, b| a.title <=> b.title }    
  end
  
  def subtagged
    unless @subtagged
      list = subtags.collect { |t| t.name }
      @subtagged = list.empty? ? [ ] : Page.find_tagged_with(list).uniq.sort { |a, b| a.title <=> b.title}
    end
    @subtagged
  end

  def on(taggable)
    taggings.create :taggable => taggable
  end
  
  def ==(comparison_object)
    super || name == comparison_object.to_s
  end
  
  def to_s
    name
  end

  def last_modified
    return nil unless name

    # this is hideous, but really fast
    @last_modified ||= Time.parse(connection.select_one(
      "SELECT max(revisions.created_at) as a, max(comments.created_at) as b
       FROM tags JOIN taggings ON (taggings.tag_id = tags.id)
       JOIN revisions ON (taggings.taggable_id = revisions.page_id)
       JOIN pages ON (revisions.page_id = pages.id)
       LEFT JOIN comments ON (comments.revision_id = revisions.id)
       WHERE tags.name = '#{name}' OR tags.name LIKE '#{name}.%'"
    ).values.compact.max)
  end
  
  def basename
    name.split('.').pop
  end
  
  def parent
    parts = name.split('.')
    parts.pop
    Tag.find_by_name(parts.join('.'))
  end
  
  def parents
    p = []
    parts = name.split('.')
    while parts.pop && parts.length > 0
      p << Tag.find_or_new(parts.join('.'))
    end
    p.compact.reverse
  end

  def subtags
    self.class.all_tags(:top => self.name)
  end

  def recent_items(options = {})
    options[:pages] = (tagged | subtagged).collect { |p| p.id }
    Page.recent_items(options)
  end

  def self.find_or_new(name)
    Tag.find_by_name(name) || Tag.new(:name => name)
  end
  
  def self.all_tags(options={})
    where = options[:top] && !options[:top].empty? ? "WHERE t1.name LIKE '#{options[:top]}.%'" : ""
    tags = Tag.find_by_sql "SELECT t1.*, count(DISTINCT taggable_id) AS count FROM tags AS t1
                            LEFT JOIN tags AS t2 ON (t2.name LIKE t1.name||'%')
                            JOIN taggings ON (taggings.tag_id = t2.id) #{where}
                            GROUP BY t1.id, t1.name ORDER BY t1.name"

    if options[:top_only]
      # throw out any with parents already in the list
      tags = tags.delete_if do |t|
        tags.any? { |a| /^#{a.name}\./ =~ t.name }
      end

      # collapse names
      tags.collect! do |t|
        if t.name['.']
          t.name = t.name.split('.').first
          t = Tag.new(t.attributes)
        end
        t
      end
      
      # sum duplicates
      counts = { }
      tags.each { |t| counts[t.name] ||= 0; counts[t.name] += t.count }
      tags = counts.collect do
        |name, count| Tag.new(:name => name, :count => count)
      end.sort { |a, b| a.name <=> b.name }
    end
      
    tags
  end
    
  def self.search(terms)
    return [ ] if terms.blank?

    to_clean = [ ]
    conditions = terms.split.collect { |t| to_clean << t; "name ILIKE '%' || ? || '%'" }.join(' AND ')
    where = sanitize_sql(to_clean.unshift(conditions))
    Tag.find_by_sql("SELECT tags.* FROM tags JOIN taggings ON (taggings.tag_id = tags.id) WHERE #{where} ORDER BY tags.name")
  end
  
end
