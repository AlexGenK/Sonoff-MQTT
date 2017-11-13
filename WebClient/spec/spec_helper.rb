require 'rack/test'
require 'rspec'
require 'factory_bot'
require 'database_cleaner'
require 'capybara/dsl'

ENV['RACK_ENV'] = 'test'

require File.expand_path '../../app.rb', __FILE__

module RSpecMixin
  include Rack::Test::Methods
  def app() Sinatra::Application end
end

RSpec.configure do |config| 
  config.include RSpecMixin
  config.include FactoryBot::Syntax::Methods
  config.include Capybara::DSL

  config.before(:suite) do
    FactoryBot.find_definitions
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before(:each) do
    DatabaseCleaner.strategy = :transaction
  end
 
  config.before(:each, :js => true) do
    DatabaseCleaner.strategy = :truncation
  end
 
  config.before(:each) do
    DatabaseCleaner.start
  end
 
  config.after(:each) do
    DatabaseCleaner.clean
  end
end

Capybara.app = Sinatra::Application
