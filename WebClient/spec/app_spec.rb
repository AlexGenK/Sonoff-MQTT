require File.expand_path '../spec_helper.rb', __FILE__

describe "WebClient" do
  before(:all) do
    Pow.new(alarm_power: "100").save
  end

  it "should allow accessing the home page" do
    get '/'
    expect(last_response).to be_ok
  end

end
