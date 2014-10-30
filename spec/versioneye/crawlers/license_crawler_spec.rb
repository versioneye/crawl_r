require 'spec_helper'
require 'vcr'
require 'webmock'



describe LicenseCrawler do

  describe 'process_github_master' do

    it "finds MIT" do
      License.count.should == 0
      product = ProductFactory.create_new
      LicenseCrawler.process_github_master('winton/a_b', product).should be_truthy
      License.count.should == 1
      License.first.name.should eq('MIT')
    end

    it "finds MIT" do
      License.count.should == 0
      product = ProductFactory.create_new
      LicenseCrawler.process_github_master('achirkunov/spatial_adapter', product).should be_truthy
      License.count.should == 1
      License.first.name.should eq('MIT')
    end

    it "finds GPL-3" do
      License.count.should == 0
      product = ProductFactory.create_new
      LicenseCrawler.process_github_master('livingsocial/abanalyzer', product).should be_truthy
      License.count.should == 1
      License.first.name.should eq('GPL-3.0')
    end

  end

end
