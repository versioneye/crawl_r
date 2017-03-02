require 'spec_helper'

describe CodeplexLicenseCrawler do
  lm = LicenseMatcher.new

  let(:lic1_url){ "http://bundler.codeplex.com/license" }
  let(:lic2_url){ "https://toastspopuphelpballoon.codeplex.com/license" }
  let(:lic3_url){ "http://moo.codeplex.com/license" }
  let(:lic4_url){ "https://pubcomp.codeplex.com/license" }
  let(:lic5_url){ "https://speechlib.codeplex.com/license" }
  let(:lic6_url){ "http://dbentry.codeplex.com/license" }


  describe "is_codeplex_url" do
    it "returns true for all license urls" do
      expect(CodeplexLicenseCrawler.is_codeplex_url(lic1_url)).to be_truthy
      expect(CodeplexLicenseCrawler.is_codeplex_url(lic2_url)).to be_truthy
      expect(CodeplexLicenseCrawler.is_codeplex_url(lic3_url)).to be_truthy
      expect(CodeplexLicenseCrawler.is_codeplex_url(lic4_url)).to be_truthy
      expect(CodeplexLicenseCrawler.is_codeplex_url(lic5_url)).to be_truthy
    end

    it "returns false for all other kinds" do
       expect(CodeplexLicenseCrawler.is_codeplex_url(nil)).to be_falsey
       expect(CodeplexLicenseCrawler.is_codeplex_url('https://versioneye.com')).to be_falsey

    end
  end

  describe "fetch_and_process_page" do
    it "returns BSD-3 for lic1_url" do
      uri = CodeplexLicenseCrawler.to_license_url lic1_url
      VCR.use_cassette('codeplex_licenses/lic1') do
        best_match = CodeplexLicenseCrawler.fetch_and_process_page(lm, uri)
        expect(best_match[0]).to eq('bsd-3-clause')
        expect(best_match[1]).to be > 0.9
      end
    end

    it "returns BSD-2 for lic2_url" do
      uri = CodeplexLicenseCrawler.to_license_url lic2_url
      VCR.use_cassette('codeplex_licenses/lic2') do
        best_match = CodeplexLicenseCrawler.fetch_and_process_page(lm, uri)
        expect(best_match[0]).to eq('bsd-2-clause')
        expect(best_match[1]).to be > 0.9
      end
    end

    it "returns GPL-2 for lic3_url" do
      uri = CodeplexLicenseCrawler.to_license_url lic3_url
      VCR.use_cassette('codeplex_licenses/lic3') do
        best_match = CodeplexLicenseCrawler.fetch_and_process_page(lm, uri)
        expect(best_match[0]).to eq('gpl-2.0')
        expect(best_match[1]).to be > 0.9
      end
    end

    it "returns LGPL for lic4_url" do
      uri = CodeplexLicenseCrawler.to_license_url lic4_url
      VCR.use_cassette('codeplex_licenses/lic4') do
        best_match = CodeplexLicenseCrawler.fetch_and_process_page(lm, uri)
        expect(best_match[0]).to eq('lgpl-2.1')
        expect(best_match[1]).to be > 0.9
      end
    end

    it "returns MS-PL for lic5_url" do
      uri = CodeplexLicenseCrawler.to_license_url lic5_url
      VCR.use_cassette('codeplex_licenses/lic5') do
        best_match = CodeplexLicenseCrawler.fetch_and_process_page(lm, uri)
        expect(best_match[0]).to eq('ms-pl')
        expect(best_match[1]).to be > 0.9
      end
    end

    it "returns BSD-2 for lic5_url" do
      uri = CodeplexLicenseCrawler.to_license_url lic6_url
      VCR.use_cassette('codeplex_licenses/lic6') do
        best_match = CodeplexLicenseCrawler.fetch_and_process_page(lm, uri)
        expect(best_match[0]).to eq('custom')
        expect(best_match[1]).to be > 0.9
      end
    end


  end
end
