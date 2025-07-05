class Blog < ApplicationRecord
  validates :title, presence: true
  validates :content, presence: true

  scope :published, -> { where(published: true) }
  scope :unpublished, -> { where(published: false) }

  def self.search(query)
    return all if query.blank?

    where("title LIKE :query OR content LIKE :query", query: "%#{query}%")
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
