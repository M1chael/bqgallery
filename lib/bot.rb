require 'telegram/bot'

class Bot
	def initialize(options)
    options.each{ |key, value| instance_variable_set("@#{key}", value) }
    @markup = markup(0)
	end

  def send_image(image)
    text = "\xF0\x9F\x91\xA4 #{image.user}\n\xF0\x9F\x93\xB1 #{image.exif.model}\n\xF0\x9F\x94\x97 #{image.post}"
    Telegram::Bot::Client.run(@token) do |telegram| 
      @response = telegram.api.send_photo(chat_id: @chat_id, caption: text, reply_markup: @markup, 
        photo: Faraday::UploadIO.new(image.path, 'image/jpeg'))
    end
    DB[:images].where(link: image.link).update(rating: 0, 
      mid: @response['result']['message_id'], fid: @response['result']['photo'][-1]['file_id'])
  end

  def markup(likes)
    kb = [[Telegram::Bot::Types::InlineKeyboardButton.new(text: likes.to_s, callback_data: 'rating'), 
      Telegram::Bot::Types::InlineKeyboardButton.new(text: "✋️ Спасибо", callback_data: 'like')]]
    Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: kb)    
  end

  def callback(options)
    Telegram::Bot::Client.run(@token) do |telegram| 
      if options[:data] == 'like'
        if DB[:likes].where(mid: options[:mid], uid: options[:uid]).count == 0
          text = 'Ваш голос учтён'
          rating = DB[:images][mid: options[:mid]][:rating] + 1
          DB[:images].where(mid: options[:mid]).update(rating: rating)
          DB[:likes].insert(mid: options[:mid], uid: options[:uid])
          markup = markup(rating)
          telegram.api.edit_message_reply_markup(chat_id: @chat_id, message_id: options[:mid], reply_markup: markup)
        else
          text = 'Вы проголосовали ранее'
        end
        telegram.api.answer_callback_query(callback_query_id: options[:id], text: text)
      end
    end
  end
end
