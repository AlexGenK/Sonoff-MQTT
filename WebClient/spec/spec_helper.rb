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

# конфигурация DatabaseCleaner
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

# конфигурация Capybara
Capybara.app = Sinatra::Application
Capybara.ignore_hidden_elements = false

# конфигурация FactoryBot и определение фабрики
FactoryBot.define do
  sequence :time do |n|
    Time.now - (n * 3600)
  end

  factory :telemetry, class: Pow do
    factor { (100.0 / (120 + rand(20))).round(2) }
    datetime { generate(:time) }
    voltage { 210 + rand(30) }
    current { (10.0 / (15 + rand(15))).round(3) }
    power { voltage * current * factor }
    alarm_power '100'
    alarm_on true
  end
end
