require 'spec_helper'

describe NpmCrawler do

  describe 'get_first_level_list' do
    it "returns the list" do
      list = described_class.get_first_level_list
      expect( list ).to_not be_nil
      expect( list.count > 1 ).to be_truthy
    end
  end

  describe 'crawl' do
    it 'crawles cakephp and skips all branches' do
      Product.delete_all
      expect( License.count ).to eq(0)
      expect( Product.count ).to eq(0)
      NpmCrawler.crawl true, ["stack-mapper"]
      expect( Product.count ).to eq(1)
      product = Product.first
      expect( product.versions.count > 1 ).to be_truthy
      expect( product.dependencies.count > 1 ).to be_truthy
      expect( License.count > 1 ).to be_truthy
    end
  end

end
