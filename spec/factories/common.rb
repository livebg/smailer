FactoryGirl.define do
  sequence(:name)  { |n| "Name-#{n}" }
  sequence(:email) { |n| "user#{n}@example.com" }
end
