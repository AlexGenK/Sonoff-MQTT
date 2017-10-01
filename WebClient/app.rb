require 'sinatra'
require 'sinatra/reloader'
require 'mysql2'
require 'chartkick'

configure do
	$client = Mysql2::Client.new(:host => ENV['POWDATA_HOST'], 
		    					 :username => ENV['POWDATA_USER'], 
		    					 :password => ENV['POWDATA_PASS'], 
		    					 :port => ENV['POWDATA_PORT'])
end

def setDataForChart
	pow_data = {}
	@result.each do |row|
		pow_data[row['datetime']] = row['power']
	end
	return pow_data
end

def setChartHeader
	params[:period] == 'l24h' ? 'in the last 24 hours' : "from #{params[:startTime]} to #{params[:endTime]}"
end

get '/' do
	params[:period] ||= 'l24h'
	if params[:period] == 'l24h'
		@result = $client.query("SELECT datetime, power FROM sonoff.pow WHERE datetime>'#{Time.now-(24*60*60)}'")
	elsif params[:period] == "given"
		startTime = DateTime.strptime(params[:startTime], '%d.%m.%Y %H:%M')
		endTime = DateTime.strptime(params[:endTime], '%d.%m.%Y %H:%M')
		@result = $client.query("SELECT datetime, power FROM sonoff.pow WHERE datetime>'#{startTime}' AND datetime<'#{endTime}'")
	end
	@pow_data = setDataForChart
	@chartHeader = setChartHeader
	erb :pow
end
