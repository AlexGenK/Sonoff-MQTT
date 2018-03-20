require 'mqtt'
require 'json'
require 'mysql2'
require './helpers/sender'
require './helpers/colorizer'

# получение номера счетчика из топика
def get_elmeter_id(topic)
  %r{/(.+)/}.match(topic)[1]
end

# чтение параметров подкючения БД
client = Mysql2::Client.new(host: ENV['POW_DATA_HOST'],
                            username: ENV['POW_DATA_USER'],
                            password: ENV['POW_DATA_PASS'],
                            port: ENV['POW_DATA_PORT'])

# создание канала отправки сообщения
sender = Sender.new(send_to: ENV['POW_SMS_TEL'])

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
                (datetime, power, factor, voltage, current, period, alarm_power, alarm_on, elmeter_id)
                VALUES
                ('#{parsed_hash['Time']}', #{parsed_hash['ENERGY']['Power']},
                #{parsed_hash['ENERGY']['Factor']}, #{parsed_hash['ENERGY']['Voltage']},
                #{parsed_hash['ENERGY']['Current']}, #{parsed_hash['ENERGY']['Period']},
                #{result.first['alarm_power']}, #{result.first['alarm_on']},
                '#{get_elmeter_id(topic)}')")

    # отправка сообщения пользователю о превышении граничной мощности
    if (result.first['alarm_on'] != 0) && (parsed_hash['ENERGY']['Period'] > result.first['alarm_power'])
      sender_result = sender.send_message
      puts sender_result[:message].red
    end
  end
end
