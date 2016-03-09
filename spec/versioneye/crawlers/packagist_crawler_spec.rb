require 'spec_helper'

describe PackagistCrawler do

  describe 'crawle_package' do
    it "succeeds" do
      License.count.should == 0
      described_class.crawle_package 'doctrine/annotations'
      License.count.should > 1
    end
  end

  describe 'get_first_level_list' do
    it "returns the list" do
      list = described_class.get_first_level_list
      list.should_not be_nil
      list.should_not be_empty
      list.count.should > 1
    end
  end

  describe 'is_branch?' do
    it "returns false because no links" do
      product = ProductFactory.create_new
      product.prod_key = 'versioneye/naturalsorter'
      resp = PackagistCrawler.is_branch? product, '1.0.0'
      resp.should be_falsy
    end
    it "returns false because no links" do
      product = ProductFactory.create_new
      product.prod_key = 'versioneye/naturalsorter'
      product.save
      Versionlink.find_or_create_by(:language => product.language,
        :prod_key => product.prod_key, :name => "Source", :link => "http://heise.de" )
      resp = PackagistCrawler.is_branch? product, '1.0.0'
      resp.should be_falsy
    end
    it "returns true because version does not exist" do
      product = ProductFactory.create_new
      product.prod_key = 'versioneye/naturalsorter'
      product.save
      Versionlink.find_or_create_by(:language => product.language,
        :prod_key => product.prod_key, :name => "GitHub", :link => "https://github.com/versioneye/naturalsorter" )
      resp = PackagistCrawler.is_branch? product, '0.0.0'
      resp.should be_truthy
    end
    it "returns false because version exist" do
      product = ProductFactory.create_new
      product.prod_key = 'versioneye/naturalsorter'
      product.save
      Versionlink.find_or_create_by(:language => product.language,
        :prod_key => product.prod_key, :name => "GitHub", :link => "https://github.com/versioneye/naturalsorter" )
      resp = PackagistCrawler.is_branch? product, 'v1.0.0'
      resp.should be_falsey
    end
  end

  describe 'crawl cakephp' do
    it 'crawles cakephp and skips all branches' do
      Product.delete_all
      Versionlink.find_or_create_by(:language => "PHP",
        :prod_key => "cakephp/cakephp", :name => "GitHub", :link => "https://github.com/cakephp/cakephp" )
      Product.count.should eq(0)
      PackagistCrawler.crawle_package "cakephp/cakephp"
      Product.count.should eq(1)
      product = Product.first
      product.versions.count.should > 39
    end
  end

end
