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


  describe "is_license_filename" do
    it "matches variation of license" do
      expect(GithubLicenseCrawler.is_license_filename('license')).to be_truthy
      expect(GithubLicenseCrawler.is_license_filename('license.md')).to be_truthy
      expect(GithubLicenseCrawler.is_license_filename('licence.txt')).to be_truthy
      expect(GithubLicenseCrawler.is_license_filename('license')).to be_truthy
      expect(GithubLicenseCrawler.is_license_filename('MIT_license')).to be_truthy
      expect(GithubLicenseCrawler.is_license_filename('license-MIT')).to be_truthy

    end

    it "matches variation of copyright" do
      expect(GithubLicenseCrawler.is_license_filename('copyright')).to be_truthy
      expect(GithubLicenseCrawler.is_license_filename('COPYRIGHT')).to be_truthy
    end

    it "returns false for others" do
      expect(GithubLicenseCrawler.is_license_filename('README.md')).to be_falsey
      expect(GithubLicenseCrawler.is_license_filename('LINT.er')).to be_falsey
    end

  end

  let(:serde_url){ 'https://github.com/serde-rs/serde/tree/fd3d1396d33a49200daaaf8bf17eba78fe4183d8' }
  let(:mux_product){
    Product.new(
      language: Product::A_LANGUAGE_GO,
      prod_type: Project::A_TYPE_GODEP,
      prod_key: 'github.com/gorilla/mux',
      name: 'mux',
    )
  }

  let(:mux_version1){
    Version.new(
      version: '1.4.0',
      commit_sha: 'bcd8bc72b08df0f70df986b97f95590779502d31'
    )
  }

  let(:mux_version2){
    Version.new(
      version: '1.3.0',
      commit_sha: '392c28fe23e1c45ddba891b0320b3b5df220beea'
    )
  }

  let(:serde_product){
    Product.new(
      language: Product::A_LANGUAGE_RUST,
      prod_type: Project::A_TYPE_CARGO,
      prod_key: 'serde',
      name: 'serde'
    )
  }

  let(:serde_version1){
    Version.new(
      version: '1.0.8',
      commit_sha: 'ec8dd2f5a0eac20972c0a854038021b24c06a9dd'
    )
  }

  describe "fetch_licenses_from_commit_tree" do
    it "returns correct list of url paths for SERDE" do
      VCR.use_cassette('github_licenses/serde_commit_tree') do
        urls = GithubLicenseCrawler.fetch_licenses_from_commit_tree(serde_url)
        expect(urls).not_to be_nil
        expect(urls.size).to eq(2)
        expect(urls[0][0]).to eq('LICENSE-APACHE')
        expect(urls[0][1]).to eq("/serde-rs/serde/blob/fd3d1396d33a49200daaaf8bf17eba78fe4183d8/LICENSE-APACHE")

        expect(urls[1][0]).to eq('LICENSE-MIT')
        expect(urls[1][1]).to eq("/serde-rs/serde/blob/fd3d1396d33a49200daaaf8bf17eba78fe4183d8/LICENSE-MIT")
      end
    end
  end

  describe "crawl_version_commit_tree" do
    before do
      mux_product.versions << mux_version1
      mux_product.save

      serde_product.versions << serde_version1
      serde_product.save
    end

    it "fetches licenses for github.com/gorilla/mux" do
      VCR.use_cassette('github_licenses/mux_version_commit_tree') do
        expect(License.all.size).to eq(0)

        prod_dt = GithubLicenseCrawler.to_prod_dt(mux_product, mux_version1)
        GithubLicenseCrawler.crawl_version_commit_tree(
          prod_dt, 'gorilla', 'mux', 0.9, lm
        )
        expect(License.all.size).to eq(1)


        lic1 = License.where(
          language: mux_product[:language],
          prod_key: mux_product[:prod_key],
          version: mux_version1[:version]
        ).first

        expect(lic1).not_to be_nil
        expect(lic1[:spdx_id]).to eq('BSD-3-Clause')
      end
    end

    it "saves multiple licenses for version" do
      VCR.use_cassette('github_licenses/serde_version_commit_tree') do
        expect(License.all.size).to eq(0)

        prod_dt = GithubLicenseCrawler.to_prod_dt(serde_product, serde_version1)
        GithubLicenseCrawler.crawl_version_commit_tree(
          prod_dt, 'serde-rs', 'serde', 0.9, lm
        )

        expect(License.all.size).to eq(2)
        licenses = License.where(
          language: serde_product[:language],
          prod_key: serde_product[:prod_key],
          version: serde_version1[:version]
        ).to_a

        expect(licenses.empty?).to be_falsey
        expect(licenses[0]).not_to be_nil
        expect(licenses[0][:spdx_id]).to eq('Apache-2.0')
        expect(licenses[1]).not_to be_nil
        expect(licenses[1][:spdx_id]).to eq('MIT')

      end
    end
  end

  describe "crawl_product_commit_tree" do
    before do
      mux_product.versions << mux_version2
      mux_product.versions << mux_version1
      mux_product.save
    end

    it "fetches correct licenses for each of version" do
      VCR.use_cassette('github_licenses/crawl_product_commit_tree') do
        expect(License.all.size).to eq(0)

        GithubLicenseCrawler.crawl_product_commit_tree(
          mux_product[:language], mux_product[:prod_key], 'gorilla', 'mux', 0.9, lm
        )
        expect(License.all.size).to eq(2)

        lic1 = License.where(
          language: mux_product[:language],
          prod_key: mux_product[:prod_key],
          version: mux_version1[:version]
        ).first
        expect(lic1).not_to be_nil
        expect(lic1[:spdx_id]).to eq('BSD-3-Clause')

        lic2 = License.where(
          language: mux_product[:language],
          prod_key: mux_product[:prod_key],
          version: mux_version2[:version]
        ).first
        expect(lic2).not_to be_nil
        expect(lic2[:spdx_id]).to eq('BSD-3-Clause')


      end
    end
  end
end
