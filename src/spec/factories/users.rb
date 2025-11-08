FactoryBot.define do
  factory :user do
    after(:create) do |user|
      create(:user_credential, user: user)
      create(:user_profile, user: user)
      create(:user_status, user: user)
    end

    trait :with_blogs do
      after(:create) do |user|
        create_list(:blog, 3, user: user)
      end
    end

    trait :suspended do
      after(:create) do |user|
        create(:user_status, user: user, status: :suspended)
      end
    end

    trait :deleted do
      after(:create) do |user|
        create(:user_status, user: user, status: :deleted)
      end
    end
  end
end
