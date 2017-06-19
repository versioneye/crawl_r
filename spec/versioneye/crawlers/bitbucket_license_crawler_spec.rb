require 'spec_helper'

describe BitbucketLicenseCrawler do
  lm = LicenseMatcher.new

  let(:commit_url){
    'https://bitbucket.org/mchaput/whoosh/src/20f2c538262e8f656e089521a21a9fa5c8ae3394'
  }

  let(:test_file_url){
    'https://bitbucket.org/mchaput/whoosh/raw/20f2c538262e8f656e089521a21a9fa5c8ae3394/LICENSE.txt'
  }

  context "fetch_licenses_from_commit_tree" do
    it "fetches correct list of filename and path pair" do
      VCR.use_cassette('bitbucket/license_crawler/fetch_licenses_from_commit_tree') do
        res = BitbucketLicenseCrawler.fetch_licenses_from_commit_tree(commit_url)
        expect(res).not_to be_nil
        expect(res.size).to eq(1)

        expect(res[0][0]).to eq('LICENSE.txt')
        expect(res[0][1]).to eq('/mchaput/whoosh/src/20f2c538262e8f656e089521a21a9fa5c8ae3394/LICENSE.txt?at=default')
      end
    end
  end

  context "fetch_and_match_license_file" do
    it "fetches and detects correct license for test_file_url" do
      VCR.use_cassette('bitbucket/license_crawler/fetch_and_match_license_file') do
        res = BitbucketLicenseCrawler.fetch_and_match_license_file(lm, test_file_url)
        expect(res).not_to be_nil
        expect(res.size).to eq(2)
        expect(res[0]).to eq('bsd-2-freebsd')
      end
    end
  end

  let(:whoosh_product){
    Product.new(
      language: Product::A_LANGUAGE_PYTHON,
      prod_type: Project::A_TYPE_PIP,
      prod_key: 'whoosh',
      name: 'whoosh'
    )
  }

  let(:whoosh_version1){
    Version.new(
      version: '2.7.4',
      commit_sha: '20f2c538262e8f656e089521a21a9fa5c8ae3394'
    )
  }

  let(:whoosh_version2){
    Version.new(
      version: '2.7.0',
      commit_sha: '018de5b25567a8d25464b409ba85e722f7694bc7'
    )
  }


  context "crawl_version_commit_tree" do
    before do
      whoosh_product.versions << whoosh_version1
      whoosh_product.save
    end

    it "fetches and saves license file correctly" do
      VCR.use_cassette('bitbucket/license_crawler/crawl_version_commit_tree') do
        expect(License.all.size).to eq(0)

        prod_dt = BitbucketLicenseCrawler.to_prod_dt(whoosh_product, whoosh_version1)
        BitbucketLicenseCrawler.crawl_version_commit_tree(
          prod_dt, 'mchaput', 'whoosh', 0.9, lm
        )

        expect(License.all.size).to eq(1)
        lic1 = License.where(
          language: whoosh_product[:language],
          prod_key: whoosh_product[:prod_key],
          version: whoosh_version1[:version]
        ).first

        expect(lic1).not_to be_nil
        expect(lic1[:spdx_id]).to eq('BSD-2-FreeBSD')
      end
    end
  end

  context "crawl_product_commit_tree" do
    before do
      whoosh_product.versions << whoosh_version1
      whoosh_product.versions << whoosh_version2
      whoosh_product.save
    end

    it "fetches and saves licenses for each version" do
      VCR.use_cassette('bitbucket/license_crawler/crawl_product_commit_tree') do
        expect(License.all.size).to eq(0)

        BitbucketLicenseCrawler.crawl_product_commit_tree(
          whoosh_product[:language], whoosh_product[:prod_key],
          'mchaput', 'whoosh', 0.9, lm
        )

        expect(License.all.size).to eq(2)
        lic1 = License.where(
          language: whoosh_product[:language],
          prod_key: whoosh_product[:prod_key],
          version: whoosh_version1[:version]
        ).first

        expect(lic1).not_to be_nil
        expect(lic1[:spdx_id]).to eq('BSD-2-FreeBSD')

        lic2 = License.where(
          language: whoosh_product[:language],
          prod_key: whoosh_product[:prod_key],
          version: whoosh_version2[:version]
        ).first

        expect(lic2).not_to be_nil
        expect(lic2[:spdx_id]).to eq('BSD-2-FreeBSD')

      end
    end
  end

end

