require 'spec_helper'

describe TikiCrawler do

  describe 'crawl' do
    it 'crawles all packages' do
      Product.delete_all
      Versionlink.delete_all
      Product.count.should eq(0)
      TikiCrawler.crawl nil, true
      Product.count.should eq(1)
      product = Product.first
      expect( product.prod_key ).to eq('adodb/adodb')
      expect( product.versions.count > 0 ).to be_truthy
    end
  end

end
