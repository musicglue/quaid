FactoryGirl.define do
  factory :paranoid_project do
    name { Faker::Name.name }
  end
end