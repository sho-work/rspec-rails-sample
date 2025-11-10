FactoryBot.define do
  factory :user_status do
    user
    status { :active }
    reason { "Initial status" }
    effective_at { Time.current }

    trait :suspended do
      status { :suspended }
      reason { "Account suspended" }
    end

    trait :deleted do
      status { :deleted }
      reason { "Account deleted" }
    end
  end
end
