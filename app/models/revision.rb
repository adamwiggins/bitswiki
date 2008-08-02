class Revision < ActiveRecord::Base
  belongs_to :page
  belongs_to :user
  has_many :comments

  # get the revision number as displayed on the page
  def rid
    return 1 if self.page.nil?

    revs = self.page.index_revisions
    n = 0
    until n >= revs.length || revs[n] == self
      n += 1
    end
    revs.length - n
  end

  def earliest?
    return true if self.page.nil?
    self.id == self.page.index_revisions.last.id
  end

  def latest?
    return true if self.page.nil?
    self.id == self.page.index_revisions.first.id
  end

  def only?
    latest? && earliest?
  end
end
