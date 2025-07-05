class Blog < ApplicationRecord
  validates :title, presence: true
  validates :content, presence: true

  scope :published, -> { where(published: true) }
  scope :unpublished, -> { where(published: false) }

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
end
