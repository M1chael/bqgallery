require 'image'
require 'spec_helper'
require 'fileutils'

describe Image do

  let(:googl) { double }
	let(:image) { Image.new(IMAGES[0], googl) } 
  let(:path) { File.expand_path('../../', __FILE__) }

  before(:example) do
    allow(googl).to receive(:short).with(IMAGES[0][:post]).and_return('https://goo.gl/abc')
  end

	describe '#download' do
		it 'downloads file' do
      expect(image).to receive(:`).
        with("wget -U 'BQ Gallery bot' -x --load-cookies #{path}/assets/4pda.cookies -O #{path}/assets/tmp/%F75+%E7%E4%E3.jpg #{IMAGES[0][:link]}")
      image.download(path + '/assets/4pda.cookies')
		end
	end

  describe '#exif' do
    after(:example) do
      FileUtils.rm(path + '/assets/tmp/%F75+%E7%E4%E3.jpg')
    end

    it 'is nil for files without exif' do
      allow(image).to receive(:`) { FileUtils.cp(path + '/test/2017-03-21_17-35-17.png', path + '/assets/tmp/%F75+%E7%E4%E3.jpg') }
      image.download(path + '/assets/4pda.cookies')
      expect(image.exif).to be nil
    end

    it 'returns make' do
      allow(image).to receive(:`) { FileUtils.cp(path + '/test/IMG_20170610_115233193.jpg', path + '/assets/tmp/%F75+%E7%E4%E3.jpg') }
      image.download(path + '/assets/4pda.cookies')
      expect(image.exif.make).to eq('Motorola')
    end

    it 'returns model' do
      allow(image).to receive(:`) { FileUtils.cp(path + '/test/IMG_20170610_115233193.jpg', path + '/assets/tmp/%F75+%E7%E4%E3.jpg') }
      image.download(path + '/assets/4pda.cookies')
      expect(image.exif.model).to eq('XT1580')
    end
  end

  describe '#remove' do
    it 'removes file' do
      allow(image).to receive(:`) { FileUtils.cp(path + '/test/2017-03-21_17-35-17.png', path + '/assets/tmp/%F75+%E7%E4%E3.jpg') }
      image.download(path + '/assets/4pda.cookies')
      image.remove
      expect(File.exist?(path + '/assets/tmp/2017-03-21_17-35-17.png')).to be false
    end
  end

  describe '#save' do
    it 'should save info to DB' do
      DB[:images].delete
      allow(image).to receive(:`) { FileUtils.cp(path + '/test/IMG_20170610_115233193.jpg', path + '/assets/tmp/%F75+%E7%E4%E3.jpg') }
      image.download(path + '/assets/4pda.cookies')
      image.save
      data = [IMAGES[0].clone]
      data[0][:model] = 'XT1580'
      [:rating, :mid, :fid].each{ |field| data[0][field] = nil }
      data[0][:post] = 'https://goo.gl/abc'
      expect(DB[:images].all).to eq(data)
      FileUtils.rm(path + '/assets/tmp/%F75+%E7%E4%E3.jpg')
    end
  end

  describe '#saved?' do
    it 'returns false, if image not in the DB' do
      DB[:images].delete
      expect(image.saved?).to be false
    end

    it 'returns true, if image is in the DB' do
      DB[:images].delete
      DB[:images].insert(IMAGES[0])
      expect(image.saved?).to be true
    end
  end
end
