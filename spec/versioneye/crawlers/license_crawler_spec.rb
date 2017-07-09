require 'spec_helper'

describe LicenseCrawler do
  let(:product){ ProductFactory.create_new }

  describe 'process_github_master' do
    before do
      License.delete_all
      product.save
    end

    it "finds PHP License 3.01" do
      VCR.use_cassette('license/php-src') do
        expect( License.count ).to eq(0)

        expect( LicenseCrawler.process_github_master('php/php-src', product) ).to be_truthy
        expect( License.count ).to eq(1)
        expect( License.first.name ).to eq('PHP-3.01')
      end
    end

    it "finds MIT" do
      VCR.use_cassette('license/gauntlet') do
        expect( License.count ).to eq(0)

        expect( LicenseCrawler.process_github_master('geta6/gauntlet', product) ).to be_truthy
        expect( License.count ).to eq(1)
        expect( License.first.name ).to eq('MIT')
      end
    end

    it "finds MIT" do
      VCR.use_cassette('license/a_b') do
        expect( License.count ).to eq(0)

        expect( LicenseCrawler.process_github_master('winton/a_b', product) ).to be_truthy
        expect( License.count ).to eq(1)
        expect( License.first.name ).to eq('MIT')
      end
    end

    it "finds MIT" do
      VCR.use_cassette('license/utilities') do
        expect( License.count ).to eq(0)

        expect( LicenseCrawler.process_github_master('ryanzec/utilities', product) ).to be_truthy
        expect( License.count ).to eq(1)
        expect( License.first.name ).to eq('MIT')
      end
    end

    it "finds MIT" do
      VCR.use_cassette('license/spatial_adapter') do
        expect( License.count ).to eq(0)

        expect( LicenseCrawler.process_github_master('achirkunov/spatial_adapter', product) ).to be_truthy
        expect( License.count ).to eq(1)
        expect( License.first.name ).to eq('MIT')
      end
    end

    it "finds MIT" do
      VCR.use_cassette('license/action_links') do
        expect( License.count ).to eq(0)

        expect( LicenseCrawler.process_github_master('biola/action_links', product) ).to be_truthy
        expect( License.count ).to eq(1)
        expect( License.first.name ).to eq('MIT')
      end
    end

    it "finds MIT" do
      VCR.use_cassette('license/doughboy') do
        expect( License.count ).to eq(0)

        expect( LicenseCrawler.process_github_master('jschairb/doughboy', product) ).to be_truthy
        expect( License.count ).to eq(1)
        expect( License.first.name ).to eq('MIT')
      end
    end

    it "finds MIT" do
      VCR.use_cassette('license/msgs') do
        expect( License.count ).to eq(0)

        expect( LicenseCrawler.process_github_master('cujojs/msgs', product) ).to be_truthy
        expect( License.count ).to eq(1)
        expect( License.first.name ).to eq('MIT')
      end
    end

    it "finds MIT" do
      VCR.use_cassette('license/ui-select2') do
        expect( License.count).to eq(0)

        expect( LicenseCrawler.process_github_master('angular-ui/ui-select2', product)).to be_truthy
        expect( License.count).to eq( 1 )
        expect( License.first.name).to eq('MIT')
      end
    end

    it "finds MIT" do
      VCR.use_cassette('license/event-stream') do
        expect( License.count).to eq(0)

        expect( LicenseCrawler.process_github_master('dominictarr/event-stream', product)).to be_truthy
        expect( License.count).to eq( 1 )
        expect( License.first.name).to eq('MIT')
      end
    end

    it "finds The Unlicense" do
      VCR.use_cassette('license/ScriptInclude') do
        expect( License.count).to eq( 0 )

        expect( LicenseCrawler.process_github_master('EvanHahn/ScriptInclude', product)).to be_truthy
        expect( License.count).to eq( 1 )
        expect( License.first.name).to eq('The Unlicense')
      end
    end

    it "finds The Unlicense" do
      VCR.use_cassette('license/udefine') do
        expect( License.count).to eq( 0 )

        expect( LicenseCrawler.process_github_master('freezedev/udefine', product)).to be_truthy
        expect( License.count).to eq( 1 )
        expect( License.first.name).to eq('The Unlicense')
      end
    end

    it "finds DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE" do
      VCR.use_cassette('license/mezu') do
        expect( License.count).to eq( 0 )

        expect( LicenseCrawler.process_github_master('tinogomes/mezu', product)).to be_truthy
        expect( License.count).to eq( 1 )
        expect( License.first.name).to eq('DWTFYWTP License')
      end
    end

    it "finds GPL-3" do
      VCR.use_cassette('license/abanalyzer') do
        expect( License.count).to eq( 0 )

        expect( LicenseCrawler.process_github_master('livingsocial/abanalyzer', product)).to be_truthy
        expect( License.count).to eq( 1 )
        expect( License.first.name).to eq('GPL-3.0')
      end
    end
    it "finds GPL-3" do
      VCR.use_cassette('license/thumbelina') do
        expect( License.count).to eq( 0 )

        expect( LicenseCrawler.process_github_master('czonsius/thumbelina', product)).to be_truthy
        expect( License.count).to eq( 1 )
        expect( License.first.name).to eq('GPL-3.0')
      end
    end

    it "finds GPL-2" do
      VCR.use_cassette('license/airplane_mode') do
        expect( License.count).to eq( 0 )

        expect( LicenseCrawler.process_github_master('benjaminoakes/airplane_mode', product)).to be_truthy
        expect( License.count).to eq( 1 )
        expect( License.first.name).to eq('GPL-2.0')
      end
    end

    it "finds AGPL-3" do
      VCR.use_cassette('license/fuel_purchase') do
        expect( License.count).to eq( 0 )

        link = Versionlink.new(
          :link => 'https://github.com/brighterplanet/fuel_purchase',
          :language => product.language,
          :prod_key => product.prod_key
        )
        expect( link.save ).to be_truthy
        LicenseCrawler.crawl

        expect( License.count).to eq( 1 )
        expect( License.first.name).to eq('AGPL-3.0')
      end
    end

    it "finds LGPL-3" do
      VCR.use_cassette('license/actionpool') do
        expect( License.count).to eq( 0 )
        link = Versionlink.new(:link => 'https://github.com/spox/actionpool', :language => product.language, :prod_key => product.prod_key)
        expect( link.save ).to be_truthy

        LicenseCrawler.crawl product.language

        expect( License.count).to eq( 1 )
        expect( License.first.name).to eq('LGPL-3.0')
      end
    end

    it "finds Apache-2.0" do
      VCR.use_cassette('license/action_mailer_tls') do
        expect( License.count).to eq( 0 )

        expect( LicenseCrawler.process_github_master('openrain/action_mailer_tls', product)).to be_truthy
        expect( License.count).to eq( 1 )
        expect( License.first.name).to eq('Apache-2.0')
      end
    end

    it "finds Apache-2.0" do
      VCR.use_cassette('license/active_blur') do
        expect( License.count).to eq( 0 )

        expect( LicenseCrawler.process_github_master('nearinfinity/active_blur', product)).to be_truthy
        expect( License.count).to eq( 1 )
        expect( License.first.name).to eq('Apache-2.0')
      end
    end

    it "finds Apache-2.0" do
      VCR.use_cassette('license/csscv') do
        expect( License.count).to eq( 0 )

        expect( LicenseCrawler.process_github_master('csswizardry/csscv', product)).to be_truthy
        expect( License.count).to eq( 1 )
        expect( License.first.name).to eq('Apache-2.0')
      end
    end

    it "finds Mozilla Public License Version 2.0" do
      VCR.use_cassette('license/ajax_pagination') do
        expect( License.count).to eq( 0 )

        expect( LicenseCrawler.process_github_master('ronalchn/ajax_pagination', product)).to be_truthy
        expect( License.count).to eq( 1 )
        expect( License.first.name).to eq('MPL-2.0')
      end
    end

    it "finds Mozilla Public License Version 2.0" do
      VCR.use_cassette('license/fireplace') do
        expect( License.count).to eq( 0 )

        expect( LicenseCrawler.process_github_master('mozilla/fireplace', product)).to be_truthy
        expect( License.count).to eq( 1 )
        expect( License.first.name).to eq('MPL-2.0')
      end
    end

    it "finds Mozilla Public License Version 2.0" do
      VCR.use_cassette('license/makedrive') do
        expect( License.count).to eq( 0 )

        expect( LicenseCrawler.process_github_master('mozilla/makedrive', product)).to be_truthy
        expect( License.count).to eq( 1 )
        expect( License.first.name).to eq('MPL-2.0')
      end
    end

    it "finds New BSD" do
      VCR.use_cassette('license/active_reload') do
        expect( License.count).to eq( 0 )

        expect( LicenseCrawler.process_github_master('paneq/active_reload', product)).to be_truthy
        expect( License.count).to eq( 1 )
        expect( License.first.name).to eq('New BSD')
      end
    end

    it "finds New BSD" do
      VCR.use_cassette('license/spree_coupon_preview') do
        expect( License.count).to eq( 0 )

        expect( LicenseCrawler.process_github_master('MrRuru/spree_coupon_preview', product)).to be_truthy
        expect( License.count).to eq( 1 )
        expect( License.first.name).to eq('New BSD')
      end
    end

    it "finds New BSD" do
      VCR.use_cassette('license/spree_essential_cms') do
        expect( License.count).to eq( 0 )

        expect( LicenseCrawler.process_github_master('citrus/spree_essential_cms', product)).to be_truthy
        expect( License.count).to eq( 1 )
        expect( License.first.name).to eq('New BSD')
      end
    end

    it "finds New BSD" do
      VCR.use_cassette('license/ar_mailer') do
        expect( License.count).to eq( 0 )

        expect( LicenseCrawler.process_github_master('adzap/ar_mailer', product)).to be_truthy
        expect( License.count).to eq( 1 )
        expect( License.first.name).to eq('New BSD')
      end
    end

    it "finds New BSD" do
      VCR.use_cassette('license/zrender') do
        expect( License.count).to eq( 0 )

        expect( LicenseCrawler.process_github_master('ecomfe/zrender', product)).to be_truthy
        expect( License.count).to eq( 1 )
        expect( License.first.name).to eq('New BSD')
      end
    end

    it "finds BSD 2-clause" do
      VCR.use_cassette('license/ambit') do
        expect( License.count).to eq( 0 )

        expect( LicenseCrawler.process_github_master('jimwise/ambit', product)).to be_truthy
        expect( License.count).to eq( 1 )
        expect( License.first.name).to eq('BSD 2-clause')
      end
    end

    it "finds BSD 2-clause" do
      VCR.use_cassette('license/execjslint') do
        expect( License.count).to eq( 0 )

        expect( LicenseCrawler.process_github_master('mintdigital/execjslint', product)).to be_truthy
        expect( License.count).to eq( 1 )
        expect( License.first.name).to eq('BSD 2-clause')
      end
    end

    it "finds BSD 2-clause" do
      VCR.use_cassette('license/uijet') do
        expect( License.count).to eq( 0 )

        expect( LicenseCrawler.process_github_master('ydaniv/uijet', product)).to be_truthy
        expect( License.count ).to eq( 1 )
        expect( License.first.name).to eq('BSD 2-clause')
      end
    end

    it "finds Ruby" do
      VCR.use_cassette('license/bone') do
        expect( License.count).to eq( 0 )

        expect( LicenseCrawler.process_github_master('solutious/bone', product)).to be_truthy
        expect( License.count).to eq( 1 )
        expect( License.first.name).to eq('Ruby')
      end
    end

    it "finds Ruby" do
      VCR.use_cassette('license/ruport') do
        expect( License.count).to eq( 0 )

        expect( LicenseCrawler.process_github_master('ruport/ruport', product)).to be_truthy
        expect( License.count).to eq( 1 )
        expect( License.first.name).to eq('Ruby')
      end
    end

  end
end
