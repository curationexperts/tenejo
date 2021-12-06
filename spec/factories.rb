# frozen_string_literal: true
FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "somepassword" }
    trait :admin do
      roles { [association(:role, name: 'admin')] }
    end
  end

  factory :role do
    name { "admin" }
  end
end
