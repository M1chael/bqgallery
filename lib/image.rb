require 'net/http'
require 'exif'
require 'sequel'

class Image
  attr_reader :exif, :link, :post, :user, :path

  def initialize(image, googl)
    image.each{|var, value| instance_variable_set("@#{var}", value)}
    @path = File.expand_path('../..', __FILE__) + '/assets/tmp/' + File.basename(URI(@link).path)
    @post = googl.short(@post)
  end

  def saved?
    DB[:images].where(link: @link).count != 0
  end

  def download(cookies)
    `wget -U 'BQ Gallery bot' -x --load-cookies #{cookies} -O #{@path} #{@link}`
    begin
      @exif = Exif::Data.new(File.open(@path))
    rescue 
      @exif = nil
    end
  end

  def remove
    FileUtils.rm(@path)
  end

  def save
    DB[:images].insert(link: @link, post: @post, user: @user, model: @exif.model)
  end
end
