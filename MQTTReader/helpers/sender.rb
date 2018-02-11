require 'nexmo'

# отправлятель сообщений
class Sender

	# создание канала для отправки сообщения и инициализация переменных
	def initialize(send_to:, send_from: 'POW')
		@client = Nexmo::Client.new(key: ENV['POW_SMS_KEY'], secret: ENV['POW_SMS_SECRET'])
		@send_to = send_to
		@send_from = send_from
	end

	# отправка собщения в созданный канал
	def send_message(message: 'Alarm!')
		response=@client.send_message(from: @send_from, to: @send_to, text: message)
		if response['messages'][0]['status'] == '0'
		  return {error_level: 0,
		  		  message: "Sent message #{response['messages'][0]['message-id']}"}
		else
		  return {error_level: 1,
		  		  message: "Error: #{response['messages'][0]['error-text']}"}
		end
	end 
end
