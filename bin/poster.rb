#!/usr/bin/env ruby

require 'yaml'

wd = File.expand_path(File.dirname(__FILE__))
Dir["#{wd}/../lib/*.rb"].each {|file| require file }
config = YAML.load_file(wd + '/../assets/config.yml')
DB = Sequel.sqlite(File.join(wd, '../assets', config[:db]))
bot = Bot.new(token: config[:telegram_token], chat_id: config[:chat_id])
googl = GooGL.new(config[:google_api])

config[:sources].each do |source|
  if source[0] == :'4pda'
    cookies = File.join(wd, '../assets', source[1][:cookies])
    source[1][:topics].each do |topic|
      name = topic[0]
      parser = Parser.new(topic: topic[1][:id], page: topic[1][:page])
      parser.images.each do |image|
        image = Image.new(image, googl)
        if !image.saved?
          image.download(cookies)
          if image.exif&.make&.casecmp('BQ') == 0 && File.size(image.path).to_f / 2**20 < 10
            image.save
            bot.send_image(image)
            image.remove
          else
            image.remove
          end
        end
      end
      if !parser.last_page? && parser.posts == 21
        config[:sources][:'4pda'][:topics][name][:page] = config[:sources][:'4pda'][:topics][name][:page] + 20
        File.write(wd + '/../assets/config.yml', config.to_yaml)
      end
    end
  end
end
