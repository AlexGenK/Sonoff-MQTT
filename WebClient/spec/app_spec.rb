require File.expand_path '../spec_helper.rb', __FILE__

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

describe 'My WebClient' do
  before(:all) do
    create_list(:telemetry, 72)
  end

  before do
    visit '/'
  end

  context 'when wisit by default' do
    it 'allows accessing the home page' do
      expect(page.status_code).to be 200
    end
    it 'shows power consumption in the last 24 hours' do
      expect(page).to have_content 'Power consumption in the last 24 hours'
    end
    it 'sets the power alarm on' do
      expect(page).to have_field 'alarmOn', checked: true
    end
    it 'sets the power alarm to the 100W' do
      expect(page).to have_field 'inputAlarmPower', with: '100'
    end
  end

  context "when switch to the 'last 24 hours' mode" do
    it 'shows power consumption in the last 24 hours' do
      page.choose 'optionsPeriod1'
      page.click_button 'Refresh chart'
      expect(page).to have_content 'Power consumption in the last 24 hours'
    end
  end

  context "when switch to the 'a given period' mode" do
    let(:start_time) { (Time.now - (48 * 60 * 60)).strftime('%d.%m.%Y %H:%M') }
    let(:end_time) { Time.now.strftime('%d.%m.%Y %H:%M') }

    it 'shows power consumption a given period' do
      page.choose 'optionsPeriod2'
      fill_in 'startTime', with: start_time
      fill_in 'endTime', with: end_time
      page.click_button 'Refresh chart'
      expect(page).to have_content "Power consumption from #{start_time} to #{end_time}"
    end
  end
end
