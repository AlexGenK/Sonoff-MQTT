require File.expand_path '../spec_helper.rb', __FILE__

FactoryBot.define do
  sequence :time do |n|
    Time.now-(n*3600)
  end

  factory :telemetry, class: Pow do
    factor { (100.0/(120+rand(20))).round(2) }
    datetime { generate(:time) }
    voltage { 210+rand(30) }
    current { (10.0/(15+rand(15))).round(3) }
    power { voltage*current*factor }
    alarm_power '100'
    alarm_on true
  end
end

describe 'WebClient' do
  before(:all) do
    create_list(:telemetry, 72)
  end

  it 'should allow accessing the home page' do
    get '/'
    expect(last_response).to be_ok
  end
end
