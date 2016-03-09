require 'spec_helper'

describe ZendframeworkCrawler do

  describe 'crawl' do
    it 'crawles all packages' do
      Product.delete_all
      Versionlink.delete_all
      Product.count.should eq(0)
      ZendframeworkCrawler.crawl nil, true
      Product.count.should eq(1)
      product = Product.first
      expect( product.prod_key ).to eq('zendframework/skeleton-application')
      expect( product.versions.count > 0 ).to be_truthy
    end
  end

end