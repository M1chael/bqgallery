require 'bot'
require 'image'
require 'spec_helper'

describe Bot do

  {token: 'telegram_token', chat_id: 'chat_id', user: 'username', 
    post: 'http://goo.gl/abcd', path: '/local/path/to/image.jpg',
    link: 'http://4pda.ru/link/to/image.jpg'}.each{ |key, value| let(key) { value } }
  let(:bot) { Bot.new(token: token, chat_id: chat_id) }
  exif = Struct.new(:model)
  ulite = exif.new('Aquaris U Lite')
	let(:image) { instance_double('Image', link: link, post: post, user: user, exif: ulite, path: path) }
  let(:telegram) { double }
  let(:api) { double }

  before(:example) do
    allow(Telegram::Bot::Types::InlineKeyboardButton).to receive(:new).with(text: '0', callback_data: 'rating').and_return('rb')
    allow(Telegram::Bot::Types::InlineKeyboardButton).to receive(:new).with(text: "\xE2\x9D\xA4", callback_data: 'like').and_return('lb')
    allow(Telegram::Bot::Types::InlineKeyboardMarkup).to receive(:new).with(inline_keyboard: [['rb', 'lb']]).and_return('markup')
  end

	describe '#send_image' do
    before(:example) do
      allow(telegram).to receive(:api).and_return(api)
      allow(api).to receive(:send_photo).and_return(SF_RESPONSE)
      allow(Faraday::UploadIO).to  receive(:new).with(image.path, 'image/jpeg').and_return('image')
      allow(Telegram::Bot::Client).to receive(:run).with(token).and_yield(telegram)
    end

    it 'sends image to channel' do
      caption = "\xF0\x9F\x91\xA4 #{user}\n\xF0\x9F\x93\xB1 #{ulite.model}\n\xF0\x9F\x94\x97 #{post}"
			expect(Telegram::Bot::Client).to receive(:run).with(token).and_yield(telegram)
      expect(telegram).to receive(:api)
      expect(api).to receive(:send_photo).with(chat_id: chat_id, caption: caption, reply_markup: 'markup', photo: 'image')
      bot.send_image(image)
		end

    it 'updates database' do
      DB[:images].delete
      DB[:images].insert(link: 'otherlink', post: 'otherpost', user: 'otheruser', model: 'othermodel')
      DB[:images].insert(link: link, post: post, user: user, model: image.exif.model)
      data = DB[:images].all
      data[1][:rating] = 0
      data[1][:mid] = 4
      data[1][:fid] = 'AgADAgADBKgxG3KL8El6Bq0oCT1jmEM8tw0ABNP2P8ZqDNbt1GYEAAEC'
      bot.send_image(image)
      expect(DB[:images].all).to eq(data)
    end
  end

  describe '#callback' do
    let(:message) { double }

    before(:example) do
      msg = Struct.new(:message_id)
      @id = 100
      @msg_id = msg.new(11)
      from = Struct.new(:id)
      @from_id = from.new(13)
      @data = 'like'
      @markup10 = 'markup10'
      allow(message).to receive(:data).and_return(@data)
      allow(message).to receive(:id).and_return(@id)
      allow(message).to receive(:message).and_return(@msg_id)
      allow(message).to receive(:from).and_return(@from_id)
      allow(telegram).to receive(:listen).and_return(message)
      allow(telegram).to receive(:api).and_return(api)
      allow(api).to receive(:answer_callback_query)
      allow(api).to receive(:edit_message_reply_markup)
      allow(Telegram::Bot::Client).to receive(:run).with(token).and_yield(telegram)
      allow(Telegram::Bot::Types::InlineKeyboardButton).to receive(:new).with(text: '10', callback_data: 'rating').and_return('rb10')
      allow(Telegram::Bot::Types::InlineKeyboardButton).to receive(:new).with(text: '1', callback_data: 'rating').and_return('rb1')
      allow(Telegram::Bot::Types::InlineKeyboardMarkup).to receive(:new).with(inline_keyboard: [['rb10', 'lb']]).and_return(@markup10)
      allow(Telegram::Bot::Types::InlineKeyboardMarkup).to receive(:new).with(inline_keyboard: [['rb1', 'lb']]).and_return('markup1')
    end

    it 'shows ok-alert for first time vote' do
      DB[:images].delete
      DB[:images].insert(mid: @msg_id.message_id, rating: 0)
      expect(api).to receive(:answer_callback_query).with(callback_query_id: @id, text: 'Ваш голос учтён')
      bot.callback(data: @data, uid: @from_id.id, mid: @msg_id.message_id, id: @id)
    end

    it 'shows no-vote-alert for re-vote' do
      DB[:images].delete
      DB[:likes].delete
      DB[:images].insert(mid: @msg_id.message_id, rating: 0)
      DB[:likes].insert(mid: @msg_id.message_id, uid: @from_id.id)
      expect(api).to receive(:answer_callback_query).with(callback_query_id: @id, text: 'Вы проголосовали ранее')
      bot.callback(data: @data, uid: @from_id.id, mid: @msg_id.message_id, id: @id)
    end

    it 'updates rating on the button after voting' do
      DB[:images].delete
      DB[:images].insert(mid: @msg_id.message_id, rating: 9)
      expect(api).to receive(:edit_message_reply_markup).with(chat_id: chat_id, 
        message_id: @msg_id.message_id, reply_markup: @markup10)
      bot.callback(data: @data, uid: @from_id.id, mid: @msg_id.message_id, id: @id)
    end

    it 'updates rating in the DB after voting' do
      DB[:images].delete
      DB[:images].insert(mid: @msg_id.message_id, rating: 9)
      bot.callback(data: @data, uid: @from_id.id, mid: @msg_id.message_id, id: @id)
      expect(DB[:images][mid: @msg_id.message_id][:rating]).to eq(10)
    end

    it 'writes likes info to DB' do
      DB[:images].delete
      DB[:likes].delete
      DB[:images].insert(mid: @msg_id.message_id, rating: 9)
      bot.callback(data: @data, uid: @from_id.id, mid: @msg_id.message_id, id: @id)
      expect(DB[:likes].all).to eq([mid: @msg_id.message_id, uid: @from_id.id])
    end
  end
end
