require File.expand_path '../spec_helper.rb', __FILE__

FactoryBot.define do
  factory :telemetry, class: Pow do
    alarm_power "10"
  end
end

describe "WebClient" do
  before(:all) do
    create(:telemetry)
  end

  it "should allow accessing the home page" do
    get '/'
    expect(last_response).to be_ok
  end

end
