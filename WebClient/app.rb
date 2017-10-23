require 'sinatra'
require 'sinatra/reloader'
require 'mysql2'
require 'chartkick'
require 'sinatra/activerecord'

set :database,  adapter: 'mysql2',
                host: ENV['POWDATA_HOST'],
                port: ENV['POWDATA_PORT'],
                username: ENV['POWDATA_USER'],
                password: ENV['POWDATA_PASS'],
                database: 'sonoff',
                pool: '10'

class Pow < ActiveRecord::Base
  self.table_name = 'pow'
  self.default_timezone = :local
end

def set_data_for_chart
  pow_data = {}
  @result.each do |row|
    pow_data[row['datetime']] = row.power
  end
  return pow_data
end

def set_chart_header
  params[:period] == 'l24h' ? 'in the last 24 hours' : "from #{params[:startTime]} to #{params[:endTime]}"
end

get '/' do
  @alarm_power = Pow.last.alarm_power
  @alarm_on = Pow.last.alarm_on
  params[:period] ||= 'l24h'
  if params[:period] == 'l24h'
    @result = Pow.where("datetime > '#{Time.now - (24 * 60 * 60)}'")
  elsif params[:period] == 'given'
    start_time = DateTime.strptime(params[:startTime], '%d.%m.%Y %H:%M')
    end_time = DateTime.strptime(params[:endTime], '%d.%m.%Y %H:%M')
    @result = Pow.where("datetime > '#{start_time}' AND datetime < '#{end_time}'")
  end
  @pow_data = set_data_for_chart
  @chart_header = set_chart_header
  erb :pow
end

post '/' do
  Pow.update(Pow.last.id, alarm_on: (params['alarmOn'] == 'on'),
                          alarm_power: params['alarmPower'])
  redirect '/'
end
