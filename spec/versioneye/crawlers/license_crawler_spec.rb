require 'spec_helper'
require 'vcr'
require 'webmock'



describe LicenseCrawler do

  describe 'process_github_master' do

    it "finds MIT" do
      License.count.should == 0
      product = ProductFactory.create_new
      LicenseCrawler.process_github_master('geta6/gauntlet', product).should be_truthy
      License.count.should == 1
      License.first.name.should eq('MIT')
    end

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
      LicenseCrawler.process_github_master('ryanzec/utilities', product).should be_truthy
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

    it "finds MIT" do
      License.count.should == 0
      product = ProductFactory.create_new
      LicenseCrawler.process_github_master('comster/house', product).should be_truthy
      License.count.should == 1
      License.first.name.should eq('MIT')
    end

    it "finds MIT" do
      License.count.should == 0
      product = ProductFactory.create_new
      LicenseCrawler.process_github_master('jschairb/doughboy', product).should be_truthy
      License.count.should == 1
      License.first.name.should eq('MIT')
    end

    it "finds MIT" do
      License.count.should == 0
      product = ProductFactory.create_new
      LicenseCrawler.process_github_master('cujojs/msgs', product).should be_truthy
      License.count.should == 1
      License.first.name.should eq('MIT')
    end

    it "finds MIT" do
      License.count.should == 0
      product = ProductFactory.create_new
      LicenseCrawler.process_github_master('angular-ui/ui-select2', product).should be_truthy
      License.count.should == 1
      License.first.name.should eq('MIT')
    end

    it "finds The Unlicense" do
      License.count.should == 0
      product = ProductFactory.create_new
      LicenseCrawler.process_github_master('EvanHahn/ScriptInclude', product).should be_truthy
      License.count.should == 1
      License.first.name.should eq('The Unlicense')
    end

    it "finds DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE" do
      License.count.should == 0
      product = ProductFactory.create_new
      LicenseCrawler.process_github_master('tinogomes/mezu', product).should be_truthy
      License.count.should == 1
      License.first.name.should eq('DWTFYWTP License')
    end

    it "finds GPL-3" do
      License.count.should == 0
      product = ProductFactory.create_new
      LicenseCrawler.process_github_master('livingsocial/abanalyzer', product).should be_truthy
      License.count.should == 1
      License.first.name.should eq('GPL-3.0')
    end

    it "finds GPL-2" do
      License.count.should == 0
      product = ProductFactory.create_new
      LicenseCrawler.process_github_master('benjaminoakes/airplane_mode', product).should be_truthy
      License.count.should == 1
      License.first.name.should eq('GPL-2.0')
    end

    it "finds AGPL-3" do
      License.count.should == 0
      product = ProductFactory.create_new
      LicenseCrawler.process_github_master('brighterplanet/fuel_purchase', product).should be_truthy
      License.count.should == 1
      License.first.name.should eq('AGPL-3.0')
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

    it "finds Apache License 2.0" do
      License.count.should == 0
      product = ProductFactory.create_new
      LicenseCrawler.process_github_master('csswizardry/csscv', product).should be_truthy
      License.count.should == 1
      License.first.name.should eq('Apache License 2.0')
    end

    it "finds Mozilla Public License Version 2.0" do
      License.count.should == 0
      product = ProductFactory.create_new
      LicenseCrawler.process_github_master('ronalchn/ajax_pagination', product).should be_truthy
      License.count.should == 1
      License.first.name.should eq('MPL-2.0')
    end
    it "finds Mozilla Public License Version 2.0" do
      License.count.should == 0
      product = ProductFactory.create_new
      LicenseCrawler.process_github_master('rosace/rosace', product).should be_truthy
      License.count.should == 1
      License.first.name.should eq('MPL-2.0')
    end
    it "finds Mozilla Public License Version 2.0" do
      License.count.should == 0
      product = ProductFactory.create_new
      LicenseCrawler.process_github_master('mozilla/fireplace', product).should be_truthy
      License.count.should == 1
      License.first.name.should eq('MPL-2.0')
    end
    it "finds Mozilla Public License Version 2.0" do
      License.count.should == 0
      product = ProductFactory.create_new
      LicenseCrawler.process_github_master('mozilla/makedrive', product).should be_truthy
      License.count.should == 1
      License.first.name.should eq('MPL-2.0')
    end

    it "finds New BSD" do
      License.count.should == 0
      product = ProductFactory.create_new
      LicenseCrawler.process_github_master('paneq/active_reload', product).should be_truthy
      License.count.should == 1
      License.first.name.should eq('New BSD')
    end

    it "finds New BSD" do
      License.count.should == 0
      product = ProductFactory.create_new
      LicenseCrawler.process_github_master('MrRuru/spree_coupon_preview', product).should be_truthy
      License.count.should == 1
      License.first.name.should eq('New BSD')
    end

    it "finds New BSD" do
      License.count.should == 0
      product = ProductFactory.create_new
      LicenseCrawler.process_github_master('johndavid400/spree_news', product).should be_truthy
      License.count.should == 1
      License.first.name.should eq('New BSD')
    end

    it "finds New BSD" do
      License.count.should == 0
      product = ProductFactory.create_new
      LicenseCrawler.process_github_master('citrus/spree_essential_cms', product).should be_truthy
      License.count.should == 1
      License.first.name.should eq('New BSD')
    end

    it "finds New BSD" do
      License.count.should == 0
      product = ProductFactory.create_new
      LicenseCrawler.process_github_master('adzap/ar_mailer', product).should be_truthy
      License.count.should == 1
      License.first.name.should eq('New BSD')
    end

    it "finds New BSD" do
      License.count.should == 0
      product = ProductFactory.create_new
      LicenseCrawler.process_github_master('ecomfe/zrender', product).should be_truthy
      License.count.should == 1
      License.first.name.should eq('New BSD')
    end

    it "finds BSD 2-clause" do
      License.count.should == 0
      product = ProductFactory.create_new
      LicenseCrawler.process_github_master('jimwise/ambit', product).should be_truthy
      License.count.should == 1
      License.first.name.should eq('BSD 2-clause')
    end
    it "finds BSD 2-clause" do
      License.count.should == 0
      product = ProductFactory.create_new
      LicenseCrawler.process_github_master('mintdigital/execjslint', product).should be_truthy
      License.count.should == 1
      License.first.name.should eq('BSD 2-clause')
    end
    it "finds BSD 2-clause" do
      License.count.should == 0
      product = ProductFactory.create_new
      LicenseCrawler.process_github_master('ydaniv/uijet', product).should be_truthy
      License.count.should == 1
      License.first.name.should eq('BSD 2-clause')
    end

    it "finds Ruby" do
      License.count.should == 0
      product = ProductFactory.create_new
      LicenseCrawler.process_github_master('solutious/bone', product).should be_truthy
      License.count.should == 1
      License.first.name.should eq('Ruby')
    end

    it "finds Ruby" do
      License.count.should == 0
      product = ProductFactory.create_new
      LicenseCrawler.process_github_master('ruport/ruport', product).should be_truthy
      License.count.should == 1
      License.first.name.should eq('Ruby')
    end

  end

end
