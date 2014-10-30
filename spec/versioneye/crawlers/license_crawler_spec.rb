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

    it "finds MIT" do
      License.count.should == 0
      product = ProductFactory.create_new
      LicenseCrawler.process_github_master('biola/action_links', product).should be_truthy
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

    it "finds LGPL-3" do
      License.count.should == 0
      product = ProductFactory.create_new
      LicenseCrawler.process_github_master('spox/actionpool', product).should be_truthy
      License.count.should == 1
      License.first.name.should eq('LGPL-3.0')
    end

    it "finds Apache License 2.0" do
      License.count.should == 0
      product = ProductFactory.create_new
      LicenseCrawler.process_github_master('openrain/action_mailer_tls', product).should be_truthy
      License.count.should == 1
      License.first.name.should eq('Apache License 2.0')
    end

    it "finds Apache License 2.0" do
      License.count.should == 0
      product = ProductFactory.create_new
      LicenseCrawler.process_github_master('nearinfinity/active_blur', product).should be_truthy
      License.count.should == 1
      License.first.name.should eq('Apache License 2.0')
    end

  end

end
