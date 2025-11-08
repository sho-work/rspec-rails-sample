class UserProfile < ApplicationRecord
  belongs_to :user

  validates :username, presence: true, length: { minimum: 1, maximum: 50 }
  validates :bio, length: { maximum: 500 }, allow_blank: true
  validates :avatar_url, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]), allow_blank: true }
  validates :website_url, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]), allow_blank: true }
  validates :birth_date, comparison: { less_than: Date.today }, allow_blank: true

  def age
    return nil unless birth_date

    today = Date.today
    age = today.year - birth_date.year
    age -= 1 if today < birth_date + age.years
    age
  end

  def formatted_bio
    bio.presence || "No bio provided"
  end

  def display_name
    username
  end
end
