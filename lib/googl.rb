require 'google/apis/urlshortener_v1'

class GooGL
	def initialize(key)
    shortener = Google::Apis::UrlshortenerV1
    @service = shortener::UrlshortenerService.new
    @service.key = key
    @url = Google::Apis::UrlshortenerV1::Url.new
	end

  def short(url)
    @url.long_url = url
    @service.insert_url(@url).id
  end
end
