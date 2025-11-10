FactoryBot.define do
  factory :blog do
    user
    sequence(:title) { |n| "Blog Title #{n}" }
    content { Faker::Lorem.paragraphs(number: 3).join("\n") }
    published { false }
    view_count { 0 }

    trait :published do
      published { true }
    end

    trait :unpublished do
      published { false }
    end

    trait :with_tags do
      after(:create) do |blog|
        create_list(:blog_tag, 3, blog: blog)
      end
    end

    trait :popular do
      view_count { rand(100..1000) }
      published { true }
    end
  end
end
