require 'rubygems'
require 'bundler/setup'
require 'spork'
require 'guard/rspec'
require 'rspec'

Spork.prefork do
  require 'factory_girl'
  require 'database_cleaner'
  require 'faker'
  require 'mongoid'
  require 'quaid'
  Mongoid.load!(File.expand_path("../mongoid.yml", __FILE__), :test)

  RSpec.configure do |config|
    config.include FactoryGirl::Syntax::Methods

    config.before(:suite) do
      DatabaseCleaner.strategy = :truncation
      DatabaseCleaner.clean
    end

    config.after(:each) do
      DatabaseCleaner.clean
    end
  end

  Dir['./spec/support/**/*.rb'].each{ |file| require file }
end

Spork.each_run do
  require 'quaid'
  FactoryGirl.find_definitions
end










