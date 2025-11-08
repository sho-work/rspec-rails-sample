class Tag < ApplicationRecord
  has_many :blog_tags, dependent: :destroy
  has_many :blogs, through: :blog_tags

  validates :name, presence: true, uniqueness: true, length: { minimum: 1, maximum: 50 }
  validates :slug, presence: true, uniqueness: true

  before_validation :generate_slug, if: -> { slug.blank? && name.present? }

  scope :popular, -> { joins(:blog_tags).group(:id).order('COUNT(blog_tags.id) DESC') }
  scope :recent, -> { order(created_at: :desc) }
  scope :by_name, -> { order(:name) }

  def blog_count
    blogs.count
  end

  def generate_slug
    self.slug = name.parameterize
  end

  def related_tags(limit: 5)
    Tag.joins(:blog_tags)
      .where(blog_tags: { blog_id: blog_ids })
      .where.not(id: id)
      .group(:id)
      .order('COUNT(blog_tags.id) DESC')
      .limit(limit)
  end

  class << self
    def search(query)
      where("name LIKE ? OR description LIKE ?", "%#{sanitize_sql_like(query)}%", "%#{sanitize_sql_like(query)}%")
    end
  end
end
