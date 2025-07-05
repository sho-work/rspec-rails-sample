FactoryBot.define do
  factory :blog do
    sequence(:title) { |n| "Blog Title #{n}" }
    content { "This is a sample blog content." }
    published { false }

    trait :published do
      published { true }
    end

    trait :unpublished do
      published { false }
    end
  end
end
