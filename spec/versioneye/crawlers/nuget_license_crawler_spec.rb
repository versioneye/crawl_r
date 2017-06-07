require 'spec_helper'

describe NugetLicenseCrawler do
  let(:lic1_url){ "https://www.nuget.org/packages/Newtonsoft.Json/9.0.1" }
  let(:lic2_url){ "https://www.nuget.org/packages/BabylonJS" }

  context "fetch_and_process_nuget_page" do
    it "returns MIT for JSON.NET page" do
      VCR.use_cassette('nuget_licenses/lic1') do
        lic_id = NugetLicenseCrawler.fetch_and_process_nuget_page(lic1_url)
        expect(lic_id).to eq('MIT')
      end
    end

    it "returns Apache-2.0 for BabylonJS page" do
      VCR.use_cassette('nuget_licenses/lic2') do
        lic_id = NugetLicenseCrawler.fetch_and_process_nuget_page(lic2_url)
        expect(lic_id).to eq('Apache-2.0') 
      end
    end
  end
end
