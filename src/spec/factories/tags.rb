FactoryBot.define do
  factory :tag do
    sequence(:name) { |n| "Tag#{n}" }
    slug { name&.parameterize }
    description { Faker::Lorem.sentence }

    trait :with_blogs do
      after(:create) do |tag|
        create_list(:blog_tag, 3, tag: tag)
      end
    end
  end
end
