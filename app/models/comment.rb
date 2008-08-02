class Comment < ActiveRecord::Base
  belongs_to :revision
  belongs_to :user

  def page
    revision.page
  end

  def content
    comment
  end
end
