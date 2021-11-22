# frozen_string_literal: true
FactoryBot.define do
  factory :user do
    email { "user@example.com" }
    password { "somepassword" }
    password_confirmation { "somepassword" }
    trait :admin do
      roles { [association(:role, name: 'admin')] }
    end
  end

  factory :role do
    name { "admin" }
  end
end
