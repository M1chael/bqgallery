#!/usr/bin/env ruby

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

require 'yaml'
require 'bot'
require 'sequel'

wd = File.expand_path(File.dirname(__FILE__))
config = YAML.load_file(wd + '/../assets/config.yml')
DB = Sequel.sqlite(File.join(wd, '../assets', config[:db]))

bot = Bot.new(token: config[:telegram_token], chat_id: config[:chat_id])

Telegram::Bot::Client.run(config[:telegram_token]) do |telegram|
  telegram.listen do |message|
    bot.callback(data: message.data, uid: message.from.id, mid: message.message.message_id, id: message.id)
  end
end
