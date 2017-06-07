require 'spec_helper'

describe BitbucketLicenseCrawler do
  let(:repo1_url){ "https://bitbucket.org/acraven/banshee" }
  
  context "is_license_file" do
    it "returns true for commonly used filenames" do
      expect(BitbucketLicenseCrawler.is_license_file("license")).to be_truthy
      expect(BitbucketLicenseCrawler.is_license_file("LICENSE.md")).to be_truthy
      expect(BitbucketLicenseCrawler.is_license_file("LICENSE-MIT")).to be_truthy
      expect(BitbucketLicenseCrawler.is_license_file("Copying")).to be_truthy
    end

    it "returns false for non-license files" do
      expect(BitbucketLicenseCrawler.is_license_file(nil)).to be_falsey
      expect(BitbucketLicenseCrawler.is_license_file('project.json')).to be_falsey
    end
  end


  context "fetch_license_urls" do
    it "returns correct status-code 200 and correct list of urls" do
      uri = BitbucketLicenseCrawler.parse_url( repo1_url )

      VCR.use_cassette('bitbucket_licenses/repo1') do
        code, urls = BitbucketLicenseCrawler.fetch_license_urls uri
        expect(code).to eq(200)
        expect(urls).not_to be_nil
        expect(urls.size).to eq(1)
        expect(urls.first).to eq("""https://bitbucket.org/acraven/banshee/raw/9ae61b530bd23eab05e0ede4d0d6ce6f21993f23/LICENSE?at=master")
      end
    end
  end
end
