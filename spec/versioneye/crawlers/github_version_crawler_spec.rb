require 'spec_helper'

describe GithubVersionCrawler do

  before :all do
    FakeWeb.allow_net_connect = true
  end

  after :all do
    WebMock.allow_net_connect!
  end

  describe ".owner_and_repo" do
    example "1" do
      repo = 'https://github.com/0xced/ABGetMe.git'
      parsed = GithubVersionCrawler.parse_github_url(repo)

      # parsed.should_not be_nil
      expect( parsed[:owner] ).to  eq('0xced')
      expect( parsed[:repo] ).to  eq('ABGetMe')
    end
  end


  describe ".fetch_commit_date" do

    it "should return the date for a commit" do
      VCR.use_cassette('github/crawl_versions/fetch_commit_date') do

        user_repo = {:owner => 'versioneye', :repo => 'naturalsorter' }
        date = GithubVersionCrawler.fetch_commit_date(
          user_repo, '3cc7ef47557d7d790c7e55e667d451f56d276c13'
        )

        expect( date ).not_to be_nil
        expect( date ).to eq("2013-06-17 10:00:51 UTC")
      end
    end
  end

  describe ".versions_for_github_url" do

    it "returns correct versions for render-as-markdown" do
      VCR.use_cassette('github/crawl_versions/versions_for_github_url') do
        repo_url = 'https://github.com/versioneye/pom_json_format.git'
        versions = GithubVersionCrawler.versions_for_github_url repo_url

        expect( versions ).not_to be_nil
        expect( versions.size ).to eq(1)
      end
    end
  end

  let(:test_product){
    Product.new(
      language: Product::A_LANGUAGE_RUBY,
      prod_type: Project::A_TYPE_RUBYGEMS,
      prod_key: 'versioneye-security',
      name: 'versioneye-security'
    )
  }
  let(:test_sha){
    '5785e698f8ab12c8c531d7de0a92f80ccfad710e'
  }

  context "crawl_for_product" do
    before do
      test_product.versions = []
      test_product.versions << Version.new(version: '1.1.1')
      test_product.save
    end


    it "crawls correct versions for `versioneye/versioneye-core`" do
      VCR.use_cassette('github/crawl_versions/product_versions') do
        api_client = GithubVersionFetcher.new #uses keys from Settings.json

        expect(test_product.versions.size).to eq(1)
        res = GithubVersionCrawler.crawl_for_product(
          api_client, test_product, 'versioneye', 'versioneye-security'
        )

        test_product.reload
        expect(res).to be_truthy
        expect(test_product.versions.size).to eq(9)

        #it saves data from tag response correctly
        tag_ver = test_product.versions.where(version: '1.1.1').first
        expect(tag_ver).not_to be_nil
        expect(tag_ver[:tag]).to eq('v1.1.1')
        expect(tag_ver[:status]).to eq('stable')
        expect(tag_ver[:commit_sha]).to eq(test_sha)
        expect(tag_ver[:released_string]).to eq("2016-07-04 09:38:25 UTC")
      end
    end
  end

end
