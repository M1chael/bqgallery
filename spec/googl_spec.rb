require 'googl'
require 'spec_helper'

describe GooGL do

	let(:googl) { GooGL.new('key') } 

	describe '#short' do
		it 'returns shortened url' do
			expect(googl.short('http://test.com')).to eq('https://goo.gl/abs')
		end
	end

end
