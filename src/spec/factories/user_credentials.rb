FactoryBot.define do
  factory :user_credential do
    user
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "password123" }
    password_confirmation { "password123" }

    trait :locked do
      locked_until { 30.minutes.from_now }
      failed_login_attempts { 5 }
    end
  end
end
