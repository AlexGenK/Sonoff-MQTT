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

def data_for_chart(result)
  pow_data = {}
  result.each do |row|
    pow_data[row['datetime']] = row.power
  end
  return pow_data
end

def set_chart_header
  params[:period] == 'l24h' ? 'in the last 24 hours' : "from #{params[:startTime]} to #{params[:endTime]}"
end

def convert_time(time)
  DateTime.strptime(time, '%d.%m.%Y %H:%M')
end

get '/' do
  @alarm_power = Pow.last.alarm_power
  @alarm_on = Pow.last.alarm_on
  params[:period] ||= 'l24h'
  if params[:period] == 'l24h'
    result = Pow.where("datetime > '#{Time.now - (24 * 60 * 60)}'")
  elsif params[:period] == 'given'
    result = Pow.where("datetime > '#{convert_time(params[:startTime])}'
                        AND datetime < '#{convert_time(params[:endTime])}'")
  end
  @pow_data = data_for_chart(result)
  @chart_header = set_chart_header
  erb :pow
end

post '/' do
  Pow.update(Pow.last.id, alarm_on: (params['alarmOn'] == 'on'),
                          alarm_power: params['alarmPower'])
  redirect '/'
end
