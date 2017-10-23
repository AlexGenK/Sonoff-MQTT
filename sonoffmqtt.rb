require 'mqtt'
require 'json'
require 'mysql2'

client = Mysql2::Client.new(host: ENV['POWDATA_HOST'],
                            username: ENV['POWDATA_USER'],
                            password: ENV['POWDATA_PASS'],
                            port: ENV['POWDATA_PORT'])

MQTT::Client.connect(ENV['MQTT_HOST'], ENV['MQTT_PORT'].to_i) do |c|
  c.get(ENV['MQTT_TOP']) do |topic, message|
    puts '------------------'
    puts "#{topic}: #{message}"
    parsed_hash = JSON.parse(message)
    result = client.query('SELECT alarm_power, alarm_on
                           FROM sonoff.pow
                           ORDER BY idpow DESC LIMIT 1')
    client.query("INSERT INTO sonoff.pow
                (datetime, power, factor, voltage, current, alarm_power, alarm_on)
                VALUES
                ('#{parsed_hash['Time']}', #{parsed_hash['Power']},
                #{parsed_hash['Factor']}, #{parsed_hash['Voltage']},
                #{parsed_hash['Current']}, #{result.first['alarm_power']},
                #{result.first['alarm_on']})")
  end
end
