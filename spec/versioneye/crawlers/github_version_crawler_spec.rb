require 'spec_helper'
require 'vcr'
require 'webmock'


RSpec.configure do |c|
  # so we can use :vcr rather than :vcr => true;
  # in RSpec 3 this will no longer be necessary.
  c.treat_symbols_as_metadata_keys_with_true_values = true

  c.around(:each, :vcr) do |example|
    name = example.metadata[:full_description].split(/\s+/, 2).join("/").underscore.gsub(/[^\w\/]+/, "_")
    options = example.metadata.slice(:record, :match_requests_on).except(:example_group)
    VCR.use_cassette(name, options) { example.call }
  end
end


describe GithubVersionCrawler, :vcr do

  before :all do
    FakeWeb.allow_net_connect = true

  end

  after :all do
    # remove Webmock
    WebMock.allow_net_connect!

    # # restore Fakeweb
    # FakeWeb.allow_net_connect = false
    # FakeWeb.clean_registry
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

  describe "#tags_for_repo" do
    # use_vcr_cassette

    it "returns tags" do
      url = 'https://github.com/0xced/ABGetMe.git'
      owner_repo = GithubVersionCrawler.parse_github_url url

      VCR.use_cassette('github/crawl_versions/tags_for_repo') do
        tags = GithubVersionCrawler.tags_for_repo owner_repo
        expect( tags ).not_to be_nil
        expect( tags.size ).to eq(1)
        t = tags.first
        expect( t.name ).to eq('1.0.0')
        expect( t.commit.sha).to eq( '8d8d7ca9f3429c952b83d1ecf03178e8efb99cb2' )
      end
    end
  end

  describe ".fetch_commit_date" do

    it "should return the date for a commit" do
      VCR.use_cassette('github/crawl_versions/fetch_commit_date') do

        user_repo = {:owner => 'versioneye', :repo => 'naturalsorter' }
        date = GithubVersionCrawler.fetch_commit_date user_repo, '3cc7ef47557d7d790c7e55e667d451f56d276c13'

        expect( date ).not_to be_nil
        expect( date ).to eq("2013-06-17 10:00:51 UTC")
      end
    end
  end

  describe ".versions_for_github_url" do

    it "returns correct versions for render-as-markdown" do
      VCR.use_cassette('github/crawl_versions/versions_for_github_url') do
        repo_url = 'https://github.com/rmetzler/render-as-markdown.git'
        versions = GithubVersionCrawler.versions_for_github_url repo_url

        expect( versions ).not_to be_nil
        expect( versions.size ).to eq(4)
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
