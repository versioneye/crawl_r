require 'spec_helper'

describe CoreosCrawler do

  describe 'crawl' do
    it 'crawles core os' do
      Product.delete_all
      expect( License.count ).to eq(0)
      expect( Product.count ).to eq(0)
      CoreosCrawler.crawl
      expect( Product.count ).to eq(1)
      product = Product.first
      expect( product.versions.count > 1 ).to be_truthy
      expect( License.count > 0 ).to be_truthy
    end
  end

end
