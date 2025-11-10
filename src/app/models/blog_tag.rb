class BlogTag < ApplicationRecord
  belongs_to :blog
  belongs_to :tag

  validates :blog_id, presence: true
  validates :tag_id, presence: true
  validates :blog_id, uniqueness: { scope: :tag_id }

  scope :by_blog, ->(blog_id) { where(blog_id: blog_id) }
  scope :by_tag, ->(tag_id) { where(tag_id: tag_id) }
end
