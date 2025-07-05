class Blog < ApplicationRecord
  validates :title, presence: true
  validates :content, presence: true

  scope :published, -> { where(published: true) }
  scope :unpublished, -> { where(published: false) }

  def self.filter_by_title(title)
    return all if title.blank?
    sanitized_title = sanitize_sql_for_conditions(["title LIKE ?", "%#{title}%"])

    where(sanitized_title)
  end

  def self.filter_by_status(status)
    case status
    when 'published'
      published
    when 'unpublished'
      unpublished
    else
      all
    end
  end
end
