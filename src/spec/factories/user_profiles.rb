FactoryBot.define do
  factory :user_profile do
    user
    sequence(:username) { |n| "username#{n}" }
    bio { Faker::Lorem.paragraph }
    avatar_url { "https://example.com/avatar.jpg" }
    website_url { "https://example.com" }
    birth_date { 25.years.ago.to_date }
  end
end
