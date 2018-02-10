require 'sinatra'
require 'chartkick'
require 'sinatra/activerecord'

configure :development do
  require 'sinatra/reloader'
end

# параметры подключения к БД для режима разработки и продакшена
configure :production, :development do
  require 'mysql2'
  set :database,  adapter: 'mysql2',
                  host: ENV['POW_DATA_HOST'],
                  port: ENV['POW_DATA_PORT'],
                  username: ENV['POW_DATA_USER'],
                  password: ENV['POW_DATA_PASS'],
                  database: 'sonoff',
                  pool: '10'
end

# параметры подключения к БД для режима тестирования
configure :test do
  require 'sqlite3'
  set :database, 'sqlite3:pow_test.db'
end

# класс - запись о параметрах энергопотребления
class Pow < ActiveRecord::Base
  self.table_name = 'pow'

  # выборка данных и их представление в пригодном для графика виде
  def self.select_data_for_chart(query)
    pow_data = {}
    where(query).each do |row|
      pow_data[row['datetime']] = row.period
    end
    return pow_data
  end
end

# установка заголовка таблицы
def set_chart_header
  params[:period] == 'l24h' ? 'in the last 24 hours' : "from #{params[:startTime]} to #{params[:endTime]}"
end

# парсинг текстового представления даты/времени и создание из него объекта DateTime
def convert_time(time)
  Time.strptime(time, '%d.%m.%Y %H:%M')
end

# вывод основного экрана и обновление параметров графика потребления электроэнергии
get '/' do
  @alarm_power = Pow.last.alarm_power
  @alarm_on = Pow.last.alarm_on?
  params[:period] ||= 'l24h'
  # вывод графика за последние 24 часа
  if params[:period] == 'l24h'
    @pow_data = Pow.select_data_for_chart("datetime > '#{Time.now - (24 * 60 * 60)}'")
  # или вывод графика за данный период времени
  elsif params[:period] == 'given'
    @pow_data = Pow.select_data_for_chart("datetime > '#{convert_time(params[:startTime])}'
                        AND datetime < '#{convert_time(params[:endTime])}'")
  end
  @chart_header = set_chart_header
  erb :pow
end

# обновление параметров сигнализации по превышению напряжения
post '/' do
  Pow.update(Pow.last.id, alarm_on: (params['alarmOn'] == 'on'),
                          alarm_power: params['alarmPower'])
  redirect '/'
end
