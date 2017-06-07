require 'spec_helper'

describe HexCrawler do
  let(:prod1){
    Product.new(
      language: Product::A_LANGUAGE_ELIXIR,
      prod_type: Project::A_TYPE_HEX,
      prod_key: 'abacus',
      name: 'abacus'
    )
  }

  let(:prod2){
    Product.new(
      language: Product::A_LANGUAGE_ELIXIR,
      prod_type: Project::A_TYPE_HEX,
      prod_key: 'anilixir',
      name: 'anilixir'
    )
  }

  let(:prod3){
     Product.new(
      language: Product::A_LANGUAGE_ELIXIR,
      prod_type: Project::A_TYPE_HEX,
      prod_key: 'cowboy',
      name: 'cowboy',
      version: '1.1.2'
    )
  }

  let(:prod4){
    Product.new(
      language: Product::A_LANGUAGE_ELIXIR,
      prod_type: Project::A_TYPE_HEX,
      prod_key: 'aatree',
      name: 'aatree',
      version: '0.1.0'
    )
  }

  let(:product_doc){
    {
      url: "https://hex.pm/api/packages/aatree",
      updated_at: "2017-05-28T20:44:54.961756Z",
      releases: [
        {
          version: "0.1.0",
          url: "https://hex.pm/api/packages/aatree/releases/0.1.0"
        }
      ],
      name: "aatree",
      meta: {
        maintainers: [ "Ricky Han" ],
        links: {
          "GitHub": "https://github.com/rickyhan/aatree"
        },
        licenses: [ "Apache 2.0" ],
        description: "AA Tree in Pure Elixir"
      },
      inserted_at: "2017-05-28T20:44:50.276570Z",
      downloads: {
        week: 5,
        day: 5,
        all: 5
      }
    }
  }

  context "upsert_product" do
    it "saves a new product from JSON item" do
      expect(Product.all.size).to eq(0)

      HexCrawler.upsert_product(product_doc)

      expect(Product.all.size).to eq(1)

      prod = Product.all.first
      expect(prod[:language]).to eq(prod4[:language])
      expect(prod[:prod_type]).to eq(prod4[:prod_type])
      expect(prod[:prod_key]).to eq(prod4[:prod_key])
      expect(prod[:name]).to eq(prod4[:name])
      expect(prod[:description]).to eq('AA Tree in Pure Elixir')
      expect(prod[:downloads]).to eq(5)
    end
  end

  context "upsert_dependency" do
    it "saves product dependency correctly" do
      dep_doc = {
        requirement: "~> 1.0",
        optional: false,
        app: "ranch"
      }

      expect(Dependency.all.size).to eq(0)
      dep_db = HexCrawler.upsert_dependency(prod3, "1.0.0", dep_doc)
      expect(Dependency.all.size).to eq(1)

      expect(dep_db[:prod_type]).to eq(prod3[:prod_type])
      expect(dep_db[:language]).to eq(prod3[:language])
      expect(dep_db[:prod_version]).to eq('1.0.0')
      expect(dep_db[:dep_prod_key]).to eq(dep_doc[:app])
      expect(dep_db[:name]).to eq(dep_doc[:app])
      expect(dep_db[:version]).to eq(dep_doc[:requirement])
      expect(dep_db[:scope]).to eq(Dependency::A_SCOPE_COMPILE)
    end
  end

  let(:version_doc){
    {
      version: "1.0.0",
      url: "https://hex.pm/api/packages/cowboy/releases/1.0.0",
      updated_at: "2015-04-26T15:26:01.675819Z",
      retirement: nil,
      requirements: {
        ranch: {
          requirement: "~> 1.0",
          optional: false,
          app: "ranch"
        },
        cowlib: {
          requirement: "~> 1.0.0",
          optional: false,
          app: "cowlib"
        }
      },
      package_url: "https://hex.pm/api/packages/cowboy",
      meta: {
        elixir: nil,
        build_tools: [ "make", "rebar" ],
        app: "cowboy"
      },
      inserted_at: "2014-08-01T16:11:00.000000Z",
      has_docs: false,
      downloads: 300563
    }
  }

  context "upsert_version" do
    before do
      prod3.save
    end

    it "saves correctly data from json response" do
      expect(prod3.versions.size).to eq(0)

      HexCrawler.upsert_version(prod3, version_doc)
      prod3.reload
      expect(prod3.versions.size).to eq(1)

      ver = prod3.versions.first
      expect(ver[:version]).to eq(version_doc[:version])
      expect(ver[:status]).to eq('stable')
      expect(ver[:released_at]).not_to be_nil
      expect(ver[:released_string]).not_to be_nil
    end
  end

  context "save_product_version" do
    before do
      prod3.versions = []
      prod3.save
    end

    it "saves all relevant version data from the response doc" do
      expect(Product.all.size).to eq(1)
      expect(Dependency.all.size).to eq(0)
      expect(prod3.versions.size).to eq(0)

      HexCrawler.save_product_version(prod3[:prod_key], version_doc)
      prod3.reload

      expect(Product.all.size).to eq(1)
      expect(Dependency.all.size).to eq(2)
      expect(prod3.versions.size).to eq(1)

    end
  end

  context "save_product" do
    it "saves all relevant information from product json doc" do
      expect(Product.all.size).to eq(0)
      Developer.delete_all
      expect(Developer.all.size).to eq(0)

      HexCrawler.save_product(product_doc)

      expect(Product.all.size).to eq(1)
      prod = Product.all.first
      expect(prod[:language]).to eq(prod4[:language])
      expect(prod[:prod_type]).to eq(prod4[:prod_type])
      expect(prod[:prod_key]).to eq(prod4[:prod_key])
      expect(prod[:name]).to eq(prod4[:name])
      expect(prod[:description]).to eq('AA Tree in Pure Elixir')
      expect(prod[:downloads]).to eq(5)

      expect(Versionlink.all.size).to eq(1)
      link = Versionlink.all.first
      expect(link[:language]).to eq(prod4[:language])
      expect(link[:prod_key]).to eq(prod4[:prod_key])
      expect(link[:link]).to eq('https://github.com/rickyhan/aatree')
      expect(link[:name]).to eq('GitHub')

      expect(License.all.size).to eq(1)
      lic = License.all.first
      expect(lic[:language]).to eq(lic[:language])
      expect(lic[:prod_key]).to eq(lic[:prod_key])
      expect(lic[:name]).to eq('Apache 2.0')

      expect(Developer.all.size).to eq(1)
      dev = Developer.all.first
      expect(dev[:language]).to eq(prod4[:language])
      expect(dev[:prod_key]).to eq(prod4[:prod_key])
      expect(dev[:name]).to eq('Ricky Han')
    end
  end


  context "fetch_product_list" do
    it "returns correct first item from first page" do
      VCR.use_cassette('hex/product_list_page1') do
        res = HexCrawler.fetch_product_list(1)

        expect( res ).not_to be_nil
        expect(res.size).to eq(100)
        expect(res[0][:name]).to eq('aatree')
      end
    end

    it "returns correct first item from second page" do
      VCR.use_cassette('hex/product_list_page2') do
        res = HexCrawler.fetch_product_list(2)

        expect( res ).not_to be_nil
        expect( res.size ).to eq(100)
        expect(res[0][:name]).to eq('analyze')
      end
    end
  end

  context "fetch_product_details" do
    it "returns correct product details" do
      VCR.use_cassette('hex/product_details') do
        res = HexCrawler.fetch_product_details(prod3[:prod_key])

        expect(res).not_to be_nil
        expect(res[:name]).to eq(prod3[:name])
        expect(res[:releases].size).to eq(8)
      end
    end
  end

  context "fetch_product_version" do
    it "returns correct version details" do
      VCR.use_cassette('hex/product_version') do
        res = HexCrawler.fetch_product_version(prod3[:prod_key], prod3[:version])

        expect(res).not_to be_nil
        expect(res[:version]).to eq(prod3[:version])
      end
    end
  end
end
