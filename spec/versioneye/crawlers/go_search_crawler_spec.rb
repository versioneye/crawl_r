require 'spec_helper'
require 'json'

describe GoSearchCrawler do
  let(:index_list){
    ["github.com/gorilla/mux","github.com/codegangsta/cli"]
  }

  let(:package1){
    {
      "Package"     => "github.com/gorilla/mux",
      "Name"        => "mux",
      "StarCount"   => 2484,
      "Synopsis"    => "",
      "Description" => "Package mux implements a request r..",
      "Imports"     => [ "github.com/gorilla/context" ],
      "TestImports" => nil,
      "ProjectURL"  => "https://github.com/gorilla/mux",
      "StaticRank"  => 1
    }
  }

  let(:package2){
    {
      'Package'     => "github.com/codegangsta/cli",
      'Name'        => "cli",
      'StarCount'   => 4241,
      'Synopsis'    => "",
      'Description' => "Package cli provides a minimal framework",
      'Imports'     => nil,
      'TestImports' => nil,
      'ProjectURL'  => "https://github.com/codegangsta/cli",
      'StaticRank'  => 2
    }
  }

  before do
    FakeWeb.allow_net_connect = false

    FakeWeb.register_uri(
      :get,
      'http://go-search.org/api?action=packages',
      :status => 200,
      :body => JSON.generate(index_list)
    )

    FakeWeb.register_uri(
      :get,
      'http://go-search.org/api?action=package&id=github.com/gorilla/mux',
      :status => 200,
      :body => JSON.generate(package1)
    )

    FakeWeb.register_uri(
      :get,
      'http://go-search.org/api?action=package&id=github.com/codegangsta/cli',
      :status => 200,
      :body => JSON.generate(package2)
    )

  end

  after do
    Product.delete_all

    FakeWeb.allow_net_connect = true
    FakeWeb.clean_registry
  end


  context "fetch-package-index" do
    it "returns the correct list of package ids " do
      res = GoSearchCrawler.fetch_package_index

      expect(res).not_to be_nil
      expect(res.count).to eq(2)
      expect(res.first).to eq(index_list.first)
    end
  end

  context "fetch_package_detail" do
    it "returns correct package details" do
      res = GoSearchCrawler.fetch_package_detail( package1["Package"] )

      expect(res).not_to be_nil
      expect(res.has_key?(:Imports)).to be_truthy
      expect(res.has_key?(:TestImports)).to be_truthy
      expect(res[:Package]).to eq( package1["Package"] )
    end
  end

  context "crawl_all" do
    it "saves new products" do
      res = GoSearchCrawler.crawl
      expect(res).to be_truthy

      expect(Product.all.count).to eq(2)

      prod1 = Product.find_by(prod_key: package1['Package'], prod_type: 'Godep')
      expect(prod1).not_to be_nil
      expect(prod1[:name]).to eq(package1['Name'])

      deps = prod1.all_dependencies.to_a
      expect(deps.size).to eq(1)
      expect(deps[0].prod_key).to eq( package1['Package']  )
      expect(deps[0].dep_prod_key).to eq( package1['Imports'].first )

      expect(Versionlink.all.size).to eq(2)

      link_db = Versionlink.where(prod_key: prod1[:prod_key]).first
      expect(link_db).not_to be_nil
      expect(link_db[:link]).to eq(package1['ProjectURL'])

      prod2 = Product.find_by(prod_key: package2['Package'], prod_type: 'Godep')
      expect(prod2).not_to be_nil
      expect(prod2[:name]).to eq(package2['Name'])

      link_db = Versionlink.where(prod_key: prod2[:prod_key]).first
      expect(link_db).not_to be_nil
      expect(link_db[:link]).to eq(package2['ProjectURL'])


    end
  end
end
