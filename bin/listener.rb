#!/usr/bin/env ruby

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

require 'yaml'
require 'bot'
require 'sequel'
require 'logger'

wd = File.expand_path(File.dirname(__FILE__))
config = YAML.load_file(wd + '/../assets/config.yml')
DB = Sequel.sqlite(File.join(wd, '../assets', config[:db]))
logger = Logger.new(wd + '/../' + config[:log], 'monthly')
bot = Bot.new(token: config[:telegram_token], chat_id: config[:chat_id])

begin
  Telegram::Bot::Client.run(config[:telegram_token], logger: logger) do |telegram|
    telegram.listen do |message|
      if message.respond_to?(:data)
        telegram.logger.info("data: #{message.data}, uid: #{message.from.id}, mid: #{message.message.message_id}, id: #{message.id}")
        bot.callback(data: message.data, uid: message.from.id, mid: message.message.message_id, id: message.id)
      end
    end
  end
rescue => error
  logger.fatal(error)
end
