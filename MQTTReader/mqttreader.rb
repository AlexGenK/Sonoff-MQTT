require 'mqtt'
require 'mysql2'
require './helpers/sender'
require './helpers/colorizer'
require './helpers/electricalparams'

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
    puts '------MySQL-------'
    puts "#{topic}: #{message}"

    # получение текущих параметров электросети
    line_params = ElectricalParams.new(topic, message)

    # чтение последней записи из БД и создание новой записи с текущими данными
    # об энергопотреблении и продублированными данными о граничной мощности
    # из последней записи
    result = client.query('SELECT alarm_power, alarm_on
                           FROM sonoff.pow
                           ORDER BY id DESC LIMIT 1')

    client.query("INSERT INTO sonoff.pow
                (datetime, power, factor, voltage, current, period, alarm_power, alarm_on, elmeter_id)
                VALUES
                ('#{line_params.time}', #{line_params.power}, #{line_params.factor}, 
                  #{line_params.voltage}, #{line_params.current}, #{line_params.period},
                  #{result.first['alarm_power']}, #{result.first['alarm_on']},
                 '#{line_params.elmeter_id}')")

    # отправка сообщения пользователю о превышении граничной мощности
    if (result.first['alarm_on'] != 0) && (line_params.period > result.first['alarm_power'])
      sender_result = sender.send_message
      puts sender_result[:message].red
    end
  end
end
