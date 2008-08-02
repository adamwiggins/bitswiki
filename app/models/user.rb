class User < ActiveRecord::Base
  validates_presence_of :name
  validates_uniqueness_of :name

  def self.find_or_create(name)
    u = User.find_by_name(name)
    return u if u

    u = User.new(:name => name)
    u.save
    return u
  end

  def key
    unless self.key?
      require 'md5'
      self[:key] = MD5.hexdigest((object_id + rand(255)).to_s)
      save
    end
    self[:key]
  end
end
