require 'mqtt'
require 'json'
require 'mysql2'

# чтение параметров подкючения БД
client = Mysql2::Client.new(host: ENV['POW_DATA_HOST'],
                            username: ENV['POW_DATA_USER'],
                            password: ENV['POW_DATA_PASS'],
                            port: ENV['POW_DATA_PORT'])

# устанавливаем соединение с MQTT брокером
MQTT::Client.connect(ENV['POW_MQTT_HOST'], ENV['POW_MQTT_PORT'].to_i) do |c|
  # читаем сообщения от MQTT брокера
  c.get(ENV['POW_MQTT_TOPIC']) do |topic, message|
    puts '------------------'
    puts "#{topic}: #{message}"
    parsed_hash = JSON.parse(message)
    # чтение последней записи из БД и создание новой записи с текущими данными
    # об энергопотреблении и продублированными данными о граничной мощности
    # из последней записи
    result = client.query('SELECT alarm_power, alarm_on
                           FROM sonoff.pow
                           ORDER BY id DESC LIMIT 1')
    client.query("INSERT INTO sonoff.pow
                (datetime, power, factor, voltage, current, period, alarm_power, alarm_on)
                VALUES
                ('#{parsed_hash['Time']}', #{parsed_hash['Power']},
                #{parsed_hash['Factor']}, #{parsed_hash['Voltage']},
                #{parsed_hash['Current']}, #{parsed_hash['Period']},
                #{result.first['alarm_power']}, #{result.first['alarm_on']})")
  end
end
