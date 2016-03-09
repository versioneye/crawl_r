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

  describe 'get_known_packages' do
    it 'returns the list of existing npm packages from db' do
      Product.delete_all
      request = ProductFactory.create_for_npm 'request', '1.0.0'
      expect( request.save ).to be_truthy
      chai = ProductFactory.create_for_npm 'chai', '1.0.0'
      expect( chai.save ).to be_truthy
      expect( Product.count ).to eq(2)

      packages = NpmCrawler.get_known_packages
      expect( packages ).to_not be_empty
      expect( packages.first ).to eq('request')
      expect( packages.last ).to eq('chai')
    end
  end

end
