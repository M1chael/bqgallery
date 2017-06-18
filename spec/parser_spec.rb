require 'parser'
require 'spec_helper'

describe Parser do

	let(:parser) { Parser.new(topic: 758535, page: 0) } 

	describe '#images' do
		it 'returns images information' do
			expect(parser.images).to eq(IMAGES)
		end
	end

  describe '#last_page?' do
    it 'returns TRUE for last page' do
      parser = Parser.new(topic: 758535, page: 15660)
      expect(parser.last_page?).to be true
    end

    it 'returns FALSE for non-last page' do
      expect(parser.last_page?).to be false
    end
  end

  describe '#psots' do
    it 'returns number of posts on the page' do
      parser = Parser.new(topic: 758535, page: 15660)
      expect(parser.posts).to eq(15)
    end
  end
end
