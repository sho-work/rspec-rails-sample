class Blog < ApplicationRecord
  belongs_to :user
  has_many :blog_tags, dependent: :destroy
  has_many :tags, through: :blog_tags

  validates :title, presence: true
  validates :content, presence: true
  validates :user_id, presence: true
  validates :view_count, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  scope :published, -> { where(published: true) }
  scope :unpublished, -> { where(published: false) }
  scope :by_user, ->(user_id) { where(user_id: user_id) }
  scope :by_tag, ->(tag_id) { joins(:blog_tags).where(blog_tags: { tag_id: tag_id }) }
  scope :popular, -> { where(published: true).order(view_count: :desc) }
  scope :recent, -> { order(created_at: :desc) }

  # @param [String] title
  # @return [Blog::ActiveRecord_Relation]
  def self.filter_by_title(title)
    # メソッドチェーンを継続するためにcurrent_scopeを返す
    # reference: https://github.com/rails/rails/blob/7b96382519b8bdd0156ab63c849728e38039293b/activerecord/lib/active_record/scoping.rb#L25-L27
    return current_scope if title.blank?

    sanitized_title = sanitize_sql_for_conditions(["title LIKE ?", "%#{title}%"])
    where(sanitized_title)
  end

  # @param [String] status
  # @return [Blog::ActiveRecord_Relation]
  def self.filter_by_status(status)
    case status
    when 'published'
      published
    when 'unpublished'
      unpublished
    else
      # メソッドチェーンを継続するためにcurrent_scopeを返す
      # reference: https://github.com/rails/rails/blob/7b96382519b8bdd0156ab63c849728e38039293b/activerecord/lib/active_record/scoping.rb#L25-L27
      current_scope
    end
  end

  def increment_view!
    increment!(:view_count)
  end

  def author_name
    user&.username || "Unknown"
  end

  def tag_list
    tags.pluck(:name).join(", ")
  end

  class << self
    def search_with_tags(query)
      joins(:tags)
        .where("blogs.title LIKE ? OR blogs.content LIKE ? OR tags.name LIKE ?",
               "%#{sanitize_sql_like(query)}%",
               "%#{sanitize_sql_like(query)}%",
               "%#{sanitize_sql_like(query)}%")
        .distinct
    end

    def trending(limit: 10)
      published
        .where("created_at > ?", 7.days.ago)
        .order(view_count: :desc)
        .limit(limit)
    end

    def filter_by_user_and_tags(user_id: nil, tag_ids: nil)
      scope = all
      scope = scope.by_user(user_id) if user_id.present?
      scope = scope.joins(:blog_tags).where(blog_tags: { tag_id: tag_ids }).distinct if tag_ids.present?
      scope
    end
  end
end
