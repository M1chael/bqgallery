$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

require 'webmock/rspec'
require 'sequel'

DB = Sequel.sqlite(File.expand_path('../../assets/gallery.db', __FILE__))

IMAGES = [
  {link: 'http://4pda.ru/forum/dl/post/8404989/%F75+%E7%E4%E3.jpg', 
    post: 'http://4pda.ru/forum/index.php?act=findpost&pid=51313499', user: 'Marko Bruni'},
  {link: 'http://4pda.ru/forum/dl/post/10488623/IMG_20170610_205758.jpg', 
    post: 'http://4pda.ru/forum/index.php?act=findpost&pid=51336609', user: 'Uzmilk'}
]

SF_RESPONSE = {"ok"=>true, "result"=>{"message_id"=>4, "chat"=>{"id"=>-1001114079459, "title"=>"BQGallery", "username"=>"bqgallery", "type"=>"channel"}, "date"=>1497279453, "photo"=>[{"file_id"=>"AgADAgADBKgxG3KL8El6Bq0oCT1jmEM8tw0ABCIx50j18G0f0GYEAAEC", "file_size"=>1095, "width"=>90, "height"=>51}, {"file_id"=>"AgADAgADBKgxG3KL8El6Bq0oCT1jmEM8tw0ABNbQmUd62upB0WYEAAEC", "file_size"=>16240, "width"=>320, "height"=>180}, {"file_id"=>"AgADAgADBKgxG3KL8El6Bq0oCT1jmEM8tw0ABNwlQBsw_UNL02YEAAEC", "file_size"=>82541, "width"=>800, "height"=>450}, {"file_id"=>"AgADAgADBKgxG3KL8El6Bq0oCT1jmEM8tw0ABORcUhAwLWVD0mYEAAEC", "file_size"=>197508, "width"=>1280, "height"=>720}, {"file_id"=>"AgADAgADBKgxG3KL8El6Bq0oCT1jmEM8tw0ABNP2P8ZqDNbt1GYEAAEC", "file_size"=>724736, "width"=>2560, "height"=>1440}]}}

WebMock.disable_net_connect!(allow_localhost: true)

RSpec.configure do |c|
  c.before(:each) do
    stub_request(:get, 'http://4pda.ru/forum/index.php?showtopic=758535&st=0').
      with(:headers => {'User-Agent'=>'BQ gallery bot'}).
      to_return(File.read('test/html/0.html'))
    stub_request(:get, 'http://4pda.ru/forum/index.php?showtopic=758535&st=15660').
      with(:headers => {'User-Agent'=>'BQ gallery bot'}).
      to_return(File.read('test/html/15660.html'))
    stub_request(:post, "https://www.googleapis.com/urlshortener/v1/url?key=key").
       with(:body => '{"longUrl":"http://test.com"}').
         to_return(File.read('test/html/goo.gl.html'))
  end
  c.around(:each) do |example|
    DB.transaction(:rollback=>:always, :auto_savepoint=>true) { example.run }
  end
end
