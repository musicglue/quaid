FactoryGirl.define do
  factory :list do
    name { Faker::Name.name }
  end
end