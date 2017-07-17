require 'spec_helper'

describe ChefCrawler do

  describe 'crawl' do
    it 'crawles cakephp and skips all branches' do
      Product.delete_all
      expect( Product.count ).to eq(0)
      expect( License.count ).to eq(0)

      VCR.use_cassette("chef/crawl") do
        ChefCrawler.crawl true, true

        expect( Product.count ).to eq(1)
        expect( License.count > 0 ).to be_truthy
      end

    end
  end

end
