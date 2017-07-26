require 'spec_helper'

describe CratesCrawler do
  let(:env){ Settings.instance.environment }
  let(:api_key){ GlobalSetting.get(env, 'cratesio_api_key') }

  let(:prod1_id){ 'nanomsg' }
  let(:version1){ '0.6.0' }
  let(:owner1_doc){
    {
      avatar: "https://avatars.githubusercontent.com/u/565790?v=3",
      email: "dnfagnan@gmail.com",
      id: 2,
      kind: "user",
      login: "thehydroimpulse",
      name: "Daniel Fagnan",
      url: "https://github.com/thehydroimpulse"
    }
  }

  let(:dep1_doc){
    {
      crate_id: "libc",
      default_features: true,
      downloads: 0,
      features: [],
      id: 89992,
      kind: "normal",
      optional: false,
      req: "^0.2.11",
      target: nil,
      version_id: 28431
    }
  }

  context "fetch_product_list" do
    it "returns expected data for first page" do
      VCR.use_cassette('crates/products_list') do
        products = CratesCrawler.fetch_product_list(api_key, 1)
        expect(products.is_a?(Array)).to be_truthy
        expect(products.count).to eq(100)
      end
    end

    it "returns empty list for non-existing page" do
      VCR.use_cassette('crates/empty_products_list') do
        products = CratesCrawler.fetch_product_list(api_key, 99999)
        expect(products.empty?).to be_truthy
      end
    end
  end

  context "fetch_product_details" do
    it "returns expected product details" do
      VCR.use_cassette('crates/product_details') do
        product_doc = CratesCrawler.fetch_product_details(api_key, prod1_id)
        expect(product_doc.nil?).to be_falsey

        expect(product_doc.has_key?(:crate)).to be_truthy
        expect(product_doc[:crate][:id]).to eq(prod1_id)
        expect(product_doc.has_key?(:versions)).to be_truthy
      end
    end

    it "returns empty response when the product doesnt exists" do
      VCR.use_cassette('crates/empty_product_details') do
        product_doc = CratesCrawler.fetch_product_details(api_key, 'yibberish-blaberish-0001')
        expect(product_doc.nil?).to be_truthy
      end
    end
  end

  context "fetch_version_dependencies" do
    it "returns expected product dependencies" do
      VCR.use_cassette('crates/version_dependencies') do
        deps = CratesCrawler.fetch_version_dependencies(api_key, prod1_id, version1)
        expect(deps.nil?).to be_falsey

        expect(deps.size).to eq(2)
        expect(deps[0][:crate_id]).to eq('libc')
        expect(deps[1][:crate_id]).to eq('nanomsg-sys')
      end
    end
  end

  context "fetch_product_owners" do
    it "returns expected package owners" do
      VCR.use_cassette('crates/product_owners') do
        owners = CratesCrawler.fetch_product_owners(api_key, prod1_id)
        expect(owners.nil?).to be_falsey
        expect(owners.size).to eq(2)
        expect(owners[0][:login]).to eq('thehydroimpulse')
        expect(owners[1][:login]).to eq('blabaere')
      end
    end
  end

  context "upsert_product" do
    it "save product data and returns updated product model" do
      VCR.use_cassette('crates/product_details') do
        res = CratesCrawler.fetch_product_details(api_key, prod1_id)
        expect(res.nil?).to be_falsey
        expect(res.has_key?(:crate) ).to be_truthy

        product_db = CratesCrawler.upsert_product(res[:crate])

        expect(Product.all.count).to eq(1)
        expect(product_db[:language]).to eq(Product::A_LANGUAGE_RUST)
        expect(product_db[:prod_type]).to eq(CratesCrawler::A_TYPE_CARGO)
        expect(product_db[:prod_key]).to eq(prod1_id)
        expect(product_db[:tags].size).to eq(6)
      end
    end
  end

  context "upsert_version" do
    it "adds a new version and returns updated version model" do
      VCR.use_cassette('crates/product_details') do
        res = CratesCrawler.fetch_product_details(api_key, prod1_id)
        expect(res.nil?).to be_falsey
        expect(res.has_key?(:crate)).to be_truthy
        expect(res.has_key?(:versions)).to be_truthy

        product_db = CratesCrawler.upsert_product(res[:crate])
        expect(Product.all.count).to eq(1)

        expect(product_db.versions.size).to eq(0)
        version_db = CratesCrawler.upsert_version(product_db, res[:versions].first)
        product_db.reload
        expect(product_db.versions.size).to eq(1)
        expect(version_db[:version]).to eq('0.6.2')
        expect(version_db[:released_at]).not_to be_nil
      end
    end
  end

  context "upsert_product_owner" do
    it "saves correctly the details of package owner" do
      VCR.use_cassette('crates/product_details') do
        res = CratesCrawler.fetch_product_details(api_key, prod1_id)
        expect(res.nil?).to be_falsey
        expect(res.has_key?(:crate)).to be_truthy
        expect(res.has_key?(:versions)).to be_truthy

        product_db = CratesCrawler.upsert_product(res[:crate])
        expect(Product.all.count).to eq(1)

        owner_db = CratesCrawler.upsert_product_owner(product_db, owner1_doc, '1.0')
        expect(Developer.all.count).to eq(1)
        expect(owner_db[:name]).to eq('daniel_fagnan')
        expect(owner_db[:role]).to eq('owner')
        expect(owner_db[:homepage]).to eq(owner1_doc[:url])
        expect(owner_db[:email]).to eq(owner1_doc[:email])
      end
    end
  end

  context "upsert_version_license" do
    it "saves correctly the details of license" do
      VCR.use_cassette('crates/product_details') do
        res = CratesCrawler.fetch_product_details(api_key, prod1_id)
        expect(res.nil?).to be_falsey
        expect(res.has_key?(:crate)).to be_truthy
        expect(res.has_key?(:versions)).to be_truthy

        product_db = CratesCrawler.upsert_product(res[:crate])
        expect(Product.all.count).to eq(1)

        lic_db = CratesCrawler.upsert_version_license(product_db, version1, 'MIT')
        expect(License.all.count).to eq(1)
        expect(lic_db[:name]).to eq('MIT')
        expect(lic_db[:language]).to eq(product_db[:language])
        expect(lic_db[:prod_key]).to eq(product_db[:prod_key])
        expect(lic_db[:version]).to eq(version1)

      end
    end
  end

  context "upsert_product_dependency" do
    it "saves correctly the product dependency" do
      VCR.use_cassette('crates/product_details') do
        res = CratesCrawler.fetch_product_details(api_key, prod1_id)
        expect(res.nil?).to be_falsey
        expect(res.has_key?(:crate)).to be_truthy

        product_db = CratesCrawler.upsert_product(res[:crate])
        expect(Product.all.count).to eq(1)

        dep_db = CratesCrawler.upsert_product_dependency(product_db, version1, dep1_doc)
        expect(Dependency.all.count).to eq(1)
        expect(dep_db[:prod_type]).to eq(product_db[:prod_type])
        expect(dep_db[:language]).to eq(product_db[:language])
        expect(dep_db[:prod_key]).to eq(product_db[:prod_key])
        expect(dep_db[:prod_version]).to eq(version1)
        expect(dep_db[:scope]).to eq(Dependency::A_SCOPE_COMPILE)
        expect(dep_db[:version]).to eq(dep1_doc[:req])
        expect(dep_db[:name]).to eq(dep1_doc[:crate_id])
      end
    end
  end


  context "product links" do
    it "saves new Product url correclty" do
      VCR.use_cassette('crates/product_details') do
        res = CratesCrawler.fetch_product_details(api_key, prod1_id)
        expect(res.nil?).to be_falsey
        expect(res.has_key?(:crate)).to be_truthy

        product_db = CratesCrawler.upsert_product(res[:crate])
        expect(Product.all.count).to eq(1)

        url_db = CratesCrawler.upsert_version_link(product_db, version1, "test", "url://a")
        expect(Versionlink.all.count).to eq(1)
        expect(url_db[:language]).to eq(product_db[:language])
        expect(url_db[:prod_key]).to eq(product_db[:prod_key])
        expect(url_db[:version_id]).to eq(version1)
        expect(url_db[:name]).to eq('test')
        expect(url_db[:link]).to eq('url://a')
      end
    end

    it "saves correctly urls from the product document" do
      VCR.use_cassette('crates/product_details') do
        res = CratesCrawler.fetch_product_details(api_key, prod1_id)
        expect(res.nil?).to be_falsey
        expect(res.has_key?(:crate)).to be_truthy

        product_db = CratesCrawler.upsert_product(res[:crate])
        expect(Product.all.count).to eq(1)

        link1, _ = CratesCrawler.upsert_version_links(
          product_db, version1, res[:crate]
        )
        expect(Versionlink.all.count).to eq(2)

        expect(link1[:language]).to eq(product_db[:language])
        expect(link1[:prod_key]).to eq(product_db[:prod_key])
        expect(link1[:version_id]).to eq(version1)
        expect(link1[:name]).to eq('Homepage')
        expect(link1[:link]).to eq(res[:crate][:homepage])
      end
    end

    it "saves correctly download url for binaries" do
      VCR.use_cassette('crates/product_details') do
        res = CratesCrawler.fetch_product_details(api_key, prod1_id)
        expect(res.nil?).to be_falsey
        expect(res.has_key?(:crate)).to be_truthy

        product_db = CratesCrawler.upsert_product(res[:crate])
        expect(Product.all.count).to eq(1)

        pkg_name = "#{product_db[:prod_key]}-#{version1}.crate"
        dl_path = "/api/v1/crates/nanomsg/0.6.0/download"
        dl_link = "#{CratesCrawler::API_HOST}/#{dl_path}"
        url_db = CratesCrawler.upsert_version_archive(
          product_db, version1, dl_path
        )

        expect(Versionarchive.all.count).to eq(1)
        expect(url_db[:language]).to eq(product_db[:language])
        expect(url_db[:prod_key]).to eq(product_db[:prod_key])
        expect(url_db[:version_id]).to eq(version1)
        expect(url_db[:name]).to eq(pkg_name)
        expect(url_db[:link]).to eq(dl_link)

      end
    end
  end

  let(:product1){
    Product.new(
      language: Product::A_LANGUAGE_RUST,
      prod_type: CratesCrawler::A_TYPE_CARGO,
      prod_key: 'nanomsg',
      name: 'nanomsg',
      version: '0.6.0'
    )
  }

  let(:product_url){
    %r|https://crates\.io/api/v1/crates/nanomsg\?|
  }
  let(:owners_url){
    %r|https://crates\.io/api/v1/crates/nanomsg/owners|
  }
  let(:deps_url){
    %r|https://crates\.io/api/v1/crates/nanomsg/.+/dependencies|
  }
  let(:product_list_url){
    %r|https://crates\.io/api/v1/crates\?|
  }

  let(:product_list_json){
    '{"crates": [
        {"description": null,
        "documentation": null,
        "downloads": 1032,
        "id": "nanomsg",
        "max_version": "0.6.2",
        "name": "nanomsg",
        "repository": null,
        "updated_at": "2015-12-11T23:56:40Z",
        "versions": null}
    ]}'
  }

  let(:empty_list_json){
    '{"crates":[],"meta":{"total":0}}'
  }

  let(:owners_json){
    '{
      "users": [
        {
          "avatar": "https://avatars.githubusercontent.com/u/565790?v=3",
          "email": "dnfagnan@gmail.com",
          "id": 2,
          "kind": "user",
          "login": "thehydroimpulse",
          "name": "Daniel Fagnan",
          "url": "https://github.com/thehydroimpulse"
        },
        {
          "avatar": "https://avatars0.githubusercontent.com/u/9447137?v=3",
          "email": null,
          "id": 303,
          "kind": "user",
          "login": "blabaere",
          "name": "Benoît Labaere",
          "url": "https://github.com/blabaere"
        }
      ]
    }'
  }

  let(:deps_json){
  '{"dependencies":[
    {"crate_id":"libc","default_features":true,"downloads":0,"features":[],
      "id":89992,"kind":"normal","optional":false,"req":"^0.2.11","target":null,
      "version_id":28431},
    {"crate_id":"nanomsg-sys","default_features":true,"downloads":0,"features":[],
      "id":89993,"kind":"normal","optional":false,"req":"^0.6.0","target":null,
      "version_id":28431}]}'
  }

  let(:product_json){
  '{"crate":{
    "id":"nanomsg",
    "name":"nanomsg",
    "updated_at":"2017-04-19T20:27:27Z",
    "versions":[50723,40905,28431,21273,18445,17384,13574,9014,8236,7190,4944,940,924],
    "keywords":["binding","network","sub","pub","nanomsg"],
    "categories":["network-programming"],
    "badges":[{"badge_type":"appveyor","attributes":{"service":null,"repository":"blabaere/nanomsg.rs","branch":null}},{"badge_type":"travis-ci","attributes":{"branch":null,"repository":"blabaere/nanomsg.rs"}}],
    "created_at":"2014-12-08T02:08:06Z","downloads":5080,"max_version":"0.6.2",
    "description":"A high-level, Rust idiomatic wrapper around nanomsg.",
    "homepage":"https://github.com/thehydroimpulse/nanomsg.rs",
    "documentation":"https://github.com/thehydroimpulse/nanomsg.rs",
    "repository":"https://github.com/thehydroimpulse/nanomsg.rs",
    "links":{"version_downloads":"/api/v1/crates/nanomsg/downloads","versions":null,"owners":"/api/v1/crates/nanomsg/owners","owner_team":"/api/v1/crates/nanomsg/owner_team","owner_user":"/api/v1/crates/nanomsg/owner_user","reverse_dependencies":"/api/v1/crates/nanomsg/reverse_dependencies"},"exact_match":false},"versions":[{"id":50723,"crate":"nanomsg","num":"0.6.2","dl_path":"/api/v1/crates/nanomsg/0.6.2/download","updated_at":"2017-06-25T14:46:48Z","created_at":"2017-04-19T20:27:27Z","downloads":433,"features":{"no_anl":["nanomsg-sys/no_anl"],"bundled":["nanomsg-sys/bundled"]},"yanked":false,"license":"MIT","links":{"dependencies":"/api/v1/crates/nanomsg/0.6.2/dependencies","version_downloads":"/api/v1/crates/nanomsg/0.6.2/downloads","authors":"/api/v1/crates/nanomsg/0.6.2/authors"}},{"id":40905,"crate":"nanomsg","num":"0.6.1","dl_path":"/api/v1/crates/nanomsg/0.6.1/download","updated_at":"2017-06-25T14:46:48Z","created_at":"2016-12-27T08:40:00Z","downloads":530,"features":{"bundled":["nanomsg-sys/bundled"]},"yanked":false,"license":"MIT","links":{"dependencies":"/api/v1/crates/nanomsg/0.6.1/dependencies","version_downloads":"/api/v1/crates/nanomsg/0.6.1/downloads","authors":"/api/v1/crates/nanomsg/0.6.1/authors"}},{"id":28431,"crate":"nanomsg","num":"0.6.0","dl_path":"/api/v1/crates/nanomsg/0.6.0/download","updated_at":"2017-06-25T14:46:48Z","created_at":"2016-06-10T20:03:55Z","downloads":961,"features":{},"yanked":false,"license":"MIT","links":{"dependencies":"/api/v1/crates/nanomsg/0.6.0/dependencies","version_downloads":"/api/v1/crates/nanomsg/0.6.0/downloads","authors":"/api/v1/crates/nanomsg/0.6.0/authors"}},{"id":21273,"crate":"nanomsg","num":"0.5.0","dl_path":"/api/v1/crates/nanomsg/0.5.0/download","updated_at":"2017-06-25T14:46:48Z","created_at":"2016-01-24T22:07:58Z","downloads":1254,"features":{},"yanked":false,"license":"MIT","links":{"dependencies":"/api/v1/crates/nanomsg/0.5.0/dependencies","version_downloads":"/api/v1/crates/nanomsg/0.5.0/downloads","authors":"/api/v1/crates/nanomsg/0.5.0/authors"}},{"id":18445,"crate":"nanomsg","num":"0.4.2","dl_path":"/api/v1/crates/nanomsg/0.4.2/download","updated_at":"2017-06-25T14:46:48Z","created_at":"2015-11-23T12:10:09Z","downloads":357,"features":{},"yanked":false,"license":"MIT","links":{"dependencies":"/api/v1/crates/nanomsg/0.4.2/dependencies","version_downloads":"/api/v1/crates/nanomsg/0.4.2/downloads","authors":"/api/v1/crates/nanomsg/0.4.2/authors"}},{"id":17384,"crate":"nanomsg","num":"0.4.1","dl_path":"/api/v1/crates/nanomsg/0.4.1/download","updated_at":"2017-06-25T14:46:48Z","created_at":"2015-10-29T22:13:45Z","downloads":209,"features":{},"yanked":false,"license":"MIT","links":{"dependencies":"/api/v1/crates/nanomsg/0.4.1/dependencies","version_downloads":"/api/v1/crates/nanomsg/0.4.1/downloads","authors":"/api/v1/crates/nanomsg/0.4.1/authors"}},{"id":13574,"crate":"nanomsg","num":"0.4.0","dl_path":"/api/v1/crates/nanomsg/0.4.0/download","updated_at":"2017-06-25T14:46:48Z","created_at":"2015-07-23T05:54:44Z","downloads":358,"features":{},"yanked":false,"license":"MIT","links":{"dependencies":"/api/v1/crates/nanomsg/0.4.0/dependencies","version_downloads":"/api/v1/crates/nanomsg/0.4.0/downloads","authors":"/api/v1/crates/nanomsg/0.4.0/authors"}},{"id":9014,"crate":"nanomsg","num":"0.3.4","dl_path":"/api/v1/crates/nanomsg/0.3.4/download","updated_at":"2017-06-25T14:46:48Z","created_at":"2015-04-18T20:45:03Z","downloads":283,"features":{},"yanked":false,"license":"MIT","links":{"dependencies":"/api/v1/crates/nanomsg/0.3.4/dependencies","version_downloads":"/api/v1/crates/nanomsg/0.3.4/downloads","authors":"/api/v1/crates/nanomsg/0.3.4/authors"}},{"id":8236,"crate":"nanomsg","num":"0.3.3","dl_path":"/api/v1/crates/nanomsg/0.3.3/download","updated_at":"2017-06-25T14:46:48Z","created_at":"2015-04-06T18:57:47Z","downloads":143,"features":{},"yanked":false,"license":"MIT","links":{"dependencies":"/api/v1/crates/nanomsg/0.3.3/dependencies","version_downloads":"/api/v1/crates/nanomsg/0.3.3/downloads","authors":"/api/v1/crates/nanomsg/0.3.3/authors"}},{"id":7190,"crate":"nanomsg","num":"0.3.2","dl_path":"/api/v1/crates/nanomsg/0.3.2/download","updated_at":"2017-06-25T14:46:48Z","created_at":"2015-03-26T06:51:10Z","downloads":139,"features":{},"yanked":false,"license":"MIT","links":{"dependencies":"/api/v1/crates/nanomsg/0.3.2/dependencies","version_downloads":"/api/v1/crates/nanomsg/0.3.2/downloads","authors":"/api/v1/crates/nanomsg/0.3.2/authors"}},{"id":4944,"crate":"nanomsg","num":"0.3.1","dl_path":"/api/v1/crates/nanomsg/0.3.1/download","updated_at":"2017-06-25T14:46:48Z","created_at":"2015-02-12T20:20:32Z","downloads":136,"features":{},"yanked":false,"license":"MIT","links":{"dependencies":"/api/v1/crates/nanomsg/0.3.1/dependencies","version_downloads":"/api/v1/crates/nanomsg/0.3.1/downloads","authors":"/api/v1/crates/nanomsg/0.3.1/authors"}},{"id":940,"crate":"nanomsg","num":"0.3.0","dl_path":"/api/v1/crates/nanomsg/0.3.0/download","updated_at":"2017-06-25T14:46:48Z","created_at":"2014-12-08T16:21:01Z","downloads":151,"features":{},"yanked":false,"license":"MIT","links":{"dependencies":"/api/v1/crates/nanomsg/0.3.0/dependencies","version_downloads":"/api/v1/crates/nanomsg/0.3.0/downloads","authors":"/api/v1/crates/nanomsg/0.3.0/authors"}},{"id":924,"crate":"nanomsg","num":"0.2.0","dl_path":"/api/v1/crates/nanomsg/0.2.0/download","updated_at":"2017-06-25T14:46:48Z","created_at":"2014-12-08T02:08:06Z","downloads":126,"features":{},"yanked":false,"license":"MIT","links":{"dependencies":"/api/v1/crates/nanomsg/0.2.0/dependencies","version_downloads":"/api/v1/crates/nanomsg/0.2.0/downloads","authors":"/api/v1/crates/nanomsg/0.2.0/authors"}}],"keywords":[{"id":"binding","keyword":"binding","created_at":"2014-11-20T20:07:58Z","crates_cnt":28},{"id":"network","keyword":"network","created_at":"2014-11-23T06:47:40Z","crates_cnt":53},{"id":"sub","keyword":"sub","created_at":"2014-12-08T02:08:06Z","crates_cnt":1},{"id":"pub","keyword":"pub","created_at":"2014-12-08T02:08:06Z","crates_cnt":1},{"id":"nanomsg","keyword":"nanomsg","created_at":"2014-12-08T02:08:06Z","crates_cnt":4}],
  "categories":[{"id":"network-programming","category":"Network programming","slug":"network-programming","description":"Crates dealing with higher-level network protocols such as FTP, HTTP, or SSH, or lower-level network protocols such as TCP or UDP.",
        "created_at":"2017-01-17T19:13:05Z","crates_cnt":90}]}'

  }

  context "crawl_dependencies" do
    before do
      product1.versions << Version.new(version: '0.6.0')
      product1.save

      FakeWeb.allow_net_connect = false
    end

    after do
      FakeWeb.clean_registry
      FakeWeb.allow_net_connect = true
    end

    it "fetches and saves correct version releated data" do
      FakeWeb.register_uri(:get, deps_url, body: deps_json)
      version_db = product1.versions.first
      CratesCrawler.crawl_dependencies(product1, version_db, api_key)

      deps = Dependency.where(
        prod_type: CratesCrawler::A_TYPE_CARGO,
        prod_key: product1[:prod_key]
      ).to_a

      expect(deps.size).to eq(2)
      expect(deps[0][:language]).to eq(Product::A_LANGUAGE_RUST)
      expect(deps[0][:name]).to eq('libc')
      expect(deps[0][:version]).to eq('^0.2.11')
      expect(deps[0][:scope]).to eq(Dependency::A_SCOPE_COMPILE)

      expect(deps[1][:language]).to eq(Product::A_LANGUAGE_RUST)
      expect(deps[1][:name]).to eq('nanomsg-sys')
      expect(deps[1][:version]).to eq('^0.6.0')
      expect(deps[1][:scope]).to eq(Dependency::A_SCOPE_COMPILE)

    end

    it "returns nil if version_db models has no version label" do
      version_db = product1.versions.first
      version_db[:version] = nil
      expect(
        CratesCrawler.crawl_dependencies(product1, version_db, api_key)
      ).to be_nil
    end
  end

  context "process_versions" do
    before do
      Product.delete_all
      FakeWeb.allow_net_connect = false
    end

    after do
      FakeWeb.clean_registry
      FakeWeb.allow_net_connect = true
    end

    it "fetches and saves corretly all details of the product" do
      FakeWeb.register_uri :get, product_url, body: product_json
      FakeWeb.register_uri :get, deps_url, body: deps_json
      FakeWeb.register_uri :get, owners_url, body: owners_json

      product_doc = JSON.parse(product_json, symbolize_names: true)
      prod_db = CratesCrawler.process_versions(
        product1, product_doc, api_key, false
      )

      expect(prod_db).not_to be_nil
      expect(prod_db[:prod_key]).to eq(product1[:prod_key])
      expect(prod_db[:version]).to eq('0.6.0')

      expect(License.all.count).to eq(13)
      lic = License.where(
        language: product1[:language],
        prod_key: product1[:prod_key]
      ).first
      expect(lic).not_to be_nil
      expect(lic[:name]).to eq('MIT')

      expect(Dependency.all.count).to eq(26) #13 versions * 2 deps each
      dep = Dependency.where(dep_prod_key: 'libc').first
      expect(dep).not_to be_nil
      expect(dep[:prod_key]).to eq(product1[:prod_key])
      expect(dep[:language]).to eq(product1[:language])
      expect(dep[:prod_version]).to eq('0.6.2')
      expect(dep[:version]).to eq('^0.2.11')
    end

    it "ignores crawling when existing latest version of product is same" do

      product_doc = JSON.parse(product_json, symbolize_names: true)
      res = CratesCrawler.process_versions(
        product1, product_doc, api_key, true
      )
      expect(res).not_to be_nil #it will return same product model
    end
  end

  context "crawl_product_list" do
    before do
      FakeWeb.clean_registry
      FakeWeb.allow_net_connect = false
    end

    after do
      FakeWeb.allow_net_connect = true
    end

    it "crawl products on the first page and stops as second page is empty" do
      FakeWeb.register_uri :get, product_url, body: product_json
      FakeWeb.register_uri :get, deps_url, body: deps_json
      FakeWeb.register_uri :get, owners_url, body: owners_json


      FakeWeb.register_uri(
        :get, product_list_url,
        [
          {body: product_list_json, status: [200, "OK"]},
          {body: empty_list_json, status: [404, "Not found"]}
        ]
      )
      n = CratesCrawler.crawl_product_list(api_key)
      expect(n).to eq(1)

      prod_db = Product.where(
        prod_type: CratesCrawler::A_TYPE_CARGO,
        prod_key: product1[:prod_key]
      ).first
      expect(prod_db).not_to be_nil
      expect(prod_db[:prod_key]).to eq(product1[:prod_key])
      expect(prod_db[:version]).to eq('0.6.2')

      expect(License.all.count).to eq(13)
      lic = License.where(
        language: product1[:language],
        prod_key: product1[:prod_key]
      ).first
      expect(lic).not_to be_nil
      expect(lic[:name]).to eq('MIT')

      expect(Dependency.all.count).to eq(26) #13 versions * 2 deps each
      dep = Dependency.where(dep_prod_key: 'libc').first
      expect(dep).not_to be_nil
      expect(dep[:prod_key]).to eq(product1[:prod_key])
      expect(dep[:language]).to eq(product1[:language])
      expect(dep[:prod_version]).to eq('0.6.2')
      expect(dep[:version]).to eq('^0.2.11')

    end
  end
end
