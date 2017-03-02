require 'spec_helper'

describe GithubLicenseCrawler do
  lm = LicenseMatcher.new
  
  let(:lic1_url){ "https://raw.githubusercontent.com/AdaptiveMe/adaptive-arp-api/master/LICENSE" }
  let(:repo1_url) {"https://github.com/AdaptiveMe/adaptive-arp-windows"}

  let(:lic2_url){"https://github.com/mjmeans/Adafruit.IoT"}
  let(:repo2_url){ "https://github.com/mjmeans/Adafruit.IoT" }

  let(:lic3_url){ "https://raw2.github.com/PaulWeakley/Angular-Einstein/master/LICENSE" }
  let(:repo3_url){ "https://github.com/PaulWeakley/Angular-Einstein" } 

  describe "parse_url" do
    it "returns URI object for proper URLs" do
      expect( GithubLicenseCrawler.parse_url(repo1_url).to_s ).to eq(repo1_url)
    end

    it "returns nil if not valid URL" do
      expect( GithubLicenseCrawler.parse_url('C://home/folder/license.xml') ).to be_nil
    end
  end

  describe "is_github_url" do
    it "returns true to all the expected URLs" do
      uri1 = GithubLicenseCrawler.parse_url lic1_url
      expect( GithubLicenseCrawler.is_github_url(uri1) ).to be_truthy

      uri2 = GithubLicenseCrawler.parse_url repo1_url
      expect( GithubLicenseCrawler.is_github_url(uri2) ).to be_truthy

      uri3 = GithubLicenseCrawler.parse_url lic3_url
      expect( GithubLicenseCrawler.is_github_url(uri3) ).to be_truthy
    end

    it "returns false for all other URLS" do
      uri1 = GithubLicenseCrawler.parse_url 'https://www.versioneye.com'
      expect( GithubLicenseCrawler.is_github_url(uri1) ).to be_falsey
    end
  end

  describe "to_page_url" do
    it "transform github url into repo main page" do
      uri = GithubLicenseCrawler.parse_url lic3_url
      expect(GithubLicenseCrawler.to_page_url(uri).to_s ).to eq(repo3_url)
    end
  end

  describe "fetch_overall_summary" do
    it "extract correct correct summary data from lic1 page" do
      uri = GithubLicenseCrawler.parse_url repo1_url
      expected_txt = " 155 commits license 3 branches license 1 release license 2 contributors license Apache-2.0 license C# 99.8% license PowerShell 0.2% license "

      VCR.use_cassette("github_licenses/lic1") do
        txt = GithubLicenseCrawler.fetch_overall_summary uri
        expect(txt).to eq(expected_txt)
      end
    end
  end

  describe "fetch_and_process_page" do
    it "matches correct license for repo1" do
      uri = GithubLicenseCrawler.parse_url repo1_url
      VCR.use_cassette("github_licenses/lic1") do
        best_match = GithubLicenseCrawler.fetch_and_process_page(lm, uri)
        expect( best_match.first ).to eq('apache-2.0')
      end
    end

    it "returns empty match for repo2" do
      uri = GithubLicenseCrawler.parse_url repo2_url
      VCR.use_cassette("github_licenses/lic2") do
        best_match = GithubLicenseCrawler.fetch_and_process_page(lm, uri)
        expect(best_match.first).to be_nil
      end
    end

    it "returns MIT for repo3" do
      uri = GithubLicenseCrawler.parse_url repo3_url
      VCR.use_cassette("github_licenses/lic3") do
        best_match = GithubLicenseCrawler.fetch_and_process_page(lm, uri)
        expect(best_match.first).to eq('mit')
      end
    end
  end

end
