require 'rack/test'
require 'rspec'
require 'factory_bot'
require 'database_cleaner'
require 'capybara/dsl'

ENV['RACK_ENV'] = 'test'

require File.expand_path '../../app.rb', __FILE__

# подключение RSpec в тесты
module RSpecMixin
  include Rack::Test::Methods
  def app
    Sinatra::Application
  end
end

RSpec.configure do |config|
  config.include RSpecMixin
  config.include FactoryBot::Syntax::Methods
  config.include Capybara::DSL

  config.before(:suite) do
    FactoryBot.find_definitions
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
    DatabaseCleaner.start
  end

  config.before do
    DatabaseCleaner.start
  end

  config.after do
    DatabaseCleaner.clean
  end

  config.after(:suite) do
    DatabaseCleaner.clean
  end
end

Capybara.app = Sinatra::Application
