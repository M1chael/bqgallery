#!/usr/bin/env ruby

require 'yaml'

wd = File.expand_path(File.dirname(__FILE__))
Dir["#{wd}/../lib/*.rb"].each {|file| require file }
config = YAML.load_file(wd + '/../assets/config.yml')
DB = Sequel.sqlite(File.join(wd, '../assets', config[:db]))
cookies = File.join(wd, '../assets', config[:cookies])

parser = Parser.new(topic: config[:topic], page: config[:page])
bot = Bot.new(token: config[:telegram_token], chat_id: config[:chat_id])
googl = GooGL.new(config[:google_api])
parser.images.each do |image|
  image = Image.new(image, googl)
  image.download(cookies)
  if image.exif&.make&.casecmp('BQ') == 0
    image.save
    bot.send_image(image)
    image.remove
  else
    image.remove
  end
end

if !parser.last_page? && parser.posts >= 20
  config[:page] = config[:page] + 20
  File.write(wd + '/../assets/config.yml', config.to_yaml)
end
