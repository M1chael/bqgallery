require 'nokogiri'
require 'uri'

class Parser
	attr_reader :images

	def initialize(options)
    @images = Array.new
    @uri = URI('http://4pda.ru/forum/index.php?showtopic=%{topic}&st=%{page}' % options)
    @page = get_content
    parse
	end

  def last_page?
    'http:' + @page.xpath('//*[@id="ipbwrapper"]/table[1]/tr/td[1]/div/span[7]/a/@href').text == @uri.to_s
  end

  def posts
    @page.xpath('//table[@class="ipbtable"]').count - 4
  end

  private

  def get_content
    http = Net::HTTP.new(@uri.host, 80)
    req = Net::HTTP::Get.new(@uri, {'User-Agent' => 'BQ gallery bot'})
    Nokogiri::HTML(http.request(req).body)
  end

  def parse
    xpath = '//*[contains(@href, "dl/")]'
    url = 'http://4pda.ru/forum/index.php?act=findpost&pid='
    @page.xpath(xpath).each{|data| @images << {link: 'http:' + data.xpath('@href').text, 
      post: url + data.xpath('ancestor::table/@data-post').text,
      user: data.xpath('ancestor::table/tr/td/div/span[@class="normalname"]/a').text} if data.xpath('@href').text.split('.')[-1] == 'jpg' }
  end
end
